from typing import Union
from app.routes import auth
from app.routes import admin
from app.routes import spotify
import requests
from fastapi.middleware.cors import CORSMiddleware

from fastapi import FastAPI

app = FastAPI()
# สำคัญมาก: ต้องเปิด CORS เพื่อให้ Flutter เรียกได้
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(spotify.router)

@app.get("/")
def root():
    return {"message": "Welcome to MuMood API"}