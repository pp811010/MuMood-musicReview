from app.routes import auth
from app.routes import admin
from app.routes import favorite, song
from app.routes import spotify
from app.routes import mood_color
from app.routes import review
from app.routes import emotion
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from fastapi import FastAPI

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(song.router)
app.include_router(spotify.router)
app.include_router(review.router)
app.include_router(favorite.router)
app.include_router(emotion.router)
app.include_router(mood_color.router)

# mount image path file
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
def root():
    return {"message": "Welcome to MuMood API"}