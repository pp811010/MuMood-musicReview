from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select
from app.database import get_db, SessionDep
from app.models import User, Song, Favorite
from app.routes.auth import get_current_active_user
from typing import List
from pydantic import BaseModel

router = APIRouter(
    prefix="/favorites",
    tags=["favorites"]
)

# Schema Return ข้อมูลเพลง
class SongResponse(BaseModel):
    id: int
    song_name: str
    artist_name: str
    song_cover_url: str
    
    class Config:
        orm_mode = True

@router.get("/", response_model=List[SongResponse])
async def get_my_favorites(
    db: SessionDep, 
    current_user: User = Depends(get_current_active_user)
):
    # Join ตาราง Favorite กับ Song
    stmt = (
        select(Song)
        .join(Favorite, Favorite.song_id == Song.id)
        .where(Favorite.user_id == current_user.id)
    )
    result = await db.execute(stmt)
    songs = result.scalars().all()
    return songs

@router.post("/toggle/{song_id}")
async def toggle_favorite(
    song_id: int, 
    db: SessionDep, 
    current_user: User = Depends(get_current_active_user)
):
    # เช็คว่ามีเพลงนี้ในระบบ
    stmt_song = select(Song).where(Song.id == song_id)
    res_song = await db.execute(stmt_song)
    song = res_song.scalars().first()
    if not song:
        raise HTTPException(status_code=404, detail="Song not found")

    # เช็คว่าเคย Fav หรือยัง
    stmt_fav = select(Favorite).where(
        Favorite.user_id == current_user.id, 
        Favorite.song_id == song_id
    )
    res_fav = await db.execute(stmt_fav)
    existing_fav = res_fav.scalars().first()

    if existing_fav:
        # ถ้ามีแล้ว ให้ลบออก (Unfavorite)
        await db.delete(existing_fav)
        await db.commit()
        return {"message": "Removed from favorites", "is_favorited": False}
    else:
        # ถ้ายังไม่มี ให้เพิ่ม (Favorite)
        new_fav = Favorite(user_id=current_user.id, song_id=song_id)
        db.add(new_fav)
        await db.commit()
        return {"message": "Added to favorites", "is_favorited": True}