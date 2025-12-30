// lib/widgets/post_widget.dart

import 'package:flutter/material.dart';
import '../models/Meldung.dart';
import '../models/PostDto.dart';
import '../repositories/post_repository.dart';
import '../util/HelperUtil.dart';
import 'Bestätigung.dart';
import '../pages/post/Post.dart';

class PostWidget extends StatefulWidget {
  final PostDto post;
  final String? userId;
  final String userRole;
  final PostRepository postRepository; // später evtl. PostRepository

  const PostWidget({
    super.key,
    required this.post,
    required this.userId,
    required this.userRole,
    required this.postRepository,
  });

  @override
  State<PostWidget> createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> {
  bool canInteract = true;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    // ✅ Preview-URL abhängig vom Typ
    final previewUrl = post.type == PostType.video
        ? (post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.mediaUrl)
        : post.mediaUrl;

    return GestureDetector(
      onTap: () async {
        debugPrint("Ausgewählter Post: ${post.title}");

        // ✅ falls kein User vorhanden ist -> nichts tun
        if (widget.userId == null) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(post: post, userId: widget.userId!),
          ),
        );

        // 🚧 erstmal leer lassen (Navigation machen wir später)
        // if (post.type == PostType.post) { ... } else { ... }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 15),
        color: Colors.black,
        child: Column(
          children: [
            // ---------------- PREVIEW (+ PLAY nur bei Video) ----------------
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  previewUrl,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width - 20,
                  height: MediaQuery.of(context).size.height * 0.25,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      "assets/images/page/empty.png",
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width - 20,
                      height: MediaQuery.of(context).size.height * 0.25,
                    );
                  },
                ),

                // ✅ Play-Icon nur bei Videos
                if (post.type == PostType.video)
                  Image.asset(
                    "assets/images/play.png",
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.width * 0.15,
                  ),
              ],
            ),

            const SizedBox(height: 5),

            // ---------------- TITEL ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 15,
                      ),
                      child: Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 0,
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.start,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- META: VIEWS + LIKE-PROZENT + DELETE ----------------
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 20,
              ),
              child: Row(
                children: [
                  // Aufrufe
                  Text(
                    post.views == 1 ? "${post.views} Aufruf" : "${post.views} Aufrufe",
                    style: const TextStyle(
                      fontSize: 16,
                      height: 0,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),

                  const SizedBox(width: 15),

                  // Like-Prozent
                  Row(
                    children: [
                      const Icon(
                        Icons.thumb_up,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        HelperUtil.calculateLikePercentage(
                          likes: post.likes,
                          dislikes: post.dislikes,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 0,
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ],
                  ),

                  // ---------------- DELETE ICON (nur Uploader) ----------------
                  _isUploader()
                      ? Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: canInteract
                          ? GestureDetector(
                        onTap: () async {
                          await showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (dialogCtx) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  dialogTheme: const DialogThemeData(
                                    backgroundColor: Colors.black,
                                  ),
                                ),
                                child: BestaetigungsDialog(
                                  title: "Beitrag löschen",
                                  message: "Soll der Beitrag \"${post.title}\" wirklich gelöscht werden?",
                                  onConfirm: () async {
                                    if (!mounted) return;
                                    if (!canInteract) return;

                                    setState(() => canInteract = false);

                                    await _deletePost(post);

                                    if (!mounted) return;
                                    setState(() => canInteract = true);
                                  },
                                  onCancel: () {},
                                ),
                              );
                            },
                          );
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 25,
                        ),
                      )
                          : const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isUploader() {
    return widget.userId != null && widget.post.userid == widget.userId;
  }

  Future<void> _deletePost(PostDto post) async {
    if (!mounted) return;

    try {

      final success = await widget.postRepository.deletePost(post.id);

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.INFO,
          text: "Delete kommt gleich – sobald deletePost() im Repository existiert.",
        ),
        context: context,
      );

      if (success) {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.SUCCESS,
            text: 'Der Post "${post.title}" wurde gelöscht!',
          ),
          context: context,
        );
        // kein reload nötig – stream updated automatisch
      } else {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.ERROR,
            text: 'Fehler beim Löschen des Posts "${post.title}"!',
          ),
          context: context,
        );
      }

    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: 'Unerwarteter Fehler beim Löschen:\n$e',
        ),
        context: context,
      );
    }
  }

}
