import 'package:flutter/material.dart';
import 'package:frontend/widgets/detail_slider.dart';
import 'package:frontend/widgets/score_card.dart';

class RatingSection extends StatelessWidget {
  final Map<String, dynamic> avgScores;
  final double beatValue;
  final double lyricValue;
  final double moodValue;
  final bool isLocked;
  final ValueChanged<double>? onBeatChanged;
  final ValueChanged<double>? onLyricChanged;
  final ValueChanged<double>? onMoodChanged;

  const RatingSection({
    super.key,
    required this.avgScores,
    required this.beatValue,
    required this.lyricValue,
    required this.moodValue,
    required this.isLocked,
    this.onBeatChanged,
    this.onLyricChanged,
    this.onMoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Music Detail",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ScoreCard(
                score: avgScores['beat']?.toStringAsFixed(2) ?? '0.00',
                label: 'Beat',
              ),
            ),
            Expanded(
              child: ScoreCard(
                score: avgScores['lyric']?.toStringAsFixed(2) ?? '0.00',
                label: 'Lyric',
              ),
            ),
            Expanded(
              child: ScoreCard(
                score: avgScores['mood']?.toStringAsFixed(2) ?? '0.00',
                label: 'Mood',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BuildSlider(
          label: 'Beat',
          color: const Color.fromARGB(255, 229, 206, 107),
          value: beatValue,
          onChanged: isLocked ? null : onBeatChanged,
        ),
        BuildSlider(
          label: 'Lyric',
          color: const Color.fromARGB(255, 236, 123, 123),
          value: lyricValue,
          onChanged: isLocked ? null : onLyricChanged,
        ),
        BuildSlider(
          label: 'Mood',
          color: const Color.fromARGB(173, 150, 81, 184),
          value: moodValue,
          onChanged: isLocked ? null : onMoodChanged,
        ),
      ],
    );
  }
}