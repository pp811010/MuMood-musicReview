from fastapi import APIRouter, Query, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db  # ตรวจสอบ path ของ get_db ของคุณ
from app.models import Song # ตรวจสอบ path ของ Model Song ของคุณ
import requests
import base64

router = APIRouter(prefix="/spotify", tags=["Spotify"])

CLIENT_ID = 'a9d74c8adc794984bd92c755bf5f6c7c'
CLIENT_SECRET = '9596a8a1632a453cb918b00d1972559c'

def get_token():
    auth_string = f"{CLIENT_ID}:{CLIENT_SECRET}"
    auth_base64 = base64.b64encode(auth_string.encode("utf-8")).decode("utf-8")
    url = "https://accounts.spotify.com/api/token"
    headers = {
        "Authorization": f"Basic {auth_base64}",
        "Content-Type": "application/x-www-form-urlencoded"
    }
    data = {"grant_type": "client_credentials"}
    response = requests.post(url, headers=headers, data=data)
    return response.json().get("access_token")


# --- เพิ่ม Route สำหรับดึงเพลงยอดนิยมลง DB ---
@router.post("/import-top-charts")
async def import_top_charts(db: Session = Depends(get_db)):
    """ดึงเพลงจาก Top 50 Thailand และ Global มาลง Database"""
    token = get_token()
    headers = {"Authorization": f"Bearer {token}"}
    
    # List ของ Playlist ID (Top 50 TH และ Global)
    chart_ids = [
        "37i9dQZEVXbMn2vY6UIp4o", # Top 50 Thailand
        "37i9dQZEVXbMDoHDw32tY1"  # Top 50 Global
    ]
    
    total_imported = 0
    
    for playlist_id in chart_ids:
        url = f"https://api.spotify.com/v1/playlists/{playlist_id}/tracks?limit=50"
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            continue
            
        data = response.json()
        items = data.get('items', [])
        
        for item in items:
            track = item.get('track')
            if not track: continue
            
            # ตรวจสอบว่ามีเพลงนี้ใน DB หรือยัง (ป้องกันข้อมูลซ้ำ)
            exists = db.query(Song).filter(Song.spotify_id == track['id']).first()
            
            if not exists:
                new_song = Song(
                    spotify_id=track['id'],
                    song_name=track['name'],
                    artist_name=track['artists'][0]['name'] if track['artists'] else "Unknown Artist",
                    album_name=track['album']['name'] if track.get('album') else None,
                    song_cover_url=track['album']['images'][0]['url'] if track['album'].get('images') else None,
                    preview_url=track.get('preview_url'), # ลิงก์เล่นเพลง 30 วิ
                    is_custom_added=False
                )
                db.add(new_song)
                total_imported += 1
                
    try:
        db.commit() # บันทึกข้อมูลทั้งหมดลง Postgres
        return {"status": "success", "message": f"Imported {total_imported} new songs from top charts."}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/all-songs")
async def get_all_songs(db: Session = Depends(get_db)):
    """ดึงเพลงทั้งหมดที่เก็บไว้ใน Database ของเราเองออกมาโชว์"""
    db_songs = db.query(Song).order_by(Song.created_at.desc()).all()
    
    results = []
    for song in db_songs:
        results.append({
            "id": song.id,
            "spotify_id": song.spotify_id,
            "name": song.song_name, # Map ให้ตรงกับที่ Flutter รอรับ
            "artist": song.artist_name,
            "image": song.song_cover_url,
            "preview_url": song.preview_url, #
            "is_custom": song.is_custom_added
        })
    return {"results": results}


@router.get("/search")
async def search_music(q: str = Query(...)):
    token = get_token()
    headers = {"Authorization": f"Bearer {token}"}
    search_url = f"https://api.spotify.com/v1/search?q={q}&type=track&limit=10"
    
    response = requests.get(search_url, headers=headers)
    data = response.json()
    
    # ตรวจสอบว่ามีข้อมูล tracks ส่งกลับมาจริงไหม
    if 'tracks' not in data:
        return {"results": [], "error": "No tracks found"}

    tracks = []
    for item in data.get('tracks', {}).get('items', []):
        # ใช้ .get() เพื่อป้องกัน KeyError หากไม่มี Key นั้นๆ
        tracks.append({
            "name": item.get('name'),
            "artist": item.get('artists', [{}])[0].get('name') if item.get('artists') else "Unknown Artist",
            "preview_url": item.get('preview_url'),  # ถ้าไม่มีจะเป็น None แทนที่จะ Error
            "image": item.get('album', {}).get('images', [{}])[0].get('url') if item.get('album', {}).get('images') else None
        })
    return {"results": tracks}