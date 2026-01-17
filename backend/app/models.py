from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, Text, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import datetime
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    favorite_genres = Column(String)
    bio = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    reviews = relationship("Review", back_populates="user")
    favorites = relationship("Favorite", back_populates="user")


class Song(Base):
    __tablename__ = "songs"

    id = Column(Integer, primary_key=True, index=True)
    spotify_id = Column(String, unique=True, index=True, nullable=True) # null if admin added
    song_name = Column(String, nullable=False)
    album_name = Column(String)
    artist_name = Column(String)
    song_cover_url = Column(String)
    category = Column(String)
    is_custom_added = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    reviews = relationship("Review", back_populates="song")
    favorited_by = relationship("Favorite", back_populates="song")


class Emotion(Base):
    __tablename__ = "emotions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False) # เศร้า, มันส์, อารมณ์ดี, ตลก
    icon_url = Column(String)

    reviews = relationship("Review", back_populates="emotion")


class MoodColor(Base):
    __tablename__ = "mood_colors"

    id = Column(Integer, primary_key=True, index=True)
    color_name = Column(String)
    color_hex = Column(String) # เช่น #FF5733

    reviews = relationship("Review", back_populates="mood_color")


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    song_id = Column(Integer, ForeignKey("songs.id"))
    emotion_id = Column(Integer, ForeignKey("emotions.id"))
    mood_color_id = Column(Integer, ForeignKey("mood_colors.id"))
    
    beat_score = Column(Float) # 0-5
    lyric_score = Column(Float) # 0-5
    mood_score = Column(Float) # 0-5
    
    comment = Column(Text)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships for easy data fetching
    user = relationship("User", back_populates="reviews")
    song = relationship("Song", back_populates="reviews")
    emotion = relationship("Emotion", back_populates="reviews")
    mood_color = relationship("MoodColor", back_populates="reviews")


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    song_id = Column(Integer, ForeignKey("songs.id"))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="favorites")
    song = relationship("Song", back_populates="favorited_by")