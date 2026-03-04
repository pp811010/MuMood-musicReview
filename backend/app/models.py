from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, Text, DateTime, Index
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from sqlalchemy import DateTime
from app.database import Base

# ใช้ฟังก์ชันช่วยเพื่อให้ได้เวลา UTC แบบมาตรฐาน
def get_now_utc():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    favorite_genres = Column(String)
    bio = Column(String)
    created_at = Column(DateTime, default=get_now_utc)
    is_active = Column(Boolean, default=True)

    reviews = relationship("Review", back_populates="user", cascade="all, delete-orphan")
    favorites = relationship("Favorite", back_populates="user", cascade="all, delete-orphan")


class Song(Base):
    __tablename__ = "songs"

    id = Column(Integer, primary_key=True, index=True)
    spotify_id = Column(String, unique=True, index=True, nullable=True)
    song_name = Column(String, index=True, nullable=False)
    artist_name = Column(String, index=True, nullable=True)
    album_name = Column(String, nullable=True)
    song_cover_url = Column(String, nullable=True)
    preview_url = Column(String, nullable=True)
    category = Column(String, nullable=True)
    is_custom_added = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=get_now_utc)
    updated_at = Column(DateTime(timezone=True), default=get_now_utc, onupdate=get_now_utc)
    reviews = relationship("Review", back_populates="song", cascade="all, delete-orphan")
    favorited_by = relationship("Favorite", back_populates="song", cascade="all, delete-orphan")


class Emotion(Base):
    __tablename__ = "emotions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    icon_url = Column(String)
    reviews = relationship("Review", back_populates="emotion")

class MoodColor(Base):
    __tablename__ = "mood_colors"
    id = Column(Integer, primary_key=True, index=True)
    color_name = Column(String)
    color_hex = Column(String)
    reviews = relationship("Review", back_populates="mood_color")


class Review(Base):
    __tablename__ = "reviews"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    song_id = Column(Integer, ForeignKey("songs.id"), nullable=False)
    emotion_id = Column(Integer, ForeignKey("emotions.id"), nullable=False)
    mood_color_id = Column(Integer, ForeignKey("mood_colors.id"), nullable=False)
    
    beat_score = Column(Float)
    lyric_score = Column(Float)
    mood_score = Column(Float)
    comment = Column(Text)
    created_at = Column(DateTime(timezone=True), default=get_now_utc)
    updated_at = Column(DateTime(timezone=True), default=get_now_utc, onupdate=get_now_utc)

    user = relationship("User", back_populates="reviews")
    song = relationship("Song", back_populates="reviews")
    emotion = relationship("Emotion", back_populates="reviews")
    mood_color = relationship("MoodColor", back_populates="reviews")


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    song_id = Column(Integer, ForeignKey("songs.id"), nullable=False)
    created_at =  Column(DateTime(timezone=True), default=get_now_utc)

    user = relationship("User", back_populates="favorites")
    song = relationship("Song", back_populates="favorited_by")