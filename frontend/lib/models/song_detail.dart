class SongDetail {
  final String id;
  final String songName;
  final String artistName;
  final String? image; 
  final bool favorite;
  final Map<String, double> avgScores;
  final Map<String, int> emotionCounts;
  final String? dominantColor;
  final Map<String, int> colorCounts;
  final List<dynamic> comment;
  final String source;
  final String? previewUrl; 
  final String? spotifyUrl;


  SongDetail({
    required this.id,
    this.image,
    required this.songName,
    required this.artistName,
    required this.favorite,
    required this.dominantColor,
    required this.avgScores,
    required this.emotionCounts,
    required this.colorCounts,
    required this.comment,
    required this.source,
    required this.previewUrl,
    required this.spotifyUrl
  });
}