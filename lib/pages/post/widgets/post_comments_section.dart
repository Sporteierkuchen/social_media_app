
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/CommentDto.dart';
import '../../../models/Meldung.dart';
import '../../../models/PostDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/post_repository.dart';
import '../../../util/HelperUtil.dart';
import 'CommentWidegt/CommentWidget.dart';


class PostCommentsSection extends StatefulWidget {

  final PostDto post;
  final UserDto currentUser;
  final Future<void> Function() onPauseVideo;
  // ✅ von außen
  final Query<Map<String, dynamic>> commentsQuery;
  final Stream<int> commentsCountStream;
  final int pageSize;
  final PostRepository postRepository;


  const PostCommentsSection({
    super.key,
    required this.post,
    required this.currentUser,
    required this.onPauseVideo,
    required this.commentsQuery,
    required this.commentsCountStream,
    this.pageSize = 10,
    required this.postRepository,
  });

  @override
  State<PostCommentsSection> createState() => _PostCommentsSectionState();
}

class _PostCommentsSectionState extends State<PostCommentsSection> {

  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  String? _activeReplyCommentId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // Kopfzeile "Kommentare (X)"
        Container(
          color: Colors.black,
          padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
          child: Row(
            children: [
              StreamBuilder<int>(
                stream: widget.commentsCountStream,
                builder: (context, snap) {
                  final total = snap.data ?? 0;
                  return Text(
                    'Kommentare ($total)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Eingabe
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Schreibe einen Kommentar...',
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
              _isSending
                  ? const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : IconButton(
                icon: const Icon(Icons.send, size: 30, color: Colors.white),
                onPressed: _sendComment,
              ),
            ],
          ),
        ),

        // Realtime + Paging
        FirestoreQueryBuilder<Map<String, dynamic>>(
          query: widget.commentsQuery,
          pageSize: widget.pageSize,
          builder: (context, snapshot, _) {
            if (snapshot.isFetching && snapshot.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            if (snapshot.hasError) {
              return Text(
                "Fehler beim Laden der Kommentare: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              );
            }

            if (snapshot.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  "Noch keine Kommentare vorhanden.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.docs.length + 1,
              itemBuilder: (context, index) {
                // load more row
                if (index == snapshot.docs.length) {
                  if (!snapshot.hasMore) return const SizedBox(height: 20);

                  if (snapshot.isFetchingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  return Center(
                    child: TextButton(
                      onPressed: snapshot.fetchMore,
                      child: const Text("Mehr laden"),
                    ),
                  );
                }

                final doc = snapshot.docs[index];
                final comment = CommentDto.fromDocument(doc);

                return CommentWidget(
                  key: ValueKey(comment.id), // ✅ verhindert State-Verschiebung
                  comment: comment,
                  userData: widget.currentUser,
                  onTapped: widget.onPauseVideo,
                  isActive: _activeReplyCommentId == comment.id,
                  onReplyTapped: () => _toggleReplyInput(comment.id),
                  postRepository: widget.postRepository,
                );


              },
            );
          },
        ),

      ],
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final uid = widget.currentUser.userid;
    if (uid == null || uid.isEmpty) {
      HelperUtil.getToast(
        meldung: Meldung(meldungsart: Meldungsart.ERROR, text: "Nicht eingeloggt."),
        context: context,
      );
      return;
    }

    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      await widget.postRepository.addComment(
        postId: widget.post.id,
        userId: uid,
        userData: widget.currentUser,
        content: text,
      );
      _commentController.clear();
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Kommentar konnte nicht hinzugefügt werden:\n$e",
        ),
        context: context,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  void _toggleReplyInput(String commentId) {
    setState(() {
      if (_activeReplyCommentId == commentId) {
        _activeReplyCommentId = null;
      } else {
        _activeReplyCommentId = commentId;
      }
    });
  }

}
