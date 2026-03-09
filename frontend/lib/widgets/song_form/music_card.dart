import 'package:flutter/material.dart';

class MusicCard extends StatelessWidget {
  final Map<String, dynamic> song;
  final String baseUrl;
  final VoidCallback onDelete;

  const MusicCard({
    super.key,
    required this.song,
    required this.baseUrl,
    required this.onDelete,
  });

  String _resolveImageUrl() {
    final raw = song['image'] ?? "";
    if (raw.startsWith("http")) return raw;
    if (raw.startsWith("/static")) return "$baseUrl$raw";
    if (raw.isNotEmpty) return "$baseUrl/$raw";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl();
    final isCustom = song['is_custom'] == true;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.network(
                    imageUrl.isNotEmpty
                        ? imageUrl
                        : "https://via.placeholder.com/150",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.music_note,
                        size: 50,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song['name'] ?? "Unknown",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song['artist'] ?? "Unknown Artist",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ปุ่ม Delete เฉพาะเพลง Custom
        if (isCustom)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
