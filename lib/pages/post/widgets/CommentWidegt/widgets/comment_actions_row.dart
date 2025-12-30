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
    final double opacity = enabled ? 1.0 : 0.35;

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
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
                        "${comment.likes}",
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
                        "${comment.dislikes}",
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

              // Antworten (mit Count)
              GestureDetector(
                onTap: onReplyTapped,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: StreamBuilder<int>(
                    stream: postRepository.repliesCountStream(comment.id),
                    builder: (context, snap) {
                      final c = snap.data ?? 0;
                      return Text(
                        "Antworten ($c)",
                        style: const TextStyle(
                          fontSize: 15,
                          height: 0,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Löschen (nur uploader)
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
