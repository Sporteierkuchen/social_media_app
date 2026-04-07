import 'package:flutter/material.dart';

import '../../../../../models/CommentDto.dart';
import '../../../../../repositories/post_repository.dart';

class CommentActionsRow extends StatelessWidget {
  final CommentDto comment;
  final PostRepository postRepository;

  final bool enabled;
  final bool isLiked;
  final bool isDisliked;
  final bool isUploader;

  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onReplyTapped;
  final VoidCallback onDeleteTapped;

  const CommentActionsRow({
    super.key,
    required this.comment,
    required this.postRepository,
    required this.enabled,
    required this.isLiked,
    required this.isDisliked,
    required this.isUploader,
    required this.onLike,
    required this.onDislike,
    required this.onReplyTapped,
    required this.onDeleteTapped,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = enabled ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Row(
            children: [
              _ActionChip(
                icon: Icons.thumb_up_alt_outlined,
                color: isLiked ? Colors.green : Colors.white60,
                label: "${comment.likes}",
                onTap: onLike,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.thumb_down_alt_outlined,
                color: isDisliked ? Colors.red : Colors.white60,
                label: "${comment.dislikes}",
                onTap: onDislike,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onReplyTapped,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: StreamBuilder<int>(
                    stream: postRepository.repliesCountStream(comment.id),
                    builder: (context, snap) {
                      final c = snap.data ?? 0;
                      return Text(
                        "Antworten ($c)",
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isUploader) ...[
                const Spacer(),
                GestureDetector(
                  onTap: onDeleteTapped,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}