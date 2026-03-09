from typing import Optional

from pydantic import BaseModel, model_validator

class SongResponse(BaseModel):
    id: int
    song_name: str
    artist_name: Optional[str] = None
    song_cover_url: Optional[str] = None
    spotify_id: Optional[str] = None
    preview_url: Optional[str] = None

    class Config:
        from_attributes = True
