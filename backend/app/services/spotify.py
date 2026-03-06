# app/services/spotify.py  ← ย้ายมาไว้ที่นี่ทั้งหมด

import httpx
from fastapi import HTTPException
from app.core.config import settings


async def get_spotify_token() -> str:
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://accounts.spotify.com/api/token",
            data={"grant_type": "client_credentials"},
            auth=(settings.SPOTIFY_CLIENT_ID, settings.SPOTIFY_CLIENT_SECRET)
        )
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="ดึง Spotify token ไม่ได้")
        return response.json()["access_token"]


async def fetch_spotify_track(spotify_id: str) -> dict:
    token = await get_spotify_token()
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://api.spotify.com/v1/tracks/{spotify_id}",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code != 200:
            raise HTTPException(status_code=404, detail="ไม่พบเพลงนี้ใน Spotify")

        data = response.json()
        print("song detail", data)
        album_name = data.get("album", {}).get("name") if data.get("album") else None
        
        images = data.get("album", {}).get("images", [])
        cover_url = images[0]["url"] if images else None

        category = "General"
        artists = data.get("artists", [])
        if artists:
            artist_id = artists[0]["id"]
            artist_response = await client.get(
                f"https://api.spotify.com/v1/artists/{artist_id}",
                headers={"Authorization": f"Bearer {token}"}
            )
            if artist_response.status_code == 200:
                artist_data = artist_response.json()
                print('get artist', artist_data)
                genres = artist_data.get("genres", [])

                genre_mapping = {
                    "pop": "Pop",
                    "thai pop": "Pop",
                    "dance pop": "Pop",
                    "rock": "Rock",
                    "hard rock": "Rock",
                    "alt rock": "Rock",
                    "hip hop": "Hip Hop",
                    "rap": "Hip Hop",
                    "trap": "Hip Hop",
                    "r&b": "R&B",
                    "soul": "R&B",
                    "rhythm and blues": "R&B",
                    "jazz": "Jazz",
                    "k-pop": "K-Pop",
                    "korean pop": "K-Pop",
                    "indie": "Indie",
                    "indie pop": "Indie",
                    "indie rock": "Indie",
                    "classical": "Classical",
                    "metal": "Metal",
                    "heavy metal": "Metal",
                    "edm": "EDM",
                    "electronic": "EDM",
                    "house": "EDM",
                    "techno": "EDM",
                }

                raw_genre = genres[0].lower() if genres else ""
                category = next((v for k, v in genre_mapping.items() if k in raw_genre), "General")

        return {
            "name": data.get("name"),
            "artist": ", ".join([a["name"] for a in artists]),
            "album": album_name,
            "cover": cover_url,
            "preview_url": data.get("preview_url"),
            "category": category
        }