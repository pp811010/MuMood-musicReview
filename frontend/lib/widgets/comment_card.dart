import 'package:flutter/material.dart';
import 'package:frontend/services/comment_service.dart';
import 'package:frontend/widgets/user_avatar.dart';

class CommentCard extends StatelessWidget {
  final CommentItem comment;
  final int myUserId;
  final Color selectedColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    required this.myUserId,
    required this.selectedColor,
    required this.onEdit,
    required this.onDelete,
  });

  String _timeAgo() {
    try {
      final dt = DateTime.parse(comment.createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyComment = comment.userId == myUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: comment.username,
            size: 16,
            selectedColor: selectedColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                    if (comment.updatedAt != comment.createdAt)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          "(edited)",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const Spacer(),
                    // ── Edit + Delete เฉพาะ comment ของตัวเอง ──
                    if (isMyComment) ...[
                      GestureDetector(
                        onTap: onEdit,
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                // ── Content ──
                Text(
                  comment.content,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}