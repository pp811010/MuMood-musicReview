import 'dart:convert';
import 'package:frontend/core/api_client.dart';

Future<List<Map<String, dynamic>>> fetchMyReviews() async {
  final response = await ApiClient.get('/review/history/me');

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> reviews = body['reviews'] ?? [];
    return reviews.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load review history');
  }
}

Future<List<Map<String, dynamic>>> fetchMyCommentHistory() async {
  final response = await ApiClient.get('/comment/history/me');

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> items = body['song_comments'] ?? [];
    return items.cast<Map<String, dynamic>>();
  } else {
    return [];
  }
}
