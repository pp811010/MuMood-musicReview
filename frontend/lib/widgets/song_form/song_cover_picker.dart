import 'dart:io';
import 'package:flutter/material.dart';

class SongCoverPicker extends StatelessWidget {
  final File? localFile;
  final String? networkImageUrl;
  final VoidCallback onTap;

  const SongCoverPicker({
    super.key,
    required this.onTap,
    this.localFile,
    this.networkImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // ถ้ามีไฟล์ local (เพิ่งเลือกจาก Gallery) → แสดงก่อนเสมอ
    if (localFile != null) {
      return Image.file(localFile!, fit: BoxFit.cover);
    }

    // ถ้ามี URL จาก Network (หน้า Edit)
    if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
      return Image.network(
        networkImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }

    // ไม่มีรูปเลย → แสดง Placeholder (หน้า Create)
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 50, color: Colors.white54),
        Text("Add Cover", style: TextStyle(color: Colors.white54)),
      ],
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: const Color(0xFF2C2C2C),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.white24, size: 40),
          SizedBox(height: 8),
          Text(
            "No Image Found",
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
