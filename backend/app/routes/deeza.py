import httpx


async def fetch_deezer_preview(song_name: str, artist_name: str) -> str | None:
    async with httpx.AsyncClient() as client:
        query = f'artist:"{artist_name}" track:"{song_name}"'
        response = await client.get(
            "https://api.deezer.com/search",
            params={"q": query, "limit": 1}
        )
        
        if response.status_code != 200:
            return None
            
        data = response.json().get("data", [])
        if not data:
            return None

        result = data[0]
        deezer_artist = result.get("artist", {}).get("name", "").lower().strip()
        input_artist = artist_name.lower().strip()

        if deezer_artist != input_artist:
            print(f"Mismatch found: Expected {input_artist} but got {deezer_artist}")
            return None

        return result.get("preview")