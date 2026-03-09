from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from pydantic import BaseModel

from app.database import SessionDep
from app.models import Comment, Song, User
from app.core.security import get_current_active_user
from app.services.spotify import fetch_spotify_track


router = APIRouter(prefix="/comment", tags=["Comment"])


# ─── Schemas (inline) ───────────────────────────────────────────────────────


class CommentCreate(BaseModel):
    song_id_reference: str  # spotify_id หรือ db song id
    source: str  # "spotify" หรือ "db"
    content: str


class CommentUpdate(BaseModel):
    content: str


# ─── Endpoints ──────────────────────────────────────────────────────────────


@router.post("/")
async def create_comment(
    body: CommentCreate,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user),
):
    """
    คอมเมนต์ได้ไม่จำกัดจำนวน — สร้าง comment ใหม่ทุกครั้งที่เรียก
    """
    # resolve song id
    if body.source == "spotify":
        stmt = select(Song).where(Song.spotify_id == body.song_id_reference)
        song = (await db.execute(stmt)).scalar_one_or_none()

        if not song:
            # ดึงข้อมูลจาก Spotify แล้วบันทึก song ลง DB ก่อน
            spotify_data = await fetch_spotify_track(body.song_id_reference)
            song = Song(
                spotify_id=body.song_id_reference,
                song_name=spotify_data["name"],
                artist_name=spotify_data["artist"],
                album_name=spotify_data["album"],
                song_cover_url=spotify_data["cover"],
                link_url=spotify_data["link_url"],
                is_custom_added=False,
            )
            db.add(song)
            await db.flush()
        song_id = song.id
    else:
        song_id = int(body.song_id_reference)

    if not body.content.strip():
        raise HTTPException(status_code=400, detail="Comment ต้องไม่ว่างเปล่า")

    new_comment = Comment(
        user_id=current_user.id,
        song_id=song_id,
        content=body.content.strip(),
    )
    db.add(new_comment)
    await db.commit()
    await db.refresh(new_comment)

    return {
        "status": "success",
        "comment": {
            "id": new_comment.id,
            "content": new_comment.content,
            "user_id": new_comment.user_id,
            "song_id": new_comment.song_id,
            "created_at": new_comment.created_at,
            "updated_at": new_comment.updated_at,
        },
    }


@router.put("/{comment_id}")
async def update_comment(
    comment_id: int,
    body: CommentUpdate,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user),
):
    """
    แก้ไข comment ของตัวเองได้
    """
    stmt = select(Comment).where(Comment.id == comment_id)
    comment = (await db.execute(stmt)).scalar_one_or_none()

    if not comment:
        raise HTTPException(status_code=404, detail="ไม่พบ Comment นี้")
    if comment.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="ไม่มีสิทธิ์แก้ไข Comment นี้")

    if not body.content.strip():
        raise HTTPException(status_code=400, detail="Comment ต้องไม่ว่างเปล่า")

    comment.content = body.content.strip()
    await db.commit()
    await db.refresh(comment)

    return {
        "status": "success",
        "comment": {
            "id": comment.id,
            "content": comment.content,
            "user_id": comment.user_id,
            "song_id": comment.song_id,
            "created_at": comment.created_at,
            "updated_at": comment.updated_at,
        },
    }


@router.delete("/{comment_id}")
async def delete_comment(
    comment_id: int,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user),
):
    """
    ลบ comment ของตัวเองได้
    """
    stmt = select(Comment).where(Comment.id == comment_id)
    comment = (await db.execute(stmt)).scalar_one_or_none()

    if not comment:
        raise HTTPException(status_code=404, detail="ไม่พบ Comment นี้")
    if comment.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="ไม่มีสิทธิ์ลบ Comment นี้")

    await db.delete(comment)
    await db.commit()

    return {"status": "success", "message": "Comment deleted"}


@router.get("/song/{song_id}")
async def get_comments_by_song(
    song_id: int,
    db: SessionDep,
):
    """
    ดึง comments ทั้งหมดของเพลง (เรียงจากใหม่ → เก่า)
    """
    print(song_id)
    stmt = (
        select(Comment)
        .where(Comment.song_id == song_id)
        .options(selectinload(Comment.user))
        .order_by(Comment.created_at.desc())
    )
    result = await db.execute(stmt)
    comments = result.scalars().all()

    return {
        "status": "success",
        "comments": [
            {
                "id": c.id,
                "user_id": c.user_id,
                "username": c.user.username,
                "content": c.content,
                "created_at": c.created_at,
                "updated_at": c.updated_at,
            }
            for c in comments
        ],
    }


@router.get("/me/song/{song_id}")
async def get_my_comments_by_song(
    song_id: int, db: SessionDep, current_user: User = Depends(get_current_active_user)
):
    """
    ดึง comments ของตัวเองในเพลงนั้น ๆ
    """
    stmt = (
        select(Comment)
        .where(Comment.song_id == song_id, Comment.user_id == current_user.id)
        .order_by(Comment.created_at.desc())
    )
    result = await db.execute(stmt)
    comments = result.scalars().all()

    return {
        "status": "success",
        "comments": [
            {
                "id": c.id,
                "content": c.content,
                "created_at": c.created_at,
                "updated_at": c.updated_at,
            }
            for c in comments
        ],
    }
