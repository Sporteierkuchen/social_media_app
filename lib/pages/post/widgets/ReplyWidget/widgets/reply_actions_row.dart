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

    final double opacity = enabled ? 1.0 : 0.35;

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Row(
            children: [
              // Like
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onLike,
                      child: Icon(
                        Icons.thumb_up,
                        color: isLiked ? Colors.green : Colors.grey,
                        size: 15,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        "${reply.likes}",
                        style: const TextStyle(
                          fontSize: 15,
                          height: 0,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dislike
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onDislike,
                      child: Icon(
                        Icons.thumb_down,
                        color: isDisliked ? Colors.red : Colors.grey,
                        size: 15,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        "${reply.dislikes}",
                        style: const TextStyle(
                          fontSize: 15,
                          height: 0,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Delete (nur uploader)
              if (isUploader)
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: onDeleteTapped,
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 25,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
