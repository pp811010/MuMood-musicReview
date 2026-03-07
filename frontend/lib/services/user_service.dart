import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ─── Token Helpers ───

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ───

  /// POST /users/login/
  static Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login/'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'] as String;
      await saveToken(token);
      return token;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // ─── User Profile ───

  /// GET /users/profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  // ─── Favorites ───

  /// GET /favorites/history/me

  static Future<List<Map<String, dynamic>>> getMyFavorites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/history/me'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load favorites: ${response.body}');
    }
  }

  /// POST /favorites/toggle
  static Future<Map<String, dynamic>> toggleFavorite({
    required String songIdReference,
    required String source, // "spotify" or "db"
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites/toggle'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'song_id_reference': songIdReference,
        'source': source,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to toggle favorite: ${response.body}');
    }
  }

  // ─── Review History ───

  /// GET /review/history/me
  static Future<List<Map<String, dynamic>>> getMyReviews() async {
    final response = await http.get(
      Uri.parse('$baseUrl/review/history/me'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> reviews = body['reviews'] ?? [];
      return reviews.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  // ─── Song Detail ───

  /// GET /songs/resolve/{identifier}
  static Future<Map<String, dynamic>> getSongDetail(String identifier) async {
    final response = await http.get(
      Uri.parse('$baseUrl/songs/resolve/$identifier'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Song not found');
    }
  }
}
