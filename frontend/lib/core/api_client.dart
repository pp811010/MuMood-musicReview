
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart' show navigatorKey;
import 'package:frontend/screens/Login.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<http.Response> get(String path) async {
    return await _request(() async {
      final token = await _getAccessToken();
      return await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token),
      );
    });
  }

  // POST
  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return await _request(() async {
      final token = await _getAccessToken();
      return await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  // PUT
  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    return await _request(() async {
      final token = await _getAccessToken();
      return await http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  // DELETE
  static Future<http.Response> delete(String path) async {
    return await _request(() async {
      final token = await _getAccessToken();
      return await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token),
      );
    });
  }

  // ============ Private ============

  static Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };


  static Future<http.Response> _request(
    Future<http.Response> Function() call,
  ) async {
    var response = await call();

    if (response.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        response = await call(); 
      } else {
        await _forceLogout();
      }
    }

    return response;
  }

  // ขอ access token ใหม่จาก refresh token
  static Future<bool> _tryRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/users/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['access_token']);
        print('Token refreshed!');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }


  static Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }
}