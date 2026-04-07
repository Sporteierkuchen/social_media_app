import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../models/Meldung.dart';
import '../../../../../models/ReplyDto.dart';
import '../../../../../models/UserDto.dart';
import '../../../../../repositories/post_repository.dart';
import '../../../../../util/HelperUtil.dart';
import '../../ReplyWidget/ReplyWidget.dart';

class CommentRepliesSection extends StatefulWidget {
  final String commentId;
  final UserDto currentUser;
  final VoidCallback onTapped;
  final PostRepository postRepository;

  final bool isActive;
  final VoidCallback onClose;
  final int pageSize;
  final String? initialReplyId;

  const CommentRepliesSection({
    super.key,
    required this.commentId,
    required this.currentUser,
    required this.onTapped,
    required this.postRepository,
    required this.isActive,
    required this.onClose,
    this.pageSize = 2,
    this.initialReplyId,
  });

  @override
  State<CommentRepliesSection> createState() => _CommentRepliesSectionState();
}

class _CommentRepliesSectionState extends State<CommentRepliesSection> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;

  final Map<String, GlobalKey> _replyKeys = {};
  bool _initialReplyScrollDone = false;
  String? _highlightedReplyId;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          if (widget.isActive)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      cursorColor: Colors.orange,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Schreibe eine Antwort...',
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSendingReply
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                      : GestureDetector(
                    onTap: _sendReply,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          FirestoreQueryBuilder<Map<String, dynamic>>(
            query: widget.postRepository.replyQuery(widget.commentId),
            pageSize: widget.pageSize,
            builder: (context, snapshot, _) {
              if (snapshot.isFetching && snapshot.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 10),
                  child: Text(
                    "Fehler beim Laden der Antworten: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.docs.isEmpty) return const SizedBox.shrink();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.docs.length + 1,
                itemBuilder: (context, index) {
                  if (index == snapshot.docs.length) {
                    if (!snapshot.hasMore) return const SizedBox(height: 4);

                    if (snapshot.isFetchingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }

                    return StreamBuilder<int>(
                      stream: widget.postRepository.repliesCountStream(widget.commentId),
                      builder: (context, countSnap) {
                        final total = countSnap.data ?? snapshot.docs.length;
                        final loaded = snapshot.docs.length;
                        final remaining = (total - loaded) > 0 ? (total - loaded) : 0;

                        final label = remaining > 0
                            ? "Mehr Antworten laden ($remaining)"
                            : "Mehr Antworten laden";

                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: snapshot.fetchMore,
                            child: Text(
                              label,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  final doc = snapshot.docs[index];
                  final reply = ReplyDto.fromDocument(doc);

                  final key = _getReplyKey(reply.id);

                  if (widget.initialReplyId != null &&
                      widget.initialReplyId == reply.id) {
                    _scrollToReplyIfNeeded(reply.id);
                  }

                  return Container(
                    key: key,
                    margin: const EdgeInsets.only(left: 0, bottom: 8),
                    child: ReplyWidget(
                      key: ValueKey(reply.id),
                      reply: reply,
                      userData: widget.currentUser,
                      onTapped: widget.onTapped,
                      videoRepository: widget.postRepository,
                      highlighted: _highlightedReplyId == reply.id,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final uid = widget.currentUser.userid;
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Nicht eingeloggt.",
        ),
      );
      return;
    }

    if (_isSendingReply) return;
    setState(() => _isSendingReply = true);

    try {
      await widget.postRepository.addReply(
        commentId: widget.commentId,
        userId: uid,
        userData: widget.currentUser,
        content: text,
      );
      _replyController.clear();
      widget.onClose();
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Antwort konnte nicht hinzugefügt werden:\n$e",
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSendingReply = false);
    }
  }

  GlobalKey _getReplyKey(String replyId) {
    return _replyKeys.putIfAbsent(replyId, () => GlobalKey());
  }

  void _scrollToReplyIfNeeded(String replyId) {
    if (_initialReplyScrollDone) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final key = _replyKeys[replyId];
      final context = key?.currentContext;

      if (context != null) {
        _initialReplyScrollDone = true;

        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );

        if (mounted) {
          setState(() {
            _highlightedReplyId = replyId;
          });
        }

        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          if (_highlightedReplyId == replyId) {
            setState(() {
              _highlightedReplyId = null;
            });
          }
        });
      }
    });
  }
}