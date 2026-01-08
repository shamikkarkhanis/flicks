import argparse
import json
import os

import chromadb
from sentence_transformers import SentenceTransformer


def build_user_text(profile):
    genres = profile.get("genres", [])
    keywords = profile.get("keywords", [])
    parts = []
    if genres:
        parts.append("Genres: " + ", ".join(genres))
    if keywords:
        parts.append("Keywords: " + ", ".join(keywords))
    return " | ".join(parts)


def load_user_profile(path):
    with open(path, "r") as f:
        data = json.load(f)
    
    if isinstance(data, list):
        if not data:
            raise ValueError(f"{path} is empty.")
        profile = data[0]
    elif isinstance(data, dict):
        profile = data
    else:
        raise ValueError(f"{path} must be a JSON object or a list of objects.")
    
    # Ensure data structure exists
    if "data" not in profile:
        profile["data"] = {
            "liked": [],
            "disliked": [],
            "neutral": [],
            "watchlist": [],
            "history": [],
            "shown": []
        }
    else:
        # Ensure all keys exist
        required_keys = ["liked", "disliked", "neutral", "watchlist", "history", "shown"]
        for key in required_keys:
            if key not in profile["data"]:
                profile["data"][key] = []
                
    return profile

def save_user_profile(path, profile):
    # Check if original file was a list (simple heuristic or we could store this state)
    # For now, we follow the convention of the existing files which seem to be lists.
    # We can check the file content if we want to be 100% sure, but let's assume list for now 
    # if that's the project standard, or check if the path exists and read it.
    
    # We will read the file first to preserve the structure (list vs dict)
    is_list = True
    if os.path.exists(path):
        with open(path, "r") as f:
            try:
                data = json.load(f)
                if isinstance(data, dict):
                    is_list = False
            except:
                pass 
    
    output_data = [profile] if is_list else profile
    
    with open(path, "w") as f:
        json.dump(output_data, f, indent=4)

def update_user_data(user_path, movie_id, action):
    profile = load_user_profile(user_path)
    data = profile["data"]
    
    try:
        movie_id = int(movie_id)
    except ValueError:
        pass 

    if action == "liked":
        if movie_id not in data["liked"]:
            data["liked"].append(movie_id)
        # Liked implies history (watched/interacted) and shown
        if movie_id not in data["history"]:
            data["history"].append(movie_id)
        if movie_id not in data["shown"]:
            data["shown"].append(movie_id)
        
        # Remove from conflicting states
        if movie_id in data["disliked"]:
            data["disliked"].remove(movie_id)
        if movie_id in data["neutral"]:
            data["neutral"].remove(movie_id)
            
    elif action == "disliked":
        if movie_id not in data["disliked"]:
            data["disliked"].append(movie_id)
        # Disliked implies history and shown
        if movie_id not in data["history"]:
            data["history"].append(movie_id)
        if movie_id not in data["shown"]:
            data["shown"].append(movie_id)
            
        # Remove from conflicting states
        if movie_id in data["liked"]:
            data["liked"].remove(movie_id)
        if movie_id in data["neutral"]:
            data["neutral"].remove(movie_id)

    elif action == "neutral":
        if movie_id not in data["neutral"]:
            data["neutral"].append(movie_id)
        # Neutral implies history (user rated it neutral) and shown
        if movie_id not in data["history"]:
            data["history"].append(movie_id)
        if movie_id not in data["shown"]:
            data["shown"].append(movie_id)
            
        # Remove from conflicting states
        if movie_id in data["liked"]:
            data["liked"].remove(movie_id)
        if movie_id in data["disliked"]:
            data["disliked"].remove(movie_id)
            
    elif action == "watchlist":
        if movie_id not in data["watchlist"]:
            data["watchlist"].append(movie_id)
            
    elif action == "history":
        if movie_id not in data["history"]:
            data["history"].append(movie_id)
        if movie_id not in data["shown"]:
            data["shown"].append(movie_id)
            
    elif action == "shown":
        if movie_id not in data["shown"]:
            data["shown"].append(movie_id)
            
    elif action == "remove_watchlist":
         if movie_id in data["watchlist"]:
            data["watchlist"].remove(movie_id)
            
    save_user_profile(user_path, profile)
    return profile


def get_profile_from_db(user_id):
    client = chromadb.PersistentClient(path="chroma")
    collection = client.get_or_create_collection(name="users")
    results = collection.get(
        ids=[user_id],
        include=["metadatas", "documents", "embeddings"],
    )
    if len(results.get("embeddings", [])) == 0 or results["embeddings"][0] is None:
        raise ValueError(f"User embedding not found for id={user_id}")
    return results


def encode_user_text(text):
    model = SentenceTransformer("all-MiniLM-L6-v2")
    return model.encode([text]).tolist()


def upsert_user_profile(user_id, text, embedding, profile):
    client = chromadb.PersistentClient(path="chroma")
    collection = client.get_or_create_collection(name="users")
    collection.upsert(
        ids=[user_id],
        embeddings=embedding,
        metadatas=[{"payload": json.dumps(profile, ensure_ascii=True)}],
        documents=[text],
    )


def search_movies(embedding, top_k, filters=None, exclude_ids=None):
    client = chromadb.PersistentClient(path="chroma")
    collection = client.get_or_create_collection(name="movies")
    
    where_filter = None
    if filters:
        # ... (keep existing filter logic)
        conditions = [{f"is_{genre}": True} for genre in filters]
        if len(conditions) == 1:
            where_filter = conditions[0]
        else:
            where_filter = {"$or": conditions}

    # Fetch a large enough pool to guarantee top_k after exclusion
    # 150 is a safe bet for a medium sized database
    fetch_k = max(150, top_k * 2)
    
    results = collection.query(
        query_embeddings=embedding,
        n_results=fetch_k,
        include=["metadatas", "distances", "documents"],
        where=where_filter
    )

    if not exclude_ids:
        # Still truncate to top_k for consistency
        return {
            "ids": [results["ids"][0][:top_k]],
            "distances": [results["distances"][0][:top_k]],
            "metadatas": [results["metadatas"][0][:top_k]],
            "documents": [results["documents"][0][:top_k]]
        }

    # Python-side filtering for ID exclusion
    exclude_set = {str(eid) for eid in exclude_ids}
    
    new_results = {
        "ids": [[]],
        "distances": [[]],
        "metadatas": [[]],
        "documents": [[]]
    }
    
    for i in range(len(results["ids"][0])):
        mid = results["ids"][0][i]
        if mid not in exclude_set:
            new_results["ids"][0].append(mid)
            new_results["distances"][0].append(results["distances"][0][i])
            new_results["metadatas"][0].append(results["metadatas"][0][i])
            new_results["documents"][0].append(results["documents"][0][i])
        
        if len(new_results["ids"][0]) >= top_k:
            break
            
    return new_results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-profile", default="users/user_1.json")
    parser.add_argument("--encode", action="store_true")
    parser.add_argument("--top-k", type=int, default=10)
    parser.add_argument("--genres", help="Comma-separated list of genres to filter by")
    args = parser.parse_args()


    if args.encode:
        profile = load_user_profile(args.user_profile)
        query_text = build_user_text(profile)
        embedding = encode_user_text(query_text)
        user_id = profile.get("id") or os.path.splitext(os.path.basename(args.user_profile))[0]
        upsert_user_profile(user_id, query_text, embedding, profile)
    else:
        user_id = os.path.splitext(os.path.basename(args.user_profile))[0]
        embedding = [get_profile_from_db(user_id)["embeddings"][0]]

    filters = []
    if args.genres:
        filters = [g.strip() for g in args.genres.split(",")]
    else:
        filters = load_user_profile(args.user_profile).get("genres", [])

    # pull user embedding from chroma

    results = search_movies(embedding, args.top_k, filters=filters)
    for idx, movie_id in enumerate(results["ids"][0]):
        metadata = results["metadatas"][0][idx]
        payload = json.loads(metadata.get("payload", "{}"))
        title = payload.get("title", "Unknown")
        backdrop = payload.get("backdrop_path", "No Backdrop")
        score = results["distances"][0][idx]
        print(f"{idx + 1}. {title} (id={movie_id}, distance={score:.4f}, backdrop={backdrop})")


if __name__ == "__main__":
    main()
