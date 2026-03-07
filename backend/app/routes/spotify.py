# app/routers/spotify.py  ← แก้ให้ใช้ async httpx ทั้งหมด

from fastapi import APIRouter, Query, Depends, HTTPException
import httpx
from sqlalchemy import select
from app.database import SessionDep
from app.models import Song
from app.services.spotify import get_spotify_token 

router = APIRouter(prefix="/spotify", tags=["Spotify"])

BASE_URL = "http://10.0.2.2:8000"

@router.get("/top-charts")
async def get_top_charts():
    token = await get_spotify_token()
    headers = {"Authorization": f"Bearer {token}"}
    results = {"TH": [], "US": []}

    async with httpx.AsyncClient() as client:
        for market in ["TH", "US"]:
            response = await client.get(
                "https://api.spotify.com/v1/search",
                headers=headers,
                params={"q": "year:2024-2025", "type": "track", "market": market, "limit": 10}
            )
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=response.json())

            tracks = response.json()["tracks"]["items"]
            tracks.sort(key=lambda x: x.get("popularity") or 0, reverse=True)

            for track in tracks:
                results[market].append({
                    "id": track["id"],
                    "song_name": track["name"],
                    "artist_name": track["artists"][0]["name"] if track.get("artists") else "Unknown",
                    "album_name": track["album"]["name"] if track.get("album") else None,
                    "song_cover_url": track["album"]["images"][0]["url"] if track.get("album") and track["album"].get("images") else None,
                    "preview_url": track.get("preview_url"),
                    "popularity": track.get("popularity") or 0,
                    "spotify_url": track["external_urls"]["spotify"]
                })

    return {"status": "success", "charts": results}


@router.get("/songs-by-genre")
async def get_songs_by_genre(genre: str = "pop", limit: int = 10):
    token = await get_spotify_token()
    async with httpx.AsyncClient() as client:
        if genre.lower() == "all":
            params = {"q": "a", "type": "track", "limit": limit, "market": "US"}
        else:
            params = {"q": f"genre:{genre}", "type": "track", "limit": limit, "market": "US"}

        response = await client.get(
            "https://api.spotify.com/v1/search",
            headers={"Authorization": f"Bearer {token}"},
            params=params
        )
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail=response.json())
        tracks = response.json()["tracks"]["items"]
    results = [{
        "id": t["id"],
        "song_name": t["name"],
        "artist_name": t["artists"][0]["name"] if t.get("artists") else "Unknown",
        "album_name": t["album"]["name"] if t.get("album") else None,
        "song_cover_url": t["album"]["images"][0]["url"] if t.get("album") and t["album"].get("images") else None,
        "preview_url": t.get("preview_url")
    } for t in tracks]

    return {"status": "success", "genre": genre, "songs": results}



@router.get("/search")
async def search_music(q: str = Query(...)):
    token = await get_spotify_token()

    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://api.spotify.com/v1/search",
            headers={"Authorization": f"Bearer {token}"},
            params={"q": q, "type": "track", "limit": 10}
        )
        data = response.json()

    if "tracks" not in data:
        return {"results": [], "error": "No tracks found"}

    results = [item for item in data["tracks"]["items"]]

    return {"results": results}


# @router.get("/get-detail/{spotify_id}")
# async def get_music(spotify_id: str):
#     token = await get_spotify_token()

#     async with httpx.AsyncClient() as client:
#         response = await client.get(
#             f"https://api.spotify.com/v1/tracks/{spotify_id}",
#             headers={"Authorization": f"Bearer {token}"}
#         )
#         if response.status_code != 200:
#             raise HTTPException(status_code=response.status_code, detail=response.json())

#     return {"results": response.json()}