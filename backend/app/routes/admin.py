from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from app.database import get_db
from app.models import Song
import os
import uuid
import shutil

router = APIRouter(prefix="/admin", tags=["Admin"])

# Endpoint สำหรับ Search ศิลปิน/อัลบั้ม (Autocomplete)
@router.get("/search-metadata")
def search_metadata(query: str, db: Session = Depends(get_db)):
    # ค้นหาชื่อศิลปินและอัลบั้มที่ไม่ซ้ำกันในระบบ
    artists = db.query(Song.artist_name).filter(Song.artist_name.ilike(f"%{query}%")).distinct().all()
    albums = db.query(Song.album_name).filter(Song.album_name.ilike(f"%{query}%")).distinct().all()
    
    return {
        "artists": [a[0] for a in artists if a[0]],
        "albums": [a[0] for a in albums if a[0]]
    }

@router.post("/songs/create")
async def create_custom_song(
    song_name: str = Form(...),
    category: str = Form(...),
    artist_name: str = Form(...),
    album_name: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    try:
        # Validation เบื้องต้น
        if not song_name or not artist_name:
            raise HTTPException(status_code=400, detail="Song name and Artist name are required")

        # จัดการไฟล์ภาพ
        upload_dir = "static/song_covers"
        os.makedirs(upload_dir, exist_ok=True)
        unique_filename = f"{uuid.uuid4()}_{file.filename}"
        file_path = os.path.join(upload_dir, unique_filename)

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        new_song = Song(
            song_name=song_name,
            category=category,
            artist_name=artist_name,
            album_name=album_name,
            song_cover_url=f"/{file_path}",
            is_custom_added=True
        )
        db.add(new_song)
        db.commit()
        db.refresh(new_song)
        return {"status": "success", "message": "Song created successfully", "data": new_song}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))