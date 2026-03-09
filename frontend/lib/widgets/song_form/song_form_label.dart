import 'package:flutter/material.dart';

class SongFormLabel extends StatelessWidget {
  final String text;

  const SongFormLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }
}
