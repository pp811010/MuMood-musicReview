import base64
import httpx
from fastapi import APIRouter, Query, Depends, HTTPException
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models import Song
import datetime

router = APIRouter(prefix="/spotify", tags=["Spotify"])

# --- Configuration ---
CLIENT_ID = 'a9d74c8adc794984bd92c755bf5f6c7c'
CLIENT_SECRET = '9596a8a1632a453cb918b00d1972559c'
REDIRECT_URI = "http://127.0.0.1:8000/spotify/callback"
SCOPE = "playlist-read-private playlist-read-collaborative user-library-read"

@router.get("/all-songs")
async def get_all_songs(db: AsyncSession = Depends(get_db)):
    """ดึงเพลงทั้งหมดจาก DB มาแสดงผล (Async Version)"""
    stmt = select(Song).order_by(Song.id.desc())
    result = await db.execute(stmt)
    db_songs = result.scalars().all()
    
    return {
        "results": [
            {
                "id": song.id,
                "spotify_id": song.spotify_id,
                "name": song.song_name,
                "artist": song.artist_name,
                "image": song.song_cover_url,
                "preview_url": song.preview_url,
                "is_custom": song.is_custom_added
            } for song in db_songs
        ]
    }

@router.get("/search")
async def search_music(q: str = Query(...), token: str = Query(None)):
    """ค้นหาเพลงใหม่จาก Spotify API"""
    if not token:
        raise HTTPException(status_code=400, detail="Token required")
        
    headers = {"Authorization": f"Bearer {token}"}
    url = "https://api.spotify.com/v1/search"
    params = {"q": q, "type": "track", "limit": 10}
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, headers=headers, params=params)
        data = response.json()
        
    results = []
    for item in data.get('tracks', {}).get('items', []):
        images = item.get('album', {}).get('images', [])
        results.append({
            "id": item.get('id'),
            "name": item.get('name'),
            "artist": item['artists'][0]['name'] if item['artists'] else "Unknown",
            "image": images[0].get('url') if images else None,
            "preview_url": item.get('preview_url')
        })
        
    return {"results": results}

# FORCE WAY
async def get_admin_token():
    """ขอ Token แบบหลังบ้าน (Client Credentials) ไม่ต้อง Login User"""
    auth_string = f"{CLIENT_ID}:{CLIENT_SECRET}"
    auth_base64 = base64.b64encode(auth_string.encode("utf-8")).decode("utf-8")
    url = "https://accounts.spotify.com/api/token"
    headers = {
        "Authorization": f"Basic {auth_base64}",
        "Content-Type": "application/x-www-form-urlencoded"
    }
    data = {"grant_type": "client_credentials"}
    async with httpx.AsyncClient() as client:
        response = await client.post(url, headers=headers, data=data)
        return response.json().get("access_token")

@router.post("/force-import")
async def force_import(db: AsyncSession = Depends(get_db)):
    """ดึงเพลงลง DB โดยใช้ Search API แบบคลีนที่สุดเพื่อเลี่ยง Error 400"""
    token = await get_admin_token() 
    headers = {"Authorization": f"Bearer {token}"}
    
    # ใช้คำค้นหาที่หลากหลายเพื่อให้ได้เพลงจำนวนมาก
    search_queries = ["TattooColour", "ThreeManDown", "Safeplanet", "InkWaruntorn", "URBOYTJ"]
    total_imported = 0

    async with httpx.AsyncClient() as client:
        for q in search_queries:
            search_url = "https://api.spotify.com/v1/search"
            query_params = {
                "q": q,
                "type": "track",
                "limit": 10 
            }
            
            try:
                res = await client.get(search_url, headers=headers, params=query_params)
                
                if res.status_code != 200:
                    print(f"DEBUG: Search Error {res.status_code} for {q} -> {res.text}")
                    continue

                data = res.json()
                tracks = data.get('tracks', {}).get('items', [])
                
                for track in tracks:
                    if not track or not track.get('id'): continue

                    stmt = select(Song).where(Song.spotify_id == track['id'])
                    result = await db.execute(stmt)
                    if not result.scalars().first():
                        images = track.get('album', {}).get('images', [])
                        new_song = Song(
                            spotify_id=track['id'],
                            song_name=track['name'],
                            artist_name=track['artists'][0]['name'] if track['artists'] else "Unknown",
                            album_name=track.get('album', {}).get('name'),
                            song_cover_url=images[0].get('url') if images else None,
                            preview_url=track.get('preview_url'),
                            is_custom_added=False
                        )
                        db.add(new_song)
                        total_imported += 1

            except Exception as e:
                print(f"DEBUG: Exception during search -> {e}")
                continue

        await db.commit() 
    return {"status": "success", "imported_count": total_imported}