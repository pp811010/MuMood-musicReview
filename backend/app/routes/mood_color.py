from fastapi import APIRouter
from sqlalchemy import select
from app.database import get_db, SessionDep
from app.models import *


router = APIRouter(prefix='/mood-color', tags=["Mood Color"])

@router.get('/')
async def get_mood_color(db: SessionDep):
    stmt = select(MoodColor)
    result = await db.execute(stmt)
    all_emotion = result.scalars().all()
    return all_emotion