from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_, select

from app.database import SessionDep
from app.schemas.review import ReviewRequest, ReviewResponse, ReviewUpdate
from app.models import Review, Song, User
from app.core.security import get_current_active_user
from app.services.spotify import fetch_spotify_track 


router = APIRouter(prefix="/review", tags=["Review"])


from sqlalchemy import select, and_

@router.get('/me')
async def get_review_me(
    db: SessionDep, 
    song_identifier: str, 
    current_user: User = Depends(get_current_active_user)
):
    if song_identifier.isdigit():
        stmt_song = select(Song).where(Song.id == int(song_identifier))
    else:
        stmt_song = select(Song).where(Song.spotify_id == song_identifier)
        
    result_song = await db.execute(stmt_song)
    song = result_song.scalar_one_or_none()

    if not song:
        raise HTTPException(status_code=404, detail="This song not have reviewed")
    

    stmt_review = select(Review).where(
        and_(
            Review.user_id == current_user.id,
            Review.song_id == song.id
        )
    )
    result_review = await db.execute(stmt_review)
    review = result_review.scalar_one_or_none()

    if not review:
        raise HTTPException(status_code=404, detail="Review not found for this user and song")

    return review


@router.delete('/delete/comment/{review_id}')
async def delete_review(
    review_id: int,
    db: SessionDep
):
    stmt = select(Review).where(Review.id == review_id);
    result = await db.execute(stmt)
    review = result.scalar_one_or_none();
    
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    review.comment = None;
    await db.commit()
       
    return {"massage": "delete comment success"}


@router.post('/')
async def create_review(
    db: SessionDep,
    review: ReviewRequest,
    current_user: User = Depends(get_current_active_user)
):
    print('id', review.song_id_reference)
    target_song_id = None
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
                preview_url=spotify_data["preview_url"],
                link_url = spotify_data["link_url"],
                is_custom_added=False
            )
            db.add(song)
            await db.flush() 
        target_song_id = song.id
    else:
        target_song_id = int(review.song_id_reference)

    existing_review = await db.scalar(
        select(Review).where(
            Review.user_id == current_user.id,
            Review.song_id == target_song_id
        )
    )

    if existing_review:
        raise HTTPException(
            status_code=400, 
            detail="คุณเคยรีวิวเพลงนี้ไปแล้ว หากต้องการแก้ไขให้ใช้ PUT แทนครับ"
        )

    new_review = Review(
        user_id=current_user.id,
        song_id=target_song_id,
        emotion_id=review.emotion_id,
        mood_color_id=review.mood_color_id,
        beat_score=review.beat_score,
        lyric_score=review.lyric_score,
        mood_score=review.mood_score,
        comment=review.comment
    )
    db.add(new_review)
    await db.commit()
    await db.refresh(new_review)
    
    return {"status": "create review success", "review": new_review}


@router.get("/history/me")
async def get_my_reviews(
    db: SessionDep,
    current_user: User = Depends(get_current_active_user)
):
    query = select(Review).where(Review.user_id == current_user.id)
    result = await db.execute(query)
    reviews = result.scalars().all()
    return {"reviews": reviews}


async def resolve_song_id(db: SessionDep, identifier: str) -> int:
    if identifier.isdigit():
        return int(identifier)
    song = await db.scalar(select(Song).where( or_(
            Song.spotify_id == identifier,
            Song.id == int(identifier) if identifier.isdigit() else False
        )))
    if not song:
        raise HTTPException(status_code=404, detail="ไม่พบข้อมูลเพลงนี้ในระบบ")
    return song.id

@router.get("/song/{identifier}")
async def get_review_by_song(
    identifier: str,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user)
):

    song_id = await resolve_song_id(db, identifier)
    
    query = select(Review).where(
        Review.song_id == song_id,
        Review.user_id == current_user.id
    )
    result = await db.execute(query)
    review = result.scalar_one_or_none()

    if not review:
        raise HTTPException(status_code=404, detail="ไม่พบรีวิวสำหรับเพลงนี้")

    return {"status": "success", "review": review}

@router.put("/{review_id}")
async def update_review(
    review_id: int,
    data: ReviewUpdate,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user)
):
    stmt = select(Review).where(Review.id == review_id)
    review = (await db.execute(stmt)).scalar_one_or_none()

    if not review:
        raise HTTPException(status_code=404, detail="ไม่พบ Review นี้")
    if review.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="ไม่มีสิทธิ์แก้ไข Review นี้")

    # อัปเดตเฉพาะฟิลด์ที่ส่งมา
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(review, field, value)

    await db.commit()
    await db.refresh(review)
    return {"status": "success", "review": review}

@router.delete("/{review_id}")
async def delete_review(
    review_id: int,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user)
):
    stmt = select(Review).where(Review.id == review_id)
    review = (await db.execute(stmt)).scalar_one_or_none()

    if not review:
        raise HTTPException(status_code=404, detail="ไม่พบ Review นี้")
    if review.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="ไม่มีสิทธิ์ลบ Review นี้")

    await db.delete(review)
    await db.commit()
    return {"message": "Delete Review Success"}