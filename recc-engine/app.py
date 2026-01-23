import json
import os
import time
import logging
import glob
from typing import Optional, List

from fastapi import FastAPI, HTTPException, Query, Path, Request
from pydantic import BaseModel
from dotenv import load_dotenv

from tmdb_api import TMDBClient
import user

# Configure logging with rotating run files
os.makedirs("logs", exist_ok=True)
existing_logs = glob.glob("logs/server_*.log")
indices = [int(f.split("_")[-1].split(".")[0]) for f in existing_logs if "_" in f]
next_index = max(indices) + 1 if indices else 1
log_filename = f"logs/server_{next_index}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(log_filename),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("recc-engine")
logger.info("Starting server run #%d. Logging to %s", next_index, log_filename)

load_dotenv()
tmdb_client = TMDBClient(os.getenv("TMDB_BEARER"))

app = FastAPI(title="Recc Engine API")

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    logger.info("path %s | method %s | duration %.4fs | status %d", 
                request.url.path, request.method, duration, response.status_code)
    return response

class Recommendation(BaseModel):
    movie_id: str
    title: str
    score: float
    genres: List[str]
    backdrop_path: Optional[str] = None

@app.get("/")
def read_root():
    return {"message": "Welcome to the Recc Engine API"}

class UserCreate(BaseModel):
    name: str
    genres: List[str]
    movie_ids: List[int]

def update_keyword_counts(profile_keywords, new_keywords):
    """
    Updates the keyword counts in the profile.
    Handles migration if profile_keywords is a list (legacy).
    """
    # Migration: Convert list to dict if necessary
    if isinstance(profile_keywords, list):
        # Assume count 1 for existing keywords in legacy list
        counts = {k: 1 for k in profile_keywords}
    else:
        counts = profile_keywords

    for kw in new_keywords:
        counts[kw] = counts.get(kw, 0) + 1
    
    return counts

@app.post("/encode")
def encode_user(user_data: UserCreate):
    """
    Creates or updates a user profile based on the provided data.
    Fetches keywords for movie_ids, saves the profile to disk, and encodes/upserts to DB.
    """
    try:
        # Construct initial profile with new data structure
        # movie_ids generally implies 'liked' in this initial creation context
        profile = {
            "name": user_data.name,
            "genres": user_data.genres,
            "data": {
                "liked": user_data.movie_ids,
                "disliked": [],
                "neutral": [],
                "watchlist": [],
                "history": user_data.movie_ids[:], # Implies watched
                "shown": user_data.movie_ids[:]    # Implies seen
            },
            "keywords": {} # Changed to dict for frequency tracking
        }
        
        # Fetch keywords from movie_ids
        if user_data.movie_ids:
            # We will accumulate all keywords then update counts
            all_new_kws = []
            for mid in user_data.movie_ids:
                try:
                    # Fetch keywords from TMDB
                    kw_resp = tmdb_client.keywords(mid)
                    keywords_data = kw_resp.get("keywords", [])
                    # Extract keyword names
                    new_kws = [k["name"] for k in keywords_data if "name" in k]
                    all_new_kws.extend(new_kws)
                except Exception as e:
                    print(f"Error fetching keywords for movie {mid}: {e}")
            
            profile["keywords"] = update_keyword_counts({}, all_new_kws)

        # Save to disk using user.py's helper to ensure consistency
        file_path = f"users/{user_data.name}.json"
        
        user.save_user_profile(file_path, profile)

        # Encode and Upsert
        query_text = user.build_user_text(profile)
        embedding = user.encode_user_text(query_text)
        
        user.upsert_user_profile(user_data.name, query_text, embedding, profile)
        
        return {
            "message": f"User {user_data.name} created/updated and encoded successfully.",
            "profile_preview": profile
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/onboarding", response_model=List[Recommendation])
def get_onboarding_movies():
    """
    Returns a static list of popular movies for onboarding from Chroma DB.
    """
    onboarding_ids = [
        238, 324857, 85, 115, 496243,
        694, 11036, 27205, 76341, 407806
    ]
    
    try:
        movies_data = user.get_movies_by_ids(onboarding_ids)
        
        recommendations = []
        
        # Create a map for quick lookup to maintain order
        movie_map = {m["id"]: m for m in movies_data}
        
        for mid in onboarding_ids:
            mid_str = str(mid)
            if mid_str in movie_map:
                m_data = movie_map[mid_str]
                meta = m_data["metadata"]
                payload = json.loads(meta.get("payload", "{}"))
                
                # Extract genre names
                raw_genres = payload.get("genres", [])
                processed_genres = []
                for g in raw_genres:
                    if isinstance(g, dict) and "name" in g:
                        processed_genres.append(g["name"])
                    elif isinstance(g, str):
                        processed_genres.append(g)

                rec = Recommendation(
                    movie_id=mid_str,
                    title=payload.get("title", "Unknown"),
                    score=1.0, # Static score for onboarding
                    genres=processed_genres,
                    backdrop_path=payload.get("backdrop_path")
                )
                recommendations.append(rec)
                
        return recommendations

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users/{user_id}")
def get_user_profile(user_id: str):
    """
    Returns the full user profile (watchlist, history, ratings, etc.)
    """
    file_path = f"users/{user_id}.json"
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="User profile not found")
    
    try:
        profile = user.load_user_profile(file_path)
        return profile
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class WatchlistRequest(BaseModel):
    movie_id: int

@app.post("/users/{user_id}/watchlist")
def add_to_watchlist(user_id: str, request: WatchlistRequest):
    """
    Adds a movie to the user's watchlist.
    """
    try:
        file_path = f"users/{user_id}.json"
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="User profile not found")

        updated_profile = user.update_user_data(file_path, request.movie_id, "watchlist")
        return {"message": "Added to watchlist", "data": updated_profile["data"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/users/{user_id}/watchlist/{movie_id}")
def remove_from_watchlist(user_id: str, movie_id: int):
    """
    Removes a movie from the user's watchlist.
    """
    try:
        file_path = f"users/{user_id}.json"
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="User profile not found")

        updated_profile = user.update_user_data(file_path, movie_id, "remove_watchlist")
        return {"message": "Removed from watchlist", "data": updated_profile["data"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class RatingRequest(BaseModel):
    movie_id: int
    rating: str  # "like", "dislike", "neutral"

@app.post("/users/{user_id}/ratings")
def rate_movie(user_id: str, request: RatingRequest):
    """
    Updates the user's rating for a movie (like/dislike/neutral).
    If 'like', it fetches keywords, updates the profile, and re-encodes the user
    to provide live recommendation updates.
    """
    if request.rating not in ["like", "dislike", "neutral"]:
         raise HTTPException(status_code=400, detail="Invalid rating. Must be 'like', 'dislike', or 'neutral'.")

    try:
        file_path = f"users/{user_id}.json"
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="User profile not found")

        # 1. Update the local JSON data (history, liked/disliked lists)
        action_map = {
            "like": "liked",
            "dislike": "disliked",
            "neutral": "neutral"
        }
        updated_profile = user.update_user_data(file_path, request.movie_id, action_map[request.rating])
        
        # 2. If liked, we need to update keywords and re-embed for live recs
        if request.rating == "like":
            try:
                # Fetch new keywords
                kw_resp = tmdb_client.keywords(request.movie_id)
                keywords_data = kw_resp.get("keywords", [])
                new_kws = [k["name"] for k in keywords_data if "name" in k]
                
                # Merge with existing keywords using helper to update counts
                current_keywords_data = updated_profile.get("keywords", {})
                updated_keywords_dict = update_keyword_counts(current_keywords_data, new_kws)
                updated_profile["keywords"] = updated_keywords_dict
                
                # Save the keyword update to disk
                user.save_user_profile(file_path, updated_profile)
                
                # Re-encode and Upsert
                query_text = user.build_user_text(updated_profile)
                embedding = user.encode_user_text(query_text)
                user.upsert_user_profile(user_id, query_text, embedding, updated_profile)
            except Exception as tmdb_error:
                print(f"Warning: Failed to fetch keywords or re-embed for movie {request.movie_id}: {tmdb_error}")
                # We don't fail the request, just the optimization
        
        return {
            "message": f"Movie rated {request.rating}", 
            "data": updated_profile["data"]
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class SyncRequest(BaseModel):
    shown_ids: List[int]

@app.post("/users/{user_id}/sync")
def sync_user_data(user_id: str, request: SyncRequest):
    """
    Syncs the list of movies already shown to the user on the frontend.
    """
    try:
        print(f"[Backend] Syncing shown movies for user: {user_id}")
        file_path = f"users/{user_id}.json"
        if not os.path.exists(file_path):
            print(f"[Backend] Profile not found for sync: {file_path}")
            raise HTTPException(status_code=404, detail="User profile not found")

        profile = user.load_user_profile(file_path)
        
        # Update 'shown' list
        current_shown = set(profile["data"].get("shown", []))
        incoming_ids = set(request.shown_ids)
        current_shown.update(incoming_ids)
        profile["data"]["shown"] = list(current_shown)
        
        user.save_user_profile(file_path, profile)
        print(f"[Backend] Sync successful. Total shown now: {len(profile['data']['shown'])}")
        return {"message": "Sync successful", "shown_count": len(profile["data"]["shown"])}
    except Exception as e:
        print(f"[Backend] Sync error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users/{user_id}/recommendations", response_model=List[Recommendation])
def get_recommendations(
    user_id: str, 
    top_k: int = 20, 
    genres: Optional[str] = Query(None, description="Comma-separated list of genres to filter by"),
    language: Optional[str] = Query(None, description="Language code to filter by (e.g. 'en', 'es')")
):
    """
    Get movie recommendations for a user based on their stored embedding.
    Excludes movies the user has already seen or interacted with.
    """
    try:
        print(f"[Backend] Fetching recommendations for: {user_id}")
        embedding = None
        filter_genres = []
        exclude_ids = []

        # 1. Try to load user profile to get exclusion list and genres
        file_path = f"users/{user_id}.json"
        profile = None
        user_keywords_list = []
        if os.path.exists(file_path):
            profile = user.load_user_profile(file_path)
            # Exclude shown, liked, disliked, and watchlist
            data = profile.get("data", {})
            exclude_ids = list(set(
                data.get("shown", []) + 
                data.get("liked", []) + 
                data.get("disliked", []) + 
                data.get("watchlist", []) +
                data.get("history", [])
            ))
            print(f"[Backend] Loaded profile. Exclusion list size: {len(exclude_ids)}")
            if not genres:
                filter_genres = profile.get("genres", [])
            
            # Process Keywords: Filter Top 100
            raw_keywords = profile.get("keywords", {})
            if isinstance(raw_keywords, list):
                # Legacy: It's a list, use all of them (or truncate if we wanted, but logic implies frequency)
                # Since we don't have frequency, we just take them all (or top 100 arbitrary)
                user_keywords_list = raw_keywords[:100]
            elif isinstance(raw_keywords, dict):
                # Sort by count (descending)
                sorted_kws = sorted(raw_keywords.items(), key=lambda item: item[1], reverse=True)
                # Take top 100 keys
                user_keywords_list = [k for k, v in sorted_kws[:100]]
            
        else:
            print(f"[Backend] Profile file NOT FOUND: {file_path}")

        # 2. Try to get embedding from DB
        try:
            db_result = user.get_profile_from_db(user_id)
            embedding = [db_result["embeddings"][0]]
        except ValueError:
            # If not in DB, encode from profile
            if profile:
                print(f"[Backend] Embedding not in DB. Encoding from profile...")
                query_text = user.build_user_text(profile)
                embedding = user.encode_user_text(query_text)
                user.upsert_user_profile(user_id, query_text, embedding, profile)
            else:
                raise HTTPException(status_code=404, detail="User not found")

        # Override genres if provided in query
        if genres:
            filter_genres = [g.strip() for g in genres.split(",")]

        if not embedding:
            raise HTTPException(status_code=500, detail="Failed to obtain user embedding.")

        # 3. Search with exclusion and language filter
        results = user.search_movies(
            embedding, 
            top_k, 
            filters=filter_genres, 
            exclude_ids=exclude_ids,
            language=language,
            user_keywords=user_keywords_list
        )
        
        recommendations = []
        if results and results["ids"]:
            ids = results["ids"][0]
            metadatas = results["metadatas"][0]
            distances = results["distances"][0]
            
            print(f"[Backend] Engine returned {len(ids)} candidates after exclusion.")
            
            for idx, movie_id in enumerate(ids):
                meta = metadatas[idx]
                payload = json.loads(meta.get("payload", "{}"))
                
                # Extract genre names if they are objects
                raw_genres = payload.get("genres", [])
                processed_genres = []
                for g in raw_genres:
                    if isinstance(g, dict) and "name" in g:
                        processed_genres.append(g["name"])
                    elif isinstance(g, str):
                        processed_genres.append(g)

                rec = Recommendation(
                    movie_id=str(movie_id),
                    title=payload.get("title", "Unknown"),
                    score=distances[idx],
                    genres=processed_genres,
                    backdrop_path=payload.get("backdrop_path")
                )
                recommendations.append(rec)
                
        return recommendations

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
