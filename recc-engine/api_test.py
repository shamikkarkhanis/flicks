import json
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

from dotenv import load_dotenv

from data.tmdb_api import TMDBClient

MOVIE_GENRES = {
    28: "Action",
    12: "Adventure",
    16: "Animation",
    35: "Comedy",
    80: "Crime",
    99: "Documentary",
    18: "Drama",
    10751: "Family",
    14: "Fantasy",
    36: "History",
    27: "Horror",
    10402: "Music",
    9648: "Mystery",
    10749: "Romance",
    878: "Science Fiction",
    10770: "TV Movie",
    53: "Thriller",
    10752: "War",
    37: "Western",
}

load_dotenv()

client = TMDBClient(os.getenv("TMDB_BEARER"))

# print(client.movie_details(550))

movies = []
pending = []
for page in range(2, 201):
    popular = client.popular_movies(page=page)
    pending.extend(popular.get("results", []))

total = len(pending)
completed = 0


def enrich_movie(movie):
    movie_id = movie.get("id")
    if movie_id is None:
        return movie
    details = client.movie_details(movie_id)
    keywords = client.keywords(movie_id)
    details["keywords"] = keywords.get("keywords", [])
    return details


with ThreadPoolExecutor(max_workers=8) as executor:
    futures = {executor.submit(enrich_movie, movie): movie for movie in pending}
    for future in as_completed(futures):
        try:
            result = future.result()
            if None not in result.values():
                movies.append(result)
        except Exception as exc:
            movie = futures[future]
            print(f"Error fetching keywords for {movie.get('id')}: {exc}")
        completed += 1
        print(f"Completed {completed}/{total}")

with open("tmdb_dataset.json", "w") as f:
    json.dump(movies, f, indent=2, ensure_ascii=True)
