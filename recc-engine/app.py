import json
import os
from typing import Optional, List

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from dotenv import load_dotenv

from tmdb_api import TMDBClient
import user

load_dotenv()
tmdb_client = TMDBClient(os.getenv("TMDB_BEARER"))

app = FastAPI(title="Recc Engine API")

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

@app.post("/encode")
def encode_user(user_data: UserCreate):
    """
    Creates or updates a user profile based on the provided data.
    Fetches keywords for movie_ids, saves the profile to disk, and encodes/upserts to DB.
    """
    try:
        # Construct initial profile with new history structure
        profile = {
            "name": user_data.name,
            "genres": user_data.genres,
            "history": {
                "liked": user_data.movie_ids,
                "disliked": [],
                "watchlist": [],
                "seen": user_data.movie_ids[:] # Copy liked to seen
            },
            "keywords": []
        }
        
        # Fetch keywords from movie_ids
        if user_data.movie_ids:
            current_keywords = set()
            for mid in user_data.movie_ids:
                try:
                    # Fetch keywords from TMDB
                    kw_resp = tmdb_client.keywords(mid)
                    keywords_data = kw_resp.get("keywords", [])
                    # Extract keyword names
                    new_kws = [k["name"] for k in keywords_data if "name" in k]
                    
                    if new_kws:
                        current_keywords.update(new_kws)
                except Exception as e:
                    print(f"Error fetching keywords for movie {mid}: {e}")
            
            profile["keywords"] = list(current_keywords)

        # Save to disk using user.py's helper to ensure consistency
        # We can't use user.save_user_profile directly because we need to handle the path logic here 
        # or update the helper. But let's just use the logic we know.
        file_path = f"users/{user_data.name}.json"
        
        # Use the helper from user.py if possible, or replicate safe save
        # Importing save_user_profile would be better if I exposed it.
        # I did expose it in the previous step.
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

@app.get("/users/{user_id}/recommendations", response_model=List[Recommendation])
def get_recommendations(
    user_id: str, 
    top_k: int = 30, 
    genres: Optional[str] = Query(None, description="Comma-separated list of genres to filter by")
):
    """
    Get movie recommendations for a user based on their stored embedding.
    If the embedding is not in the DB, it tries to load and encode the profile from disk.
    """
    try:
        embedding = None
        filter_genres = []

        # 1. Try to get embedding from DB
        try:
            db_result = user.get_profile_from_db(user_id)
            embedding = [db_result["embeddings"][0]]
            
            # Extract genres from DB metadata if not provided in query
            if not genres and db_result["metadatas"] and db_result["metadatas"][0]:
                payload_json = db_result["metadatas"][0].get("payload")
                if payload_json:
                    profile = json.loads(payload_json)
                    filter_genres = profile.get("genres", [])
        except ValueError:
            # 2. If not in DB, try to load from file and encode
            file_path = f"users/{user_id}.json"
            if not os.path.exists(file_path):
                raise HTTPException(
                    status_code=404, 
                    detail=f"User embedding not found in DB and profile file {file_path} does not exist."
                )
            
            profile = user.load_user_profile(file_path)
            query_text = user.build_user_text(profile)
            embedding = user.encode_user_text(query_text)
            
            # Upsert so it's there next time
            user.upsert_user_profile(user_id, query_text, embedding, profile)
            
            if not genres:
                filter_genres = profile.get("genres", [])

        # Override genres if provided in query
        if genres:
            filter_genres = [g.strip() for g in genres.split(",")]

        if not embedding:
            raise HTTPException(status_code=500, detail="Failed to obtain user embedding.")

        results = user.search_movies(embedding, top_k, filters=filter_genres)
        
        recommendations = []
        if results and results["ids"]:
            ids = results["ids"][0]
            metadatas = results["metadatas"][0]
            distances = results["distances"][0]
            
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
