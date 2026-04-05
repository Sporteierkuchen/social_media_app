import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/PostDto.dart';
import '../../../pages/post/Post.dart';
import '../../../util/HelperUtil.dart';

class HomePostCard extends StatelessWidget {
  final PostDto post;
  final String currentUserId;

  const HomePostCard({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  String get _previewUrl {
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

  String get _typeLabel {
    return post.type == PostType.video ? "Video" : "Bild";
  }

  IconData get _typeIcon {
    return post.type == PostType.video ? Icons.play_circle : Icons.image;
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _previewUrl;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(
              post: post,
              userId: currentUserId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (previewUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: previewUrl,
                      imageBuilder: (context, imageProvider) {
                        return Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        );
                      },
                      placeholder: (context, url) => Container(
                        color: Colors.grey[850],
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        "assets/images/page/empty.png",
                        fit: BoxFit.cover,
                      ),
                      fadeInDuration: const Duration(milliseconds: 120),
                    )
                  else
                    Image.asset(
                      "assets/images/page/empty.png",
                      fit: BoxFit.cover,
                    ),

                  // leichtes dunkles Overlay für bessere Lesbarkeit
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromARGB(30, 0, 0, 0),
                          Color.fromARGB(40, 0, 0, 0),
                          Color.fromARGB(160, 0, 0, 0),
                        ],
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
                        color: Colors.black.withValues(alpha: 0.65),
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

                  // Play-Icon mittig für Videos
                  if (post.type == PostType.video)
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Text(
                post.benutzername.isNotEmpty
                    ? post.benutzername
                    : "${post.vorname} ${post.nachname}".trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      post.views == 1
                          ? "${post.views} Aufruf"
                          : "${post.views} Aufrufe",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.thumb_up,
                    color: Colors.grey,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    HelperUtil.calculateLikePercentage(
                      likes: post.likes,
                      dislikes: post.dislikes,
                    ),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
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
}