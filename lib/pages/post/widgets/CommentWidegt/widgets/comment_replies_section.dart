
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
  final VoidCallback onClose; // z.B. reply input schließen
  final int pageSize;

  const CommentRepliesSection({
    super.key,
    required this.commentId,
    required this.currentUser,
    required this.onTapped,
    required this.postRepository,
    required this.isActive,
    required this.onClose,
    this.pageSize = 2,
  });

  @override
  State<CommentRepliesSection> createState() => _CommentRepliesSectionState();
}

class _CommentRepliesSectionState extends State<CommentRepliesSection> {

  final TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Reply-Input nur wenn aktiv
        if (widget.isActive)
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Schreibe eine Antwort...',
                      hintStyle: const TextStyle(color: Colors.black),
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue, width: 3.0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                _isSendingReply
                    ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : IconButton(
                  icon: const Icon(Icons.send, size: 30, color: Colors.white),
                  onPressed: _sendReply,
                ),
              ],
            ),
          ),

        // Realtime + Paging (Replies)
        FirestoreQueryBuilder<Map<String, dynamic>>(
          query: widget.postRepository.replyQuery(widget.commentId),
          pageSize: widget.pageSize,
          builder: (context, snapshot, _) {
            if (snapshot.isFetching && snapshot.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
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
                // load more row
                if (index == snapshot.docs.length) {
                  if (!snapshot.hasMore) return const SizedBox(height: 10);

                  if (snapshot.isFetchingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  }

                  return StreamBuilder<int>(
                    stream: widget.postRepository.repliesCountStream(widget.commentId),
                    builder: (context, countSnap) {
                      final total = countSnap.data ?? snapshot.docs.length;
                      final loaded = snapshot.docs.length;
                      final remaining = (total - loaded) > 0 ? (total - loaded) : 0;

                      final label = remaining > 0
                          ? "Mehr Antworten laden ($remaining verbleibend)"
                          : "Mehr Antworten laden";

                      return Center(
                        child: TextButton(
                          onPressed: snapshot.fetchMore,
                          child: Text(label),
                        ),
                      );
                    },
                  );
                }

                final doc = snapshot.docs[index];
                final reply = ReplyDto.fromDocument(doc);

                return ReplyWidget(
                  key: ValueKey(reply.id),
                  reply: reply,
                  userData: widget.currentUser,
                  onTapped: widget.onTapped,
                  videoRepository: widget.postRepository,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final uid = widget.currentUser.userid;
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(meldungsart: Meldungsart.ERROR, text: "Nicht eingeloggt."),
        context: context,
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
      widget.onClose(); // klappt Input wieder zu
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Antwort konnte nicht hinzugefügt werden:\n$e",
        ),
        context: context,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSendingReply = false);
    }
  }

}
