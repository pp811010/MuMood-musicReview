import 'package:flutter/material.dart';
import 'package:frontend/models/emotion.dart';
import 'package:frontend/widgets/emotion_chip.dart';

class EmotionSection extends StatelessWidget {
  final bool isLoading;
  final List<Emotion> allEmotion;
  final String? selectedEmotion;
  final Map<String, int> emotionCounts;
  final Color selectedColor;
  final bool isLocked;
  final void Function(Emotion emotion) onTap;

  const EmotionSection({
    super.key,
    required this.isLoading,
    required this.allEmotion,
    required this.selectedEmotion,
    required this.emotionCounts,
    required this.selectedColor,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: allEmotion.map((emotion) {
        return EmotionChip(
          emotion: emotion,
          isSelected: selectedEmotion == emotion.name,
          count: emotionCounts[emotion.name] ?? 0,
          selectedColor: selectedColor,
          onTap: isLocked ? () {} : () => onTap(emotion),
        );
      }).toList(),
    );
  }
}