import httpx


async def fetch_deezer_preview(song_name: str, artist_name: str) -> str | None:
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://api.deezer.com/search",
            params={"q": f"{artist_name} {song_name}", "limit": 1}
        )
        if response.status_code != 200:
            return None
        tracks = response.json().get("data", [])
        return tracks[0].get("preview") if tracks else None