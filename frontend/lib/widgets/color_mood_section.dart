import 'package:flutter/material.dart';
import 'package:frontend/models/mood_color.dart';

class ColorMoodSection extends StatelessWidget {
  final bool isLoading;
  final List<MoodColor> allMoodColor;
  final int? selectedMoodColorId;
  final Map<String, int> colorCounts;
  final bool isLocked;
  final void Function(MoodColor mood, Color color) onSelect;

  const ColorMoodSection({
    super.key,
    required this.isLoading,
    required this.allMoodColor,
    required this.selectedMoodColorId,
    required this.colorCounts,
    required this.isLocked,
    required this.onSelect,
  });

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Color Mood",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 45,
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: allMoodColor.map((mood) {
                    final color = _hexToColor(mood.colorHex);
                    final count = colorCounts[mood.colorHex] ?? 0;
                    final isSelected = selectedMoodColorId == mood.id;
                    return GestureDetector(
                      onTap: isLocked ? null : () => onSelect(mood, color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        width: isSelected ? 52 : 45,
                        height: isSelected ? 52 : 45,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            isSelected ? 14 : 10,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: count > 0
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}