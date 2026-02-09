import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF636363),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_outlined, 0),
          _navItem(Icons.person_outline, 1),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isActive = currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        size: 35,
        color: isActive ? Colors.white : Colors.black54, // เปลี่ยนสีเมื่อ Active
      ),
      onPressed: () => onTap(index),
    );
  }
}