import 'package:flutter/material.dart';
import 'package:social_media_app/pages/post/widgets/CommentWidegt/widgets/comment_actions_row.dart';
import 'package:social_media_app/pages/post/widgets/CommentWidegt/widgets/comment_content_text.dart';
import 'package:social_media_app/pages/post/widgets/CommentWidegt/widgets/comment_header_row.dart';
import 'package:social_media_app/pages/post/widgets/CommentWidegt/widgets/comment_replies_section.dart';

import '../../../../models/CommentDto.dart';
import '../../../../models/UserDto.dart';
import '../../../../repositories/post_repository.dart';
import '../../../../models/Meldung.dart';
import '../../../../util/HelperUtil.dart';
import '../../../../widgets/Bestätigung.dart';

class CommentWidget extends StatefulWidget {
  final CommentDto comment;
  final UserDto userData;
  final bool isActive;
  final VoidCallback onReplyTapped;
  final VoidCallback onTapped;
  final PostRepository postRepository;
  final String? initialReplyId;
  final bool highlighted;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.userData,
    required this.isActive,
    required this.onReplyTapped,
    required this.onTapped,
    required this.postRepository,
    this.initialReplyId,
    this.highlighted = false,
  });

  @override
  CommentWidgetState createState() => CommentWidgetState();
}

class CommentWidgetState extends State<CommentWidget> {
  bool isLiked = false;
  bool isDisliked = false;
  bool canInteract = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void didUpdateWidget(covariant CommentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.comment.id != widget.comment.id) {
      isLiked = false;
      isDisliked = false;
      isLoading = true;
      initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = !isLoading && canInteract;
    final double opacity = enabled ? 1.0 : 0.45;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: widget.highlighted
            ? const Color(0xFF2D2400)
            : const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.highlighted ? Colors.amber : Colors.white10,
          width: widget.highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          CommentHeaderRow(
            comment: widget.comment,
            currentUser: widget.userData,
            onPauseVideo: widget.onTapped,
          ),

          CommentContentText(content: widget.comment.content),

          CommentActionsRow(
            comment: widget.comment,
            postRepository: widget.postRepository,
            enabled: enabled,
            isLiked: isLiked,
            isDisliked: isDisliked,
            isUploader: _isUploader(),
            onLike: _likeComment,
            onDislike: _dislikeComment,
            onReplyTapped: widget.onReplyTapped,
            onDeleteTapped: _confirmDelete,
          ),

          Opacity(
            opacity: opacity,
            child: IgnorePointer(
              ignoring: !enabled,
              child: CommentRepliesSection(
                commentId: widget.comment.id,
                currentUser: widget.userData,
                onTapped: widget.onTapped,
                postRepository: widget.postRepository,
                isActive: widget.isActive,
                onClose: widget.onReplyTapped,
                initialReplyId: widget.initialReplyId,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> initialize() async {
    try {
      await _checkCommentLikeDislikeStatus();
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkCommentLikeDislikeStatus() async {
    try {
      final status = await widget.postRepository.getCommentLikeDislikeStatus(
        commentId: widget.comment.id,
        userId: widget.userData.userid!,
      );

      if (!mounted) return;

      setState(() {
        isLiked = status['liked'] ?? false;
        isDisliked = status['disliked'] ?? false;
      });
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Abrufen des Like/Dislike-Status:\n$e",
        ),
      );
    }
  }

  Future<void> _likeComment() async {
    if (!canInteract) return;

    if (mounted) {
      setState(() {
        canInteract = false;
      });
    }

    try {
      await widget.postRepository.toggleLikeComment(
        commentId: widget.comment.id,
        userId: widget.userData.userid!,
        isLiked: isLiked,
        isDisliked: isDisliked,
      );

      if (mounted) {
        setState(() {
          isLiked = !isLiked;
          if (isLiked) {
            isDisliked = false;
          }
        });
      }
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Liken des Kommentars:\n$e",
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          canInteract = true;
        });
      }
    }
  }

  Future<void> _dislikeComment() async {
    if (!canInteract) return;

    if (mounted) {
      setState(() {
        canInteract = false;
      });
    }

    try {
      await widget.postRepository.toggleDislikeComment(
        commentId: widget.comment.id,
        userId: widget.userData.userid!,
        isLiked: isLiked,
        isDisliked: isDisliked,
      );

      if (mounted) {
        setState(() {
          isDisliked = !isDisliked;
          if (isDisliked) {
            isLiked = false;
          }
        });
      }
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Disliken des Kommentars:\n$e",
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          canInteract = true;
        });
      }
    }
  }

  bool _isUploader() {
    return widget.userData.userid == widget.comment.userId;
  }

  Future<void> _confirmDelete() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogCtx) {
        return Theme(
          data: Theme.of(dialogCtx).copyWith(
            dialogTheme: const DialogThemeData(backgroundColor: Colors.black),
          ),
          child: BestaetigungsDialog(
            title: "Kommentar löschen",
            message: "Soll der Kommentar wirklich gelöscht werden?",
            onConfirm: () async {
              if (!mounted) return;
              setState(() {
                isLoading = true;
                canInteract = false;
              });

              try {
                await _deleteComment(widget.comment);
              } finally {
                if (!mounted) return;
                setState(() {
                  isLoading = false;
                  canInteract = true;
                });
              }
            },
            onCancel: () {},
          ),
        );
      },
    );
  }

  Future<void> _deleteComment(CommentDto comment) async {
    try {
      await widget.postRepository.deleteCommentWithReplies(comment.id);

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Kommentar erfolgreich gelöscht!",
        ),
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Löschen des Kommentars:\n$e",
        ),
      );
    }
  }
}