import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/song_detail.dart';
import 'package:http/http.dart' as http;

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
    linkurl: result['link_url'],
  );
}

Future<Map<String, dynamic>?> fetchMyReview(String songId) async {
  final response = await ApiClient.get('/review/me?song_identifier=$songId');
  if (response.statusCode != 200) return null;
  return jsonDecode(response.body) as Map<String, dynamic>;
}

// ─────────────────────────────────────────────
// Inventory Song Service
// ─────────────────────────────────────────────

Future<List<dynamic>> loadAllSongs() async {
  try {
    final response = await http.get(Uri.parse("$_baseUrl/songs/db/all-songs"));
    if (response.statusCode == 200) {
      return json.decode(response.body)['results'] ?? [];
    }
  } catch (e) {
    debugPrint("Error loading from DB: $e");
  }
  return [];
}

Future<Map<String, List<dynamic>>> searchSongs(String query) async {
  if (query.trim().isEmpty) {
    return {'db': [], 'spotify': []};
  }
  try {
    final response = await http.get(
      Uri.parse("$_baseUrl/songs/search?q=$query"),
    );
    if (response.statusCode == 200) {
      final List<dynamic> results = json.decode(response.body)['results'] ?? [];
      return {
        'db': results.where((s) => s['source'] == 'db').toList(),
        'spotify': results.where((s) => s['source'] == 'spotify').toList(),
      };
    }
  } catch (e) {
    debugPrint("Search error: $e");
  }
  return {'db': [], 'spotify': []};
}

// ─────────────────────────────────────────────
// Admin Song Service
// ─────────────────────────────────────────────

const String _baseUrl = "http://10.0.2.2:8000";

Future<Map<String, dynamic>> fetchMetadataSuggestions(String query) async {
  if (query.trim().length < 2) {
    return {'songs': [], 'artists': [], 'albums': []};
  }
  try {
    final response = await http.get(
      Uri.parse("$_baseUrl/admin/search-metadata?query=$query"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'songs': List<Map<String, dynamic>>.from(data['songs'] ?? []),
        'artists': List<String>.from(data['artists'] ?? []),
        'albums': List<String>.from(data['albums'] ?? []),
      };
    }
  } catch (e) {
    debugPrint("Suggestions error: $e");
  }
  return {'songs': [], 'artists': [], 'albums': []};
}

Future<SongServiceResult> createSong({
  required String songName,
  required String category,
  required String artistName,
  required String albumName,
  required String linkUrl,
  required File imageFile,
}) async {
  try {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$_baseUrl/admin/songs/create"),
    );
    request.fields['song_name'] = songName;
    request.fields['category'] = category;
    request.fields['artist_name'] = artistName;
    request.fields['album_name'] = albumName;
    request.fields['link_url'] = linkUrl;
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SongServiceResult.success();
    }
    final errorMsg = json.decode(response.body)['detail'] ?? "Upload failed";
    return SongServiceResult.failure(errorMsg);
  } catch (e) {
    return SongServiceResult.failure("Connection Error: $e");
  }
}

Future<SongServiceResult> updateSong({
  required int songId,
  required String songName,
  required String category,
  required String artistName,
  required String albumName,
  required String linkUrl,
  File? newImageFile,
}) async {
  try {
    var request = http.MultipartRequest(
      "PATCH",
      Uri.parse("$_baseUrl/songs/$songId"),
    );
    request.fields['song_name'] = songName;
    request.fields['category'] = category;
    request.fields['artist_name'] = artistName;
    request.fields['album_name'] = albumName;
    request.fields['link_url'] = linkUrl;

    if (newImageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', newImageFile.path),
      );
    }

    final streamedRes = await request.send();
    if (streamedRes.statusCode == 200) return SongServiceResult.success();

    final res = await http.Response.fromStream(streamedRes);
    final errorMsg = json.decode(res.body)['detail'] ?? "Update failed";
    return SongServiceResult.failure(errorMsg);
  } catch (e) {
    return SongServiceResult.failure("Update Error: $e");
  }
}

Future<SongServiceResult> deleteSong(int songId) async {
  try {
    final res = await http.delete(Uri.parse("$_baseUrl/songs/$songId"));
    if (res.statusCode == 200) return SongServiceResult.success();
    return SongServiceResult.failure("Delete failed");
  } catch (e) {
    return SongServiceResult.failure("Delete Error: $e");
  }
}

// ─────────────────────────────────────────────
// Result Model
// ─────────────────────────────────────────────

class SongServiceResult {
  final bool isSuccess;
  final String? errorMessage;

  SongServiceResult._({required this.isSuccess, this.errorMessage});

  factory SongServiceResult.success() => SongServiceResult._(isSuccess: true);

  factory SongServiceResult.failure(String message) =>
      SongServiceResult._(isSuccess: false, errorMessage: message);
}
