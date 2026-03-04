from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select
from app.database import get_db, SessionDep
from app.models import User, Song, Favorite
from app.routes.auth import get_current_active_user
from typing import List
from pydantic import BaseModel
from app.services.spotify import fetch_spotify_track

router = APIRouter(
    prefix="/favorites",
    tags=["favorites"]
)

class FavoriteRequest(BaseModel):
    song_id_reference: str
    source: str


class SongResponse(BaseModel):
    id: int
    song_name: str
    artist_name: str
    song_cover_url: str
    
    class Config:
        orm_mode = True

@router.get("/history/me", response_model=List[SongResponse])
async def get_my_favorites(
    db: SessionDep, 
    current_user: User = Depends(get_current_active_user)
):
    stmt = (
        select(Song)
        .join(Favorite, Favorite.song_id == Song.id)
        .where(Favorite.user_id == current_user.id)
    )
    result = await db.execute(stmt)
    songs = result.scalars().all()
    return songs

@router.get("/status/{identifier}")
async def check_favorite_status(
    identifier: str, 
    source: str, 
    db: SessionDep, 
    current_user: User = Depends(get_current_active_user)
):
    if source == "spotify":
        song = await db.scalar(select(Song).where(Song.spotify_id == identifier))
    else:
        song = await db.scalar(select(Song).where(Song.id == int(identifier)))
    

    if not song:
        return {"is_favorited": False}
    
    # 2. เช็คว่า User เคย Favorite ไหม
    existing = await db.scalar(
        select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.song_id == song.id
        )
    )
    
    return {"is_favorited": bool(existing)}



@router.post("/toggle")
async def toggle_favorite(
    data: FavoriteRequest,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user)
):
    song = None
    
    if data.source == "spotify":
        song = await db.scalar(select(Song).where(Song.spotify_id == data.song_id_reference))
        
        if not song:
            spotify_data = await fetch_spotify_track(data.song_id_reference)
            song = Song(
                spotify_id=data.song_id_reference,
                song_name=spotify_data["name"],
                artist_name=spotify_data["artist"],
                album_name=spotify_data["album"],
                song_cover_url=spotify_data["cover"],
                preview_url=spotify_data["preview_url"],
                is_custom_added=False
            )
            db.add(song)
            await db.flush() # flush เพื่อให้ได้ song.id ไปใช้
            
    else: # ถ้า source ไม่ใช่ spotify (เช่น "db")
        song = await db.scalar(select(Song).where(Song.id == int(data.song_id_reference)))
        if not song:
            raise HTTPException(status_code=404, detail="ไม่พบเพลงนี้ในระบบ")

    # 2. Toggle Favorite (ใช้ song.id ที่ได้มาแน่นอนแล้ว)
    existing = await db.scalar(
        select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.song_id == song.id
        )
    )

    if existing:
        await db.delete(existing)
        message = "Removed from favorites"
        is_favorited = False
    else:
        db.add(Favorite(user_id=current_user.id, song_id=song.id))
        message = "Added to favorites"
        is_favorited = True

    await db.commit()
    return {"message": message, "is_favorited": is_favorited}