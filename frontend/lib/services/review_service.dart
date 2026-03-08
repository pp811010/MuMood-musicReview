import 'dart:convert';

import 'package:frontend/core/api_client.dart';

Future<bool> submitRating({
  required String songIdReference,
  required String source,
  required int emotionId,
  required int moodColorId,
  required double beatScore,
  required double lyricScore,
  required double moodScore,
}) async {
  final response = await ApiClient.post('/review/', {
    "song_id_reference": songIdReference,
    "emotion_id": emotionId,
    "mood_color_id": moodColorId,
    "beat_score": beatScore,
    "lyric_score": lyricScore,
    "mood_score": moodScore,
    "source": source,
  });
  dataRefreshNotifier.value++;
  return response.statusCode == 200;
}

Future<bool> updateRating({
  required int reviewId,
  required double beatScore,
  required double lyricScore,
  required double moodScore,
  required int emotionId,
  required int moodColorId,
}) async {
  final response = await ApiClient.put('/review/$reviewId', {
    "beat_score": beatScore,
    "lyric_score": lyricScore,
    "mood_score": moodScore,
    "emotion_id": emotionId,
    "mood_color_id": moodColorId,
  });
  dataRefreshNotifier.value++;
  return response.statusCode == 200;
}

Future<bool> editComment({
  required int reviewId,
  required String comment,
}) async {
  final response = await ApiClient.put('/review/$reviewId', {
    "comment": comment,
  });
  dataRefreshNotifier.value++;
  return response.statusCode == 200;
}

Future<bool> deleteComment(int reviewId) async {
  final response = await ApiClient.delete('/review/delete/comment/$reviewId');
  return response.statusCode == 200;
}

String? parseError(String responseBody) {
  try {
    final data = jsonDecode(responseBody);
    return data['detail'] as String?;
  } catch (_) {
    return null;
  }
}
