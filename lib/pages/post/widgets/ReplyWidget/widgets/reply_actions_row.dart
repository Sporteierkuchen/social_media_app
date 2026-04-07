import 'package:flutter/material.dart';

import '../../../../../models/ReplyDto.dart';

class ReplyActionsRow extends StatelessWidget {
  final ReplyDto reply;

  final bool enabled;
  final bool isLiked;
  final bool isDisliked;
  final bool isUploader;

  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onDeleteTapped;

  const ReplyActionsRow({
    super.key,
    required this.reply,
    required this.enabled,
    required this.isLiked,
    required this.isDisliked,
    required this.isUploader,
    required this.onLike,
    required this.onDislike,
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
              _ReplyActionChip(
                icon: Icons.thumb_up_alt_outlined,
                color: isLiked ? Colors.green : Colors.white60,
                label: "${reply.likes}",
                onTap: onLike,
              ),
              const SizedBox(width: 8),
              _ReplyActionChip(
                icon: Icons.thumb_down_alt_outlined,
                color: isDisliked ? Colors.red : Colors.white60,
                label: "${reply.dislikes}",
                onTap: onDislike,
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
                      size: 16,
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

class _ReplyActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ReplyActionChip({
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
          horizontal: 9,
          vertical: 6,
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
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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