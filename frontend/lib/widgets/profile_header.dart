import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final double avatarRadius;

  const ProfileHeader({
    super.key,
    required this.username,
    this.avatarRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Color(0xFFFFCCBC),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.transparent,
            backgroundImage: const AssetImage("assets/icons/funny_emoji.png"),
          ),
        ),
        const SizedBox(width: 20),
        Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
