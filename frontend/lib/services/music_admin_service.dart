import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MusicAdminService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ค้นหา Metadata (Autocomplete)
  static Future<Map<String, dynamic>> searchMetadata(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/search-metadata?query=$query'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch metadata');
  }

  // แก้ไขเพลง (PATCH)
  static Future<http.StreamedResponse> updateSong({
    required String id,
    String? name,
    String? artist,
    String? album,
    String? category,
    String? link,
    File? imageFile,
  }) async {
    // 1. สร้าง Request แบบ PATCH ไปที่ /songs/{id}
    var request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/songs/$id'),
    );

    // 2. เพิ่มข้อมูล Text Fields (ใส่เฉพาะค่าที่ไม่เป็น null)
    if (name != null) request.fields['song_name'] = name;
    if (artist != null) request.fields['artist_name'] = artist;
    if (album != null) request.fields['album_name'] = album;
    if (category != null) request.fields['category'] = category;
    if (link != null) request.fields['link_url'] = link;

    // 3. เพิ่มไฟล์รูปภาพ (ถ้ามีการเลือกใหม่)
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // ชื่อ field ต้องตรงกับที่ Backend (FastAPI) รับ
          imageFile.path,
        ),
      );
    }

    // 4. ส่ง Request และคืนค่า StreamedResponse
    return await request.send();
  }

  // ลบเพลง (DELETE)
  static Future<bool> deleteSong(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/songs/$id'));
    return res.statusCode == 200;
  }
}
