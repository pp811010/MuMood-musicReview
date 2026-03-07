import 'package:flutter/material.dart';

class BuildSlider extends StatelessWidget {
  final String label;
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;

  const BuildSlider({
    super.key,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: color,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: color,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                overlayColor: color.withOpacity(0.2),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 5,
                onChanged: onChanged, 
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}