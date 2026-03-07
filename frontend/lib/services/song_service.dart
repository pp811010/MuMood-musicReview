import 'dart:convert';

import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/song_detail.dart';

Future<SongDetail?> fetchDetailSong(String songId) async {
  final response = await ApiClient.get('/songs/detail/$songId');
  if (response.statusCode != 200) return null;
  final result = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
  final avg = result['avg_scores'] as Map<String, dynamic>? ?? {};
  final emotions = result['emotion_counts'] as Map<String, dynamic>? ?? {};
  final colors = result['color_counts'] as Map<String, dynamic>? ?? {};
  final comments = result['comment'] as List? ?? [];

   return SongDetail(
      id: result['id'],
      image: result['song_cover_url'],
      songName: result['song_name'],
      dominantColor: result['dominant_color'],
      artistName: result['artist_name'],
      favorite: result['favorite'] ?? false,
      avgScores: avg.map((k, v) => MapEntry(k, (v as num).toDouble())),
      emotionCounts: emotions.map((k, v) => MapEntry(k, v as int)),
      colorCounts: colors.map((k, v) => MapEntry(k, v as int)),
      comment: comments,
      source: result['source'] ?? '',
      previewUrl: result['preview_url'],
      spotifyUrl: result['spotify_url'],
    );
}

Future<Map<String, dynamic>?> fetchMyReview(String songId) async {
    final response = await ApiClient.get('/review/me?song_identifier=$songId');
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
}
