from fastapi import APIRouter, HTTPException
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession
import httpx
import asyncio
from app.models import Song
from app.schemas.song import SongCreate, SongResponse, SongUpdate
from app.database import SessionDep
from app.services.spotify import get_spotify_token

router = APIRouter(prefix="/songs", tags=["Songs"])

# 1. SEARCH: ค้นหาทั้งใน DB และ Spotify พร้อมกัน (รวมผลลัพธ์)
@router.get("/search")
async def search_songs(q: str, db: SessionDep):
    token = await get_spotify_token()

    # ค้นหาใน DB
    stmt = select(Song).where(
        or_(Song.song_name.ilike(f"%{q}%"), Song.artist_name.ilike(f"%{q}%"))
    ).limit(10)
    result = await db.execute(stmt)
    db_songs = result.scalars().all()
    
    db_song_map = {s.spotify_id: s for s in db_songs if s.spotify_id}

    db_results = [{
        "id": s.id,
        "name": s.song_name,
        "artist": s.artist_name,
        "image": s.song_cover_url,
        "source": "db"
    } for s in db_songs]

    # ค้นหาใน Spotify
    async with httpx.AsyncClient() as client:
        headers = {"Authorization": f"Bearer {token}"}
        response = await client.get(
            "https://api.spotify.com/v1/search",
            headers=headers,
            params={"q": q, "type": "track", "limit": 10}
        )
        spotify_items = response.json().get("tracks", {}).get("items", [])

    # รวมผลลัพธ์ (Merge & Deduplicate)
    final_results = db_results.copy()
    for item in spotify_items:
        if item["id"] in db_song_map:
            continue
        final_results.append({
            "id": item["id"],
            "name": item["name"],
            "artist": item["artists"][0]["name"] if item.get("artists") else "Unknown",
            "image": item["album"]["images"][0]["url"] if item.get("album") else None,
            "source": "spotify"
        })

    return {"query": q, "results": final_results}

# 2. RESOLVE: ดึงข้อมูลเพลง (ถ้าไม่มีใน DB ให้ไปดึงจาก Spotify)
@router.get("/resolve/{identifier}", response_model=SongResponse)
async def get_song_detail(identifier: str, db: SessionDep):
    # ค้นหาใน DB
    stmt = select(Song).where(Song.id == int(identifier)) if identifier.isdigit() else select(Song).where(Song.spotify_id == identifier)
    result = await db.execute(stmt)
    db_song = result.scalar_one_or_none()

    if db_song:
        return db_song

    # ถ้าหาไม่เจอใน DB ให้ดึงจาก Spotify
    if identifier.isdigit():
        raise HTTPException(status_code=404, detail="Song not found in database")

    token = await get_spotify_token()
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://api.spotify.com/v1/tracks/{identifier}", 
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code != 200:
            raise HTTPException(status_code=404, detail="Song not found on Spotify")
        
        data = response.json()
        return {
            "id": identifier,
            "song_name": data["name"],
            "artist_name": data["artists"][0]["name"],
            "spotify_id": identifier,
            "is_custom_added": False,
        }

# 3. CRUD มาตรฐาน
@router.post("/", response_model=SongResponse)
async def create_song(song: SongCreate, db: SessionDep):
    db_song = Song(**song.model_dump())
    db.add(db_song)
    await db.commit()
    await db.refresh(db_song)
    return db_song

@router.patch("/{song_id}", response_model=SongResponse)
async def update_song(song_id: int, song_update: SongUpdate, db: SessionDep):
    stmt = select(Song).where(Song.id == song_id)
    result = await db.execute(stmt)
    db_song = result.scalar_one_or_none()
    
    if not db_song:
        raise HTTPException(status_code=404, detail="Song not found")

    for key, value in song_update.model_dump(exclude_unset=True).items():
        setattr(db_song, key, value)
        
    await db.commit()
    await db.refresh(db_song)
    return db_song

@router.delete("/{song_id}")
async def delete_song(song_id: int, db: SessionDep):
    stmt = select(Song).where(Song.id == song_id)
    result = await db.execute(stmt)
    db_song = result.scalar_one_or_none()
    if not db_song:
        raise HTTPException(status_code=404, detail="Song not found")
        
    await db.delete(db_song)
    await db.commit()
    return {"message": "Song deleted successfully"}