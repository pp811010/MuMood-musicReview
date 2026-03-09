from datetime import datetime
from pydantic import BaseModel
from typing import Optional


class ReviewRequest(BaseModel):
    song_id_reference: str
    emotion_id: Optional[int] = None
    mood_color_id: Optional[int] = None
    beat_score: Optional[float] = None
    lyric_score: Optional[float] = None
    mood_score: Optional[float] = None
    source: str


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
    class Config:
        from_attributes = True