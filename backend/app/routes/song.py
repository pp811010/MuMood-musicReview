from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession
import httpx
import asyncio
from app.models import Favorite, Review, Song, User
from app.schemas.song import SongCreate, SongResponse, SongUpdate
from app.database import SessionDep
from app.services.spotify import get_spotify_token
from app.core.security import get_current_user
from sqlalchemy.orm import selectinload

router = APIRouter(prefix="/songs", tags=["Songs"])

BASE_URL = "http://10.0.2.2:8000"

BASE_URL = "http://10.0.2.2:8000"

@router.get("/search")
async def search_songs(q: str, db: SessionDep):
    token = await get_spotify_token()

    # 1. ค้นหาใน DB ของเราก่อน
    stmt = select(Song).where(
        or_(
            Song.song_name.ilike(f"%{q}%"), 
            Song.artist_name.ilike(f"%{q}%")
        )
    ).limit(15)
    result = await db.execute(stmt)
    db_songs = result.scalars().all()
    
    # สร้าง Map เพื่อเช็คเพลงซ้ำจาก Spotify ID
    db_spotify_ids = {s.spotify_id for s in db_songs if s.spotify_id}

    results = []
    for s in db_songs:
        img = s.song_cover_url
        if img and img.startswith("/static"):
            img = f"{BASE_URL}{img}"
        results.append({
            "id":  str(s.id),
            "name": s.song_name,
            "artist": s.artist_name,
            "image": img,
            "source": "db",
            "preview_url": s.preview_url,
            "is_custom": s.is_custom_added
        })

    # ค้นหาใน Spotify
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            "https://api.spotify.com/v1/search",
            headers={"Authorization": f"Bearer {token}"},
            params={"q": q, "type": "track", "limit": 10}
        )
        spotify_items = resp.json().get("tracks", {}).get("items", [])

    # รวมผลลัพธ์ (Merge & Deduplicate)
    final_results = db_results.copy()
    for item in spotify_items:
        if item["id"] in db_spotify_ids:
            continue # ข้ามถ้ามีในคลังเราแล้ว
        results.append({
            "id": item["id"],
            "name": item["name"],
            "artist": item["artists"][0]["name"] if item.get("artists") else "Unknown",
            "preview_url": item.get("preview_url"),
            "image": item["album"]["images"][0]["url"] if item.get("album") else None,
            "source": "spotify",
            "is_custom": False
        })

    return {"results": results}



@router.get("/detail/{identifier}", response_model=SongResponse)
async def get_song_detail(identifier: str, db: SessionDep, current_user: User = Depends(get_current_user)):
    stmt = (
        select(Song).where(Song.id == int(identifier))
        if identifier.isdigit()
        else select(Song).where(Song.spotify_id == identifier)
    )
    result = await db.execute(stmt)
    db_song = result.scalar_one_or_none()

    if db_song:
        reviews_stmt = (
            select(Review)
            .where(Review.song_id == db_song.id)
            .options(
                selectinload(Review.emotion),
                selectinload(Review.mood_color),
                selectinload(Review.user)
            )
        )
        reviews_result = await db.execute(reviews_stmt)
        reviews = reviews_result.scalars().all()

        beat_scores = [r.beat_score for r in reviews if r.beat_score is not None]
        lyric_scores = [r.lyric_score for r in reviews if r.lyric_score is not None]
        mood_scores = [r.mood_score for r in reviews if r.mood_score is not None]

        avg_beat = sum(beat_scores) / len(beat_scores) if beat_scores else 0.0
        avg_lyric = sum(lyric_scores) / len(lyric_scores) if lyric_scores else 0.0
        avg_mood = sum(mood_scores) / len(mood_scores) if mood_scores else 0.0

        emotion_counts = {}
        for r in reviews:
            if r.emotion:
                name = r.emotion.name
                emotion_counts[name] = emotion_counts.get(name, 0) + 1

        color_counts = {}
        for r in reviews:
            if r.mood_color:
                hex_color = r.mood_color.color_hex
                color_counts[hex_color] = color_counts.get(hex_color, 0) + 1

        fav_stmt = select(Favorite).where(
            Favorite.song_id == db_song.id,
            Favorite.user_id == current_user.id
        )
        fav_result = await db.execute(fav_stmt)
        is_favorite = fav_result.scalar_one_or_none() is not None

        dominant_color = max(color_counts, key=color_counts.get) if color_counts else None

        return {
            "id": str(db_song.id),
            "song_name": db_song.song_name,
            "artist_name": db_song.artist_name,
            "spotify_id": db_song.spotify_id,
            "is_custom_added": db_song.is_custom_added,
            "song_cover_url": db_song.song_cover_url,
            "favorite": is_favorite,
            "avg_scores": {
                "beat": round(avg_beat, 2),
                "lyric": round(avg_lyric, 2),
                "mood": round(avg_mood, 2),
            },
            "preview_url": db_song.preview_url,
            "emotion_counts": emotion_counts,
            "color_counts": color_counts,
            "dominant_color": dominant_color,
            "comment": [
                {
                    "user_id": r.user_id,
                    "username": r.user.username,
                    "comment": r.comment,
                    "created_at": r.created_at,
                }
                for r in reviews
                if r.comment and r.comment.strip() != ''
            ],
            "source": "db",
        }
    
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
            "favorite": False,
            "avg_scores": {"beat": 0.0, "lyric": 0.0, "mood": 0.0},
            "song_cover_url": data["album"]["images"][0]["url"] if data.get("album") else None,
            "emotion_counts": {},
            "preview_url": data.get("preview_url"), 
            "color_counts": {},
            "dominant_color": None,
            "comment": [],
            "source": "spotify",
        }


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