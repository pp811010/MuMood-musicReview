from fastapi import APIRouter, Body, Depends, HTTPException
from sqlalchemy import select

from app.core.security import get_current_active_user
from app.database import SessionDep
from app.models import Review, Song, User
from app.schemas.comment import CommentCreate
from app.services.spotify import fetch_spotify_track


router = APIRouter(prefix="/comment", tags=["comment"])

@router.post("/standalone")
async def create_comment_standalone(
    review: CommentCreate,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user)
):
    
    if review.source == "spotify":
        stmt = select(Song).where(Song.spotify_id == review.song_id_reference)
        song = (await db.execute(stmt)).scalar_one_or_none()
        
        if not song:
            spotify_data = await fetch_spotify_track(review.song_id_reference)
            song = Song(
                spotify_id=review.song_id_reference,
                song_name=spotify_data["name"],
                artist_name=spotify_data["artist"],
                album_name=spotify_data["album"],
                song_cover_url=spotify_data["cover"],
                link_url = spotify_data["link_url"],
                is_custom_added=False
            )
            db.add(song)
            await db.flush() 
        target_song_id = song.id
    else:
        target_song_id = int(review.song_id_reference)

    
    new_review = Review(
        user_id=current_user.id,
        song_id=target_song_id,
        comment=review.comment
    )

    db.add(new_review)
    await db.commit()
    await db.refresh(new_review)
    
    return {"status": "success", "message": "Comment added/updated"}