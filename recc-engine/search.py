import json

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


with open("user_1.json", "r") as f:
    user_profiles = json.load(f)

if not user_profiles:
    raise ValueError("user_1.json is empty.")

query_text = build_user_text(user_profiles[0])

model = SentenceTransformer("all-MiniLM-L6-v2")
query_embedding = model.encode([query_text]).tolist()

client = chromadb.PersistentClient(path="chroma")
collection = client.get_or_create_collection(name="movies")

results = collection.query(
    query_embeddings=query_embedding,
    n_results=10,
    include=["metadatas", "distances", "documents"],
)

for idx, movie_id in enumerate(results["ids"][0]):
    metadata = results["metadatas"][0][idx]
    payload = json.loads(metadata.get("payload", "{}"))
    title = payload.get("title", "Unknown")
    score = results["distances"][0][idx]
    print(f"{idx + 1}. {title} (id={movie_id}, distance={score:.4f})")
