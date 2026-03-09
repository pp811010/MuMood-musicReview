import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color selectedColor;

  const UserAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundColor: selectedColor.withOpacity(0.3),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: selectedColor,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.8,
        ),
      ),
    );
  }
}