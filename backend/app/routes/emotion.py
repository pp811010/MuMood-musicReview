from fastapi import APIRouter
from sqlalchemy import select
from app.database import get_db, SessionDep
from app.models import *


router = APIRouter(prefix='/emotion', tags=["Emotion"])

@router.get('/')
async def get_emotion(db: SessionDep):
    stmt = select(Emotion)
    result = await db.execute(stmt)
    all_emotion = result.scalars().all()
    return all_emotion