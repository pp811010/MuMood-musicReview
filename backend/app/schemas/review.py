from datetime import datetime
from pydantic import BaseModel
from typing import Optional


class ReviewRequest(BaseModel):
    """
    ใช้สร้าง review ใหม่ — เก็บแค่ scores + emotion + mood
    comment แยกไปใช้ POST /comment/ แทน
    """
    song_id_reference: str
    emotion_id: Optional[int] = None
    mood_color_id: Optional[int] = None
    beat_score: Optional[float] = None
    lyric_score: Optional[float] = None
    mood_score: Optional[float] = None
    source: str
    # ❌ comment ถูกลบออกแล้ว — ใช้ /comment/ endpoint แทน


class ReviewUpdate(BaseModel):
    """
    ใช้แก้ไข review — แก้ได้แค่ scores + emotion + mood
    ลบ review ไม่ได้
    """
    emotion_id: Optional[int] = None
    mood_color_id: Optional[int] = None
    beat_score: Optional[float] = None
    lyric_score: Optional[float] = None
    mood_score: Optional[float] = None
    # ❌ comment ถูกลบออกแล้ว — ใช้ /comment/ endpoint แทน


class ReviewResponse(BaseModel):
    id: int
    user_id: int
    song_id: int
    emotion_id: Optional[int] = None
    mood_color_id: Optional[int] = None
    beat_score: Optional[float] = None
    lyric_score: Optional[float] = None
    mood_score: Optional[float] = None
    created_at: datetime
    updated_at: datetime
    # ❌ comment field ถูกลบออกแล้ว

    class Config:
        from_attributes = True