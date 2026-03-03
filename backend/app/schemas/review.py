from datetime import datetime
from pydantic import BaseModel, model_validator
from typing import Optional


class ReviewRequest(BaseModel):
    song_id_reference: str
    emotion_id: int
    mood_color_id: int
    beat_score: float
    lyric_score: float
    mood_score: float
    comment: Optional[str] = None
    source: str

  


class ReviewUpdate(BaseModel):
    emotion_id: Optional[int] = None
    mood_color_id: Optional[int] = None
    beat_score: Optional[float] = None
    lyric_score: Optional[float] = None
    mood_score: Optional[float] = None
    comment: Optional[str] = None


class ReviewResponse(BaseModel):
    id: int
    user_id: int
    song_id: int
    emotion_id: int
    mood_color_id: int
    beat_score: float
    lyric_score: float
    mood_score: float
    comment: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True