import 'package:flutter/material.dart';
import 'package:frontend/widgets/user_avatar.dart';

class CommentInputBox extends StatelessWidget {
  final String username;
  final TextEditingController controller;
  final bool isEditing;
  final bool isPosting;
  final Color selectedColor;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const CommentInputBox({
    super.key,
    required this.username,
    required this.controller,
    required this.isEditing,
    required this.isPosting,
    required this.selectedColor,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: username, size: 18, selectedColor: selectedColor),
              const SizedBox(width: 10),
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isEditing)
                const Text(
                  "Editing",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  isEditing ? "Edit your comment..." : "Share your thoughts...",
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  elevation: 0,
                ),
                onPressed: isPosting ? null : onSubmit,
                child: isPosting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? "Save" : "Post",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}