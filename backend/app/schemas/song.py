from datetime import datetime
from pydantic import BaseModel
from typing import  Optional, Union
class SongBase(BaseModel):
    song_name: str
    artist_name: Optional[str] = None
    album_name: Optional[str] = None
    song_cover_url: Optional[str] = None
    preview_url: Optional[str] = None
    category: Optional[str] = None

class SongCreate(SongBase):
    spotify_id: Optional[str] = None
    is_custom_added: bool = False

class CommentInSong(BaseModel):
    user_id: int
    username: str
    comment: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class SongResponse(BaseModel):
    id: str
    song_name: str
    artist_name: Optional[str] = None
    spotify_id: Optional[str] = None
    is_custom_added: bool = False
    favorite: bool = False
    avg_scores: dict = {"beat": 0.0, "lyric": 0.0, "mood": 0.0}
    emotion_counts: dict = {} 
    color_counts: dict = {} 
    comment: list[CommentInSong] = []
    source: str
    dominant_color: Optional[str] = None 
    song_cover_url: Optional[str] = None 

    class Config:
        from_attributes = True

class SongUpdate(BaseModel):
    song_name: Optional[str] = None
    artist_name: Optional[str] = None
    album_name: Optional[str] = None
    song_cover_url: Optional[str] = None
    preview_url: Optional[str] = None
    category: Optional[str] = None
    is_custom_added: Optional[bool] = None