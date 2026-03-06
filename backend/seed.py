import asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_async_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, class_=AsyncSession, autocommit=False, autoflush=False)

from app.models import MoodColor, Emotion

async def seed_mood_colors():
    async with SessionLocal() as db:
        mood_colors = [
            MoodColor(color_name="Black", color_hex="#121812"),
            MoodColor(color_name="Brown", color_hex="#412E12"),
            MoodColor(color_name="Teal", color_hex="#045742"),
            MoodColor(color_name="Purple", color_hex="#800080"),
            MoodColor(color_name="Blue", color_hex="#0099FF"),
            MoodColor(color_name="Red", color_hex="#D40E00"),
            MoodColor(color_name="Green", color_hex="#008000"),
            MoodColor(color_name="Lime", color_hex="#CDDC39"),
        ]
        db.add_all(mood_colors)
        await db.commit()
        print("Seed mood_colors สำเร็จ")

async def seed_emotions():
    async with SessionLocal() as db:
        emotions = [
            Emotion(name='Happy'),
            Emotion(name="Sad"),
            Emotion(name="In Love"),
            Emotion(name="Lonely"),
            Emotion(name="Missing"),
            Emotion(name="Heartbroken"),
        ]
        db.add_all(emotions)
        await db.commit()
        print("Seed emotions สำเร็จ")

async def seed_all():
    await seed_mood_colors()
    await seed_emotions()

if __name__ == "__main__":
    asyncio.run(seed_all())