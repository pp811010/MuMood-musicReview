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

router = APIRouter(prefix="/admin", tags=["Admin"])

# Endpoint สำหรับ Search ศิลปิน/อัลบั้ม (Autocomplete)
@router.get("/search-metadata")
async def search_metadata(query: str, db: AsyncSession = Depends(get_db)):
    """ค้นหาศิลปินและอัลบั้มในระบบแบบ Autocomplete"""
    
    # 1. ค้นหาชื่อศิลปินที่ไม่ซ้ำกัน
    artist_stmt = select(Song.artist_name).where(Song.artist_name.ilike(f"%{query}%")).distinct()
    artist_result = await db.execute(artist_stmt)
    artists = artist_result.scalars().all()
    
    # 2. ค้นหาชื่ออัลบั้มที่ไม่ซ้ำกัน
    album_stmt = select(Song.album_name).where(Song.album_name.ilike(f"%{query}%")).distinct()
    album_result = await db.execute(album_stmt)
    albums = album_result.scalars().all()
    
    return {
        "artists": [a for a in artists if a],
        "albums": [a for a in albums if a]
    }

@router.post("/songs/create")
async def create_custom_song(
    song_name: str = Form(...),
    category: str = Form(...),
    artist_name: str = Form(...),
    album_name: str = Form(None),
    file: UploadFile = File(...),
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

@router.get("/search-metadata")
async def search_metadata(query: str, db: AsyncSession = Depends(get_db)):
    """ค้นหาข้อมูลศิลปิน/อัลบั้มที่มีอยู่แล้วเพื่อช่วย User พิมพ์"""
    # ค้นหาศิลปิน
    artist_stmt = select(Song.artist_name).where(Song.artist_name.ilike(f"%{query}%")).distinct()
    artist_res = await db.execute(artist_stmt)
    
    # ค้นหาอัลบั้ม
    album_stmt = select(Song.album_name).where(Song.album_name.ilike(f"%{query}%")).distinct()
    album_res = await db.execute(album_stmt)
    
    return {
        "artists": [a[0] for a in artist_res.all() if a[0]],
        "albums": [a[0] for a in album_res.all() if a[0]]
    }