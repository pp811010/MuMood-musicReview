import 'dart:convert';
import 'package:frontend/core/api_client.dart';

/// Model สำหรับ comment แต่ละรายการ
class CommentItem {
  final int id;
  final int userId;
  final String username;
  final String content;
  final String createdAt;
  final String updatedAt;

  CommentItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  /// สร้าง copy ที่แก้ไข content
  CommentItem copyWith({String? content}) {
    return CommentItem(
      id: id,
      userId: userId,
      username: username,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// โพสต์ comment ใหม่ — โพสต์ได้ไม่จำกัด
Future<CommentItem?> postComment({
  required String songIdReference,
  required String source,
  required String content,
}) async {
  final response = await ApiClient.post('/comment/', {
    "song_id_reference": songIdReference,
    "source": source,
    "content": content,
  });
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final commentJson = data['comment'] as Map<String, dynamic>;
    // postComment ไม่มี username ใน response → ใส่ placeholder ก่อน
    // ค่าจริงจะถูก refresh จาก fetchCommentsBySong
    return CommentItem(
      id: commentJson['id'],
      userId: commentJson['user_id'],
      username: '',
      content: commentJson['content'],
      createdAt: commentJson['created_at'] ?? '',
      updatedAt: commentJson['updated_at'] ?? '',
    );
  }
  return null;
}

/// แก้ไข comment ของตัวเอง
Future<bool> updateComment({
  required int commentId,
  required String content,
}) async {
  final response = await ApiClient.put('/comment/$commentId', {
    "content": content,
  });
  return response.statusCode == 200;
}

/// ลบ comment ของตัวเอง
Future<bool> deleteComment(int commentId) async {
  final response = await ApiClient.delete('/comment/$commentId');
  return response.statusCode == 200;
}

/// ดึง comments ทั้งหมดของเพลง
Future<List<CommentItem>> fetchCommentsBySong(int songId) async {
  final response = await ApiClient.get('/comment/song/$songId');
  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body);
  final list = data['comments'] as List? ?? [];
  return list
      .map((e) => CommentItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// ดึง comments ของตัวเองในเพลงนั้น
Future<List<CommentItem>> fetchMyCommentsBySong(int songId) async {
  final response = await ApiClient.get('/comment/me/song/$songId');
  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body);
  final list = data['comments'] as List? ?? [];
  return list
      .map((e) => CommentItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// parse error detail จาก response body
String? parseCommentError(String responseBody) {
  try {
    final data = jsonDecode(responseBody);
    return data['detail'] as String?;
  } catch (_) {
    return null;
  }
}
