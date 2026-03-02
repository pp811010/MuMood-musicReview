from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from typing import Optional
from app.database import get_db
from app.models import Song
import os
import uuid
import aiofiles # ใช้สำหรับ Async File I/O

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.post("/songs/create")
async def create_custom_song(
    song_name: str = Form(...),
    category: str = Form(...),
    artist_name: str = Form(...),
    album_name: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db) # เปลี่ยนเป็น AsyncSession
):
    try:
        # 1. จัดการไฟล์ภาพแบบ Async
        upload_dir = "static/song_covers"
        os.makedirs(upload_dir, exist_ok=True)
        unique_filename = f"{uuid.uuid4()}_{file.filename}"
        file_path = os.path.join(upload_dir, unique_filename)

        # ใช้ aiofiles เพื่อไม่ให้ Blocking การทำงานของโปรแกรม
        async with aiofiles.open(file_path, 'wb') as out_file:
            content = await file.read()
            await out_file.write(content)

        # 2. บันทึกข้อมูลลง Database
        new_song = Song(
            song_name=song_name,
            category=category,
            artist_name=artist_name,
            album_name=album_name,
            # บันทึก URL สำหรับเข้าถึงรูปภาพ (ควรนำหน้าด้วย http://... เมื่อส่งไป Flutter)
            song_cover_url=f"/static/song_covers/{unique_filename}",
            is_custom_added=True
        )
        
        db.add(new_song)
        await db.commit() # ใช้ await สำหรับ Async
        await db.refresh(new_song)
        
        return {"status": "success", "data": {"id": new_song.id, "name": new_song.song_name}}
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