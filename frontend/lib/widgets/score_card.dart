import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final String score;
  final String label;
  const ScoreCard({super.key, required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color.fromARGB(30, 136, 111, 249),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Column(
          children: [
            Text(
              score,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
                fontSize: 22,
              ),
            ),
            SizedBox(height: 5),
            Text(label, style: TextStyle(color: const Color.fromARGB(255, 182, 159, 245), fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
