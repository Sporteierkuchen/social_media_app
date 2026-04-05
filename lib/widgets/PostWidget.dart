import 'package:cached_network_image/cached_network_image.dart';
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
  final PostRepository postRepository;

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

class PostWidgetState extends State<PostWidget>
    with AutomaticKeepAliveClientMixin {
  bool canInteract = true;

  @override
  bool get wantKeepAlive => true;

  String get _previewUrl {
    final post = widget.post;

    if (post.previewUrl.isNotEmpty) {
      return post.previewUrl;
    }

    if (post.type == PostType.video) {
      if (post.thumbnailUrl.isNotEmpty) {
        return post.thumbnailUrl;
      }
      return post.mediaUrl;
    }

    return post.mediaUrl;
  }

  String get _creatorText {
    final post = widget.post;

    if (post.benutzername.trim().isNotEmpty) {
      return post.benutzername.trim();
    }

    final fullName = "${post.vorname} ${post.nachname}".trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return "Unbekannter Nutzer";
  }

  String get _typeLabel {
    return widget.post.type == PostType.video ? "Video" : "Bild";
  }

  IconData get _typeIcon {
    return widget.post.type == PostType.video ? Icons.play_circle : Icons.image;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final post = widget.post;
    final mediaQuery = MediaQuery.of(context);
    final imageWidth = mediaQuery.size.width - 24;
    final imageHeight = mediaQuery.size.height * 0.27;
    final previewUrl = _previewUrl;

    return GestureDetector(
      onTap: () async {
        debugPrint("Ausgewählter Post: ${post.title}");

        if (widget.userId == null) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(
              post: post,
              userId: widget.userId!,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- MEDIA ----------------
            Stack(
              fit: StackFit.passthrough,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  child: previewUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: previewUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 120),
                    memCacheWidth:
                    (imageWidth * mediaQuery.devicePixelRatio).round(),
                    placeholder: (context, url) => Container(
                      color: Colors.grey[850],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      "assets/images/page/empty.png",
                      fit: BoxFit.cover,
                      width: imageWidth,
                      height: imageHeight,
                    ),
                  )
                      : Image.asset(
                    "assets/images/page/empty.png",
                    fit: BoxFit.cover,
                    width: imageWidth,
                    height: imageHeight,
                  ),
                ),

                // leichtes Overlay für Lesbarkeit
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.22),
                        ],
                      ),
                    ),
                  ),
                ),

                // Badge oben links
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _typeIcon,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (post.type == PostType.video)
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
              ],
            ),

            // ---------------- CONTENT ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 19,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: post.profilePictureUrl.trim().isNotEmpty
                        ? NetworkImage(post.profilePictureUrl)
                        : null,
                    child: post.profilePictureUrl.trim().isEmpty
                        ? const Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.white,
                    )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _creatorText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isUploader())
                    canInteract
                        ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 22,
                      ),
                      onPressed: () async {
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
                                message:
                                'Soll der Beitrag "${post.title}" wirklich gelöscht werden?',
                                onConfirm: () async {
                                  if (!canInteract) {
                                    return;
                                  }

                                  if (mounted) {
                                    setState(() {
                                      canInteract = false;
                                    });
                                  }

                                  await _deletePost(post);

                                  if (mounted) {
                                    setState(() {
                                      canInteract = true;
                                    });
                                  }
                                },
                                onCancel: () {},
                              ),
                            );
                          },
                        );
                      },
                    )
                        : const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    post.views == 1
                        ? "${post.views} Aufruf"
                        : "${post.views} Aufrufe",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.thumb_up,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        HelperUtil.calculateLikePercentage(
                          likes: post.likes,
                          dislikes: post.dislikes,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    HelperUtil.getTimeAgo(post.timestamp),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
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
    final postTitle = post.title;

    try {
      final success = await widget.postRepository.deletePost(post.id);

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: success ? Meldungsart.SUCCESS : Meldungsart.ERROR,
          text: success
              ? 'Der Post "$postTitle" wurde gelöscht!'
              : 'Fehler beim Löschen des Posts "$postTitle"!',
        ),
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: 'Unerwarteter Fehler beim Löschen:\n$e',
        ),
      );
    }
  }

}