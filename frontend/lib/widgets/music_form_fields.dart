import 'package:flutter/material.dart';

class AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  const AutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget _buildTextField() {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF00D138)),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        _buildTextField(),
      ],
    );
  }
}