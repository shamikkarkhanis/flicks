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
    # 1. Keep your original logic
    ids.append(str(item.get("id")))
    documents.append(build_text(item))
    
    # 2. Minimal Metadata Change: Add Boolean Flags
    metadata = {"payload": json.dumps(item)}
    for g in item.get("genres", []):
        name = g.get("name")
        if name:
            # This creates fields like "is_Action": True, "is_Drama": True
            metadata[f"is_{name}"] = True 
            
    metadatas.append(metadata)

embeddings = model.encode(documents, show_progress_bar=True).tolist()
print(f"Generated {len(embeddings)} embeddings.")

collection.upsert(
    ids=ids,
    embeddings=embeddings,
    metadatas=metadatas,
    documents=documents,
)
