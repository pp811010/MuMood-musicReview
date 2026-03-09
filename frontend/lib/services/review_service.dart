import 'dart:convert';
import 'package:frontend/core/api_client.dart';

/// Submit review ใหม่ (scores + emotion + mood) — ทำได้ครั้งเดียวต่อเพลง
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

/// แก้ไข review ที่มีอยู่แล้ว (scores + emotion + mood) — ลบไม่ได้
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

/// parse error detail จาก response body
String? parseError(String responseBody) {
  try {
    final data = jsonDecode(responseBody);
    return data['detail'] as String?;
  } catch (_) {
    return null;
  }
}

// ❌ deleteReview — ลบออกแล้ว review ลบไม่ได้
// ❌ editComment / deleteComment — ย้ายไปที่ comment_service.dart แล้ว
