from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from app.database import get_db
from app.models import Song
import os
import uuid
import aiofiles
import httpx
from app.services.spotify import get_spotify_token

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/search-metadata")
async def search_metadata(query: str, db: AsyncSession = Depends(get_db)):
    """ค้นหาข้อมูลเพลง ศิลปิน และอัลบั้ม ทั้งจาก DB และ Spotify แบบ Autocomplete สำหรับ suggesstion"""
    
    internal_stmt = select(Song).where(
        or_(
            Song.song_name.ilike(f"%{query}%"),
            Song.artist_name.ilike(f"%{query}%")
        )
    ).limit(5)
    internal_result = await db.execute(internal_stmt)
    internal_songs = internal_result.scalars().all()

    spotify_songs = []
    token = await get_spotify_token()
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            "https://api.spotify.com/v1/search",
            headers={"Authorization": f"Bearer {token}"},
            params={"q": query, "type": "track", "limit": 10}
        )
        if resp.status_code == 200:
            spotify_items = resp.json().get("tracks", {}).get("items", [])
            for item in spotify_items:
                spotify_songs.append({
                    "name": item["name"],
                    "artist": item["artists"][0]["name"] if item.get("artists") else "Unknown",
                    "album": item["album"]["name"] if item.get("album") else "",
                    "display": f"{item['name']} - {item['artists'][0]['name']} (Spotify)"
                })

    formatted_internal = [
        {
            "name": s.song_name,
            "artist": s.artist_name,
            "album": s.album_name or "",
            "display": f"{s.song_name} - {s.artist_name} (Database)"
        } for s in internal_songs
    ]

    all_suggestions = formatted_internal + spotify_songs
    
    return {
        "songs": all_suggestions,
        "artists": list(set([s['artist'] for s in all_suggestions])),
        "albums": list(set([s['album'] for s in all_suggestions if s['album']]))
    }

@router.post("/songs/create")
async def create_custom_song(
    song_name: str = Form(...),
    category: str = Form(...),
    artist_name: str = Form(...),
    album_name: str = Form(None),
    file: UploadFile = File(...),
    link_url: str = Form(None),
    db: AsyncSession = Depends(get_db)
):
    try:
        upload_dir = "static/song_covers"
        os.makedirs(upload_dir, exist_ok=True)
        unique_filename = f"{uuid.uuid4()}_{file.filename}"
        file_path = os.path.join(upload_dir, unique_filename)

        async with aiofiles.open(file_path, 'wb') as out_file:
            content = await file.read()
            await out_file.write(content)

        new_song = Song(
            song_name=song_name,
            category=category,
            artist_name=artist_name,
            album_name=album_name,
            link_url=link_url,
            song_cover_url=f"/static/song_covers/{unique_filename}",
            is_custom_added=True
        )
        
        db.add(new_song)
        await db.commit()
        await db.refresh(new_song)

        return {"status": "success", "message": "Song created successfully", "data": new_song}
    
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
