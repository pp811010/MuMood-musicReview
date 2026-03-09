import 'package:flutter/material.dart';

class SongCategoryDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const SongCategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> categories = [
    'Pop',
    'Rock',
    'Jazz',
    'Hip-Hop',
    'Classical',
    'R&B',
    'K-Pop',
    'Indie',
    'Metal',
    'EDM',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF2C2C2C),
      hint: const Text(
        "Select Category",
        style: TextStyle(color: Colors.white24),
      ),
      items: categories
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (val) => val == null ? '*Please select a category' : null,
    );
  }
}
