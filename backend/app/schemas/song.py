from pydantic import BaseModel
from typing import Optional, Union

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

class SongResponse(BaseModel):
    id: Union[int, str]  # ยอมรับได้ทั้งตัวเลขและข้อความ
    song_name: str
    artist_name: Optional[str] = None
    spotify_id: Optional[str] = None
    is_custom_added: bool = False

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