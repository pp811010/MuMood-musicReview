import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicCoverWidget extends StatelessWidget {
  final String songName;
  final String artistName;
  final String? imageUrl;
  final String? previewUrl;
  final bool isPlaying;
  final Color selectedColor;
  final VoidCallback onTogglePreview;
  final String? linkUrl;

  const MusicCoverWidget({
    super.key,
    required this.songName,
    required this.artistName,
    this.imageUrl,
    this.previewUrl,
    required this.isPlaying,
    required this.selectedColor,
    required this.onTogglePreview,
    required this.linkUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.music_note,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    if (isPlaying)
                      Container(color: Colors.black.withOpacity(0.35)),
                  ],
                ),
              ),
            ),
            if (previewUrl != null)
              GestureDetector(
                onTap: onTogglePreview,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPlaying
                          ? selectedColor
                          : Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
          ],
        ),
        if (isPlaying) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Now Playing',
                style: TextStyle(color: selectedColor, fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                songName,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            if (linkUrl != null && linkUrl!.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(linkUrl!);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          artistName,
          style: const TextStyle(fontSize: 16, color: Colors.white24),
        ),
      ],
    );
  }
}
