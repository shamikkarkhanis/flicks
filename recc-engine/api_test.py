import json

from dotenv import load_dotenv
import os

from tmdb_api import TMDBClient

load_dotenv()

client = TMDBClient(os.getenv("TMDB_BEARER"))

with open("tmdb_dataset.json", "w") as f:
    for page in range(10, 101):
        popular = client.popular_movies(page=page)
        for movie in popular.get("results", []):
            f.write(json.dumps(movie) + "\n")

