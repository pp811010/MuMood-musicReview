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
    token = get_token()
    print(f"Token ที่ได้รับ: {token}") #
    headers = {"Authorization": f"Bearer {token}"}
    print(headers)
    
    chart_ids = [
        "36rTan768eGvGTNHXBC5Xd", # Top 50 Thailand
        "37i9dQZF1DX18jTM2l2fJY"  # Top 50 Global
    ]
    
    total_imported = 0
    

    # url = f"https://api.spotify.com/v1/playlists/37i9dQZEVXbMn2vY6UIp4o/tracks"
    # response = requests.get(url, headers=headers)
    
    # # if response.status_code != 200:
    # #     print(f"Error {response.status_code}: {response.text}") # พิมพ์ดู Error ใน Terminal
    # #     continue
        
    # data = response.json()
    # items = data.get('items', [])
    # results = []
    
    # for item in items:
    #     track = item.get('track')
    #     if not track or not track.get('id'): continue
    #     results.append(
    #         {
    #             "id": track['id'], 
    #             "song_name": track['name'],
    #             "artist_name": track['artists'][0]['name'] if track['artists'] else "Unknown Artist",
    #             "album_name": track['album']['name'] if track.get('album') else None,
    #             "song_cover_url": track['album']['images'][0]['url'] if track['album'].get('images') else None,
    #             "preview_url": track.get('preview_url'),
    #             "is_custom_added": False
    #         }
    #     )

    url = "https://api.spotify.com/v1/playlists/37i9dQZEVXbMDoHDw32tY1/tracks"
    response = requests.get(url, headers=headers)
    print(response.status_code, response.json())
    # return {"status": "success", "result": data}


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
    
    if 'tracks' not in data:
        return {"results": [], "error": "No tracks found"}

    results = []
    for item in data.get('tracks', {}).get('items', []):
        images = item.get('album', {}).get('images', [])
        image_url = images[0].get('url') if images else None
        
        artists = item.get('artists', [])
        artist_name = artists[0].get('name') if artists else "Unknown Artist"

        results.append({
            "id": item.get('id'),
            "name": item.get('name'),
            "artist": artist_name,
            "image": image_url,
            "preview_url": item.get('preview_url')
        })
        
    return {"results": results}