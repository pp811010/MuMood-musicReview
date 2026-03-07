import 'dart:convert';
import 'package:frontend/core/api_client.dart';

Future<({bool isFavorited, String message})?> toggleFavorite({
  required String songIdReference,
  required String source,
}) async {
  final response = await ApiClient.post('/favorites/toggle', {
    "song_id_reference": songIdReference,
    "source": source,
  });

  if (response.statusCode != 200) return null;

  final data = jsonDecode(response.body);
  return (
    isFavorited: data['is_favorited'] as bool,
    message: data['message'] as String,
  );
}
