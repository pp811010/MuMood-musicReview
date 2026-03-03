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
        album_name = data.get("album", {}).get("name") if data.get("album") else None
        
        images = data.get("album", {}).get("images", [])
        cover_url = images[0]["url"] if images else None

        # 3. ดึง Genre/Category (ดึงจากข้อมูล Artist มาเป็นตัวแทน)
        # เนื่องจาก Spotify API ไม่มีค่า category โดยตรงใน track object
        category = "General" # ตั้งค่า Default ไว้ก่อน
        
        return {
            "name": data.get("name"),
            "artist": ", ".join([a["name"] for a in data.get("artists", [])]),
            "album": album_name,
            "cover": cover_url,
            "preview_url": data.get("preview_url"),
            "category": category 
        }