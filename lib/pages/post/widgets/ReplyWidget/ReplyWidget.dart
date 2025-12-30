import 'package:flutter/material.dart';
import '../../../../models/Meldung.dart';
import '../../../../models/ReplyDto.dart';
import '../../../../models/UserDto.dart';
import '../../../../repositories/post_repository.dart';
import '../../../../util/HelperUtil.dart';
import '../../../../widgets/Bestätigung.dart';
import 'widgets/reply_actions_row.dart';
import 'widgets/reply_content_text.dart';
import 'widgets/reply_header_row.dart';

class ReplyWidget extends StatefulWidget {
  final ReplyDto reply;
  final UserDto userData;
  final VoidCallback onTapped;
  final PostRepository videoRepository;

  const ReplyWidget({
    super.key,
    required this.reply,
    required this.userData,
    required this.onTapped,
    required this.videoRepository,
  });

  @override
  ReplyWidgetState createState() => ReplyWidgetState();
}

class ReplyWidgetState extends State<ReplyWidget> {
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
  void didUpdateWidget(covariant ReplyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.reply.id != widget.reply.id) {
      isLiked = false;
      isDisliked = false;
      isLoading = true;
      initialize();
    }
  }

  @override
  Widget build(BuildContext context) {

    final bool enabled = !isLoading && canInteract;

    return Container(
      margin: const EdgeInsets.only(top: 10, left: 20, bottom: 10),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        children: [

          ReplyHeaderRow(
            reply: widget.reply,
            currentUser: widget.userData,
            onPauseVideo: widget.onTapped,
          ),

          ReplyContentText(content: widget.reply.content),

          ReplyActionsRow(
            reply: widget.reply,
            enabled: enabled,
            isLiked: isLiked,
            isDisliked: isDisliked,
            isUploader: _isUploader(),
            onLike: _likeReply,
            onDislike: _dislikeReply,
            onDeleteTapped: _confirmDelete,
          ),

        ],
      ),
    );
  }

  Future<void> initialize() async {
    try {
      await _checkReplyLikeDislikeStatus();
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkReplyLikeDislikeStatus() async {
    try {
      final status = await widget.videoRepository.getReplyLikeDislikeStatus(
        replyId: widget.reply.id,
        userId: widget.userData.userid!,
      );

      if (!mounted) return;

      setState(() {
        isLiked = status['liked'] ?? false;
        isDisliked = status['disliked'] ?? false;
      });
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Abrufen des Like/Dislike-Status:\n$e",
        ),
        context: context,
      );
    }
  }

  Future<void> _likeReply() async {
    if (!canInteract) return;
    setState(() => canInteract = false);

    try {
      await widget.videoRepository.toggleLikeReply(
        replyId: widget.reply.id,
        userId: widget.userData.userid!,
        isLiked: isLiked,
        isDisliked: isDisliked,
      );

      if (!mounted) return;
      setState(() {
        isLiked = !isLiked;
        if (isLiked) isDisliked = false;
      });
    } finally {
      if (!mounted) return;
      setState(() => canInteract = true);
    }
  }

  Future<void> _dislikeReply() async {
    if (!canInteract) return;
    setState(() => canInteract = false);

    try {
      await widget.videoRepository.toggleDislikeReply(
        replyId: widget.reply.id,
        userId: widget.userData.userid!,
        isLiked: isLiked,
        isDisliked: isDisliked,
      );

      if (!mounted) return;
      setState(() {
        isDisliked = !isDisliked;
        if (isDisliked) isLiked = false;
      });
    } finally {
      if (!mounted) return;
      setState(() => canInteract = true);
    }
  }

  Future<void> _confirmDelete() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            dialogTheme: const DialogThemeData(backgroundColor: Colors.black),
          ),
          child: BestaetigungsDialog(
            title: "Antwort löschen",
            message: "Soll die Antwort wirklich gelöscht werden?",
            onConfirm: () async {

              setState(() {
                isLoading = true;
                canInteract = false;
              });

              await _deleteReply(widget.reply);

              if (!mounted) return;
              setState(() {
                isLoading = false;
                canInteract = true;
              });
            },
            onCancel: () {},
          ),
        );
      },
    );
  }

  Future<void> _deleteReply(ReplyDto reply) async {
    try {
      await widget.videoRepository.deleteReply(reply.id);
      if (!mounted) return;

      HelperUtil.getToast(
        meldung: const Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Antwort erfolgreich gelöscht!",
        ),
        context: context,
      );
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Löschen der Antwort:\n$e",
        ),
        context: context,
      );
    }
  }

  bool _isUploader() => widget.userData.userid == widget.reply.userId;

}
