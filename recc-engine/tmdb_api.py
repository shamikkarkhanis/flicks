"""Thin wrapper around TMDB API using curl requests."""

from __future__ import annotations


from typing import Any, Dict, List, Optional

import requests


class TMDBClient:
    """Small convenience wrapper to keep TMDB calls in one place."""

    def __init__(self, api_key: Optional[str] = None) -> None:
        self._api_key = api_key
        self._base_url = "https://api.themoviedb.org/3/"
        self.header = {'Authorization': f'Bearer {self._api_key}'}

    def _get(self, endpoint: str) -> Dict[str, Any]:
        response = requests.get(url=self._base_url + endpoint, headers=self.header)
        response.raise_for_status()
        return response.json()

    def movie_details(self, movie_id: int) -> Dict[str, Any]:
        return self._get(f"/movie/{movie_id}")

    # def movie_credits(self, movie_id: int) -> Dict[str, Any]:
    #     return self._get(f"/movie/{movie_id}/credits")

    # def search_movie(self, query: str, *, page: int = 1) -> Dict[str, Any]:
    #     return self._get("/search/movie", params={"query": query, "page": page})

    def popular_movies(self, page: int = 1, language: str = "en-US") -> Dict[str, Any]:
        return self._get(f"movie/popular?language={language}&page={page}")
    
    def keywords(self, movie_id: int) -> Dict[str, Any]:
        return self._get(f"/movie/{movie_id}/keywords")

    # def top_rated_movies(self, *, page: int = 1) -> Dict[str, Any]:
    #     return self._get("/movie/top_rated", params={"page": page})

    # def similar_movies(self, movie_id: int, *, page: int = 1) -> Dict[str, Any]:
    #     return self._get(f"/movie/{movie_id}/similar", params={"page": page})

    # def genre_list(self) -> List[Dict[str, Any]]:
    #     data = self._get("/genre/movie/list")
    #     return data.get("genres", [])
