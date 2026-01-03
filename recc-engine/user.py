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
        return data[0]
    if not isinstance(data, dict):
        raise ValueError(f"{path} must be a JSON object or a list of objects.")
    return data

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


def search_movies(embedding, top_k, filters=None):
    client = chromadb.PersistentClient(path="chroma")
    collection = client.get_or_create_collection(name="movies")
    
    where_filter = None
    if filters:
        conditions = [{f"is_{genre}": True} for genre in filters]
        if len(conditions) == 1:
            where_filter = conditions[0]
        else:
            where_filter = {"$or": conditions}

    return collection.query(
        query_embeddings=embedding,
        n_results=top_k,
        include=["metadatas", "distances", "documents"],
        where=where_filter
    )


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
