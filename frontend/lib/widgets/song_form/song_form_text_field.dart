import 'package:flutter/material.dart';

class SongFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final FocusNode focusNode;
  final Function(String)? onChanged;
  final bool isOptional;

  const SongFormTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.focusNode,
    this.onChanged,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (isOptional) return null;
        return (val == null || val.isEmpty) ? "*Required" : null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
