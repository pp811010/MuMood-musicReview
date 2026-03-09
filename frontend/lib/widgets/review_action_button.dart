import 'package:flutter/material.dart';

class ReviewActionButtons extends StatelessWidget {
  final bool hasReview;
  final bool isEditing;
  final bool isSubmitting;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const ReviewActionButtons({
    super.key,
    required this.hasReview,
    required this.isEditing,
    required this.isSubmitting,
    required this.onEdit,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // ── Edit button (มี review อยู่แล้ว และไม่ได้กำลัง edit) ──
        if (hasReview && !isEditing)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white38),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text("Edit", style: TextStyle(fontSize: 14)),
          ),

        // ── Cancel + Submit/Save (ยังไม่มี review หรือ กำลัง edit) ──
        if (!hasReview || isEditing) ...[
          if (isEditing)
            TextButton(
              onPressed: onCancel,
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white38),
              ),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSubmitting ? Colors.grey : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    hasReview ? "Save" : "Submit Rating",
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
          ),
        ],
      ],
    );
  }
}