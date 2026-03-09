import 'package:flutter/material.dart';
import 'package:frontend/services/comment_service.dart';
import 'package:frontend/widgets/comment_input_box.dart';
import 'package:frontend/widgets/comment_card.dart';

class CommentSection extends StatelessWidget {
  final List<CommentItem> comments;
  final int myUserId;
  final String myUserName;
  final Color selectedColor;
  final bool openCommentBox;
  final bool isEditingComment;
  final bool isPosting;
  final TextEditingController controller;
  final VoidCallback onOpenNew;
  final VoidCallback onCloseBox;
  final VoidCallback onSubmit;
  final void Function(CommentItem comment) onEditComment;
  final void Function(CommentItem comment) onDeleteComment;

  const CommentSection({
    super.key,
    required this.comments,
    required this.myUserId,
    required this.myUserName,
    required this.selectedColor,
    required this.openCommentBox,
    required this.isEditingComment,
    required this.isPosting,
    required this.controller,
    required this.onOpenNew,
    required this.onCloseBox,
    required this.onSubmit,
    required this.onEditComment,
    required this.onDeleteComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "Comments",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (comments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${comments.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            // ── Write button ──
            GestureDetector(
              onTap: () {
                if (openCommentBox && !isEditingComment) {
                  onCloseBox();
                } else {
                  onOpenNew();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (openCommentBox && !isEditingComment)
                      ? Colors.white
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 15,
                      color: (openCommentBox && !isEditingComment)
                          ? Colors.black
                          : Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Write",
                      style: TextStyle(
                        color: (openCommentBox && !isEditingComment)
                            ? Colors.black
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Input box ──
        if (openCommentBox) ...[
          const SizedBox(height: 16),
          CommentInputBox(
            username: myUserName,
            controller: controller,
            isEditing: isEditingComment,
            isPosting: isPosting,
            selectedColor: selectedColor,
            onCancel: onCloseBox,
            onSubmit: onSubmit,
          ),
        ],

        const SizedBox(height: 16),

        // ── Comment list ──
        if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white.withOpacity(0.15),
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No comments yet",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white.withOpacity(0.06), height: 1),
            itemBuilder: (_, i) => CommentCard(
              comment: comments[i],
              myUserId: myUserId,
              selectedColor: selectedColor,
              onEdit: () => onEditComment(comments[i]),
              onDelete: () => onDeleteComment(comments[i]),
            ),
          ),
      ],
    );
  }
}