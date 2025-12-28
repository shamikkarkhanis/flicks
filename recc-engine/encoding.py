import json

import chromadb
from sentence_transformers import SentenceTransformer


def build_text(item):
    genre_names = [g.get("name") for g in item.get("genres", []) if g.get("name")]
    keyword_names = [
        k.get("name") for k in item.get("keywords", []) if k.get("name")
    ]
    overview = item.get("overview") or ""
    parts = []
    if genre_names:
        parts.append("Genres: " + ", ".join(genre_names))
    if keyword_names:
        parts.append("Keywords: " + ", ".join(keyword_names))
    if overview:
        parts.append("Overview: " + overview)
    return " | ".join(parts)


with open("data/tmdb_dataset.json", "r") as f:
    data = json.load(f)

client = chromadb.PersistentClient(path="chroma")
collection = client.get_or_create_collection(name="movies")

model = SentenceTransformer("all-MiniLM-L6-v2")

ids = []
documents = []
metadatas = []
for item in data:
    movie_id = item.get("id")
    if movie_id is None:
        continue
    genre_names = [g.get("name") for g in item.get("genres", []) if g.get("name")]
    genre_names_str = "|" + "|".join(genre_names) + "|" if genre_names else ""
    ids.append(str(movie_id))
    documents.append(build_text(item))
    metadatas.append(
        {
            "payload": json.dumps(item, ensure_ascii=True),
            "genre_names_str": genre_names_str,
        }
    )

embeddings = model.encode(documents, show_progress_bar=True).tolist()
print(f"Generated {len(embeddings)} embeddings.")

collection.upsert(
    ids=ids,
    embeddings=embeddings,
    metadatas=metadatas,
    documents=documents,
)
