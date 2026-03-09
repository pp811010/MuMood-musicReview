import 'package:flutter/material.dart';

class NoTracksFound extends StatelessWidget {
  const NoTracksFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            "No tracks found",
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}