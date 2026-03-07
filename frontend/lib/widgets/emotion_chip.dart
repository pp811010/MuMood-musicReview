import 'package:flutter/material.dart';
import 'package:frontend/models/emotion.dart';

class EmotionChip extends StatelessWidget {
  final Emotion emotion;
  final bool isSelected;
  final int count;
  final Color selectedColor;
  final VoidCallback onTap;

  const EmotionChip({
    super.key,
    required this.emotion,
    required this.isSelected,
    required this.count,
    required this.selectedColor,
    required this.onTap,
  });

  static const Map<String, IconData> _icons = {
    'Happy': Icons.sentiment_very_satisfied,
    'Sad': Icons.sentiment_very_dissatisfied,
    'In Love': Icons.favorite,
    'Lonely': Icons.nightlight_round,
    'Missing': Icons.psychology,
    'Heartbroken': Icons.heart_broken,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[emotion.name] ?? Icons.music_note;
    const activeColor = Color.fromRGBO(255, 174, 174, 1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? selectedColor.withOpacity(0.9) : const Color(0xFF2A2A2A),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? activeColor : Colors.white60,
                size: 17),
            const SizedBox(width: 6),
            Text(emotion.name,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? activeColor : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? activeColor : Colors.white54,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}