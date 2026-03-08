from pydantic import BaseModel


class CommentCreate(BaseModel):
    song_id_reference: str
    comment: str
    source: str
