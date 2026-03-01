class Song {
  final int? id;              // ID หลักใน PostgreSQL (Primary Key)
  final String? spotifyId;    // ID จาก Spotify (null ถ้าเป็นเพลงที่ Admin เพิ่มเอง)
  final String songName;      // ชื่อเพลง
  final String? artistName;   // ชื่อศิลปิน
  final String? albumName;    // ชื่ออัลบั้ม
  final String? songCoverUrl; // ลิงก์รูปปกเพลง
  final String? previewUrl;   // ลิงก์เล่นเพลงตัวอย่าง 30 วินาที
  final bool isCustomAdded;   // ระบุว่าเป็นเพลงที่ระบบ/Admin เพิ่มเองหรือไม่

  Song({
    this.id,
    this.spotifyId,
    required this.songName,
    this.artistName,
    this.albumName,
    this.songCoverUrl,
    this.previewUrl,
    this.isCustomAdded = false,
  });

  // ฟังก์ชัน Factory สำหรับแปลง JSON เป็น Object
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      spotifyId: json['spotify_id'],
      // ใช้ ?? เพื่อรองรับ Key ที่ต่างกันระหว่าง Spotify API (name) และ DB (song_name)
      songName: json['song_name'] ?? json['name'] ?? 'Unknown Track', 
      artistName: json['artist_name'] ?? json['artist'] ?? 'Unknown Artist',
      albumName: json['album_name'] ?? json['album'],
      songCoverUrl: json['song_cover_url'] ?? json['image'] ?? '',
      previewUrl: json['preview_url'], //
      isCustomAdded: json['is_custom_added'] ?? false,
    );
  }

  // ฟังก์ชันสำหรับแปลง Object กลับเป็น JSON (สำหรับส่งไป Save ที่ FastAPI)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotify_id': spotifyId,
      'song_name': songName,
      'artist_name': artistName,
      'album_name': albumName,
      'song_cover_url': songCoverUrl,
      'preview_url': previewUrl, //
      'is_custom_added': isCustomAdded,
    };
  }
}