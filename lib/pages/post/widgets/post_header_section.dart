import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';

import '../../../models/PostDto.dart';
import '../../../util/HelperUtil.dart';

class PostHeaderSection extends StatelessWidget {
  final Stream<PostDto?> postStream;

  final bool playerReady;
  final ChewieController? chewieController;

  final bool canInteract;
  final bool isLiked;
  final bool isDisliked;
  final Future<void> Function() onLike;
  final Future<void> Function() onDislike;

  const PostHeaderSection({
    super.key,
    required this.postStream,
    required this.playerReady,
    required this.chewieController,
    required this.canInteract,
    required this.isLiked,
    required this.isDisliked,
    required this.onLike,
    required this.onDislike,
  });

  String _getDetailImageUrl(PostDto post) {
    if (post.fullImageUrl.isNotEmpty) {
      return post.fullImageUrl;
    }

    if (post.mediaUrl.isNotEmpty) {
      return post.mediaUrl;
    }

    if (post.previewUrl.isNotEmpty) {
      return post.previewUrl;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final imageMaxHeight = mediaQuery.size.height * 0.62;

    return StreamBuilder<PostDto?>(
      stream: postStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Fehler: ${snapshot.error}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          );
        }

        final post = snapshot.data;
        if (post == null) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                "Beitrag nicht gefunden",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final categories = post.categories;
        final dislikes = post.dislikes;
        final likes = post.likes;
        final uploadDate = post.timestamp;
        final title = post.title;
        final views = post.views;
        final detailImageUrl = _getDetailImageUrl(post);

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- MEDIA ----------------
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: post.type == PostType.video
                      ? (playerReady && chewieController != null
                      ? AspectRatio(
                    aspectRatio:
                    chewieController!.aspectRatio ?? 16 / 9,
                    child: Chewie(controller: chewieController!),
                  )
                      : SizedBox(
                    width: double.infinity,
                    height: screenWidth * 0.7,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ))
                      : detailImageUrl.isNotEmpty
                      ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: imageMaxHeight,
                      minWidth: double.infinity,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: detailImageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      fadeInDuration:
                      const Duration(milliseconds: 120),
                      memCacheWidth: (screenWidth *
                          mediaQuery.devicePixelRatio)
                          .round(),
                      placeholder: (context, url) => SizedBox(
                        width: double.infinity,
                        height: screenWidth * 0.8,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return Image.asset(
                          "assets/images/page/empty.png",
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: screenWidth * 0.8,
                        );
                      },
                    ),
                  )
                      : Image.asset(
                    "assets/images/page/empty.png",
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: screenWidth * 0.8,
                  ),
                ),

                // ---------------- CONTENT ----------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titel
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 23,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Meta
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetaChip(
                            icon: Icons.visibility_outlined,
                            label:
                            views == 1 ? "$views Aufruf" : "$views Aufrufe",
                          ),
                          _MetaChip(
                            icon: Icons.thumb_up_alt_outlined,
                            label: HelperUtil.calculateLikePercentage(
                              likes: likes,
                              dislikes: dislikes,
                            ),
                          ),
                          _MetaChip(
                            icon: Icons.schedule,
                            label: HelperUtil.getTimeAgo(uploadDate),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Like / Dislike
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: "$likes",
                              text: "Gefällt mir",
                              icon: Icons.thumb_up_alt_outlined,
                              isActive: isLiked,
                              activeColor: Colors.blue,
                              canInteract: canInteract,
                              onTap: onLike,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: "$dislikes",
                              text: "Gefällt nicht",
                              icon: Icons.thumb_down_alt_outlined,
                              isActive: isDisliked,
                              activeColor: Colors.red,
                              canInteract: canInteract,
                              onTap: onDislike,
                            ),
                          ),
                        ],
                      ),

                      if (categories.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text(
                          "Kategorien",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((category) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF232323),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white60,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final bool canInteract;
  final Future<void> Function() onTap;

  const _ActionButton({
    required this.label,
    required this.text,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.canInteract,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? activeColor : Colors.white;

    return GestureDetector(
      onTap: canInteract ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.7) : Colors.white10,
          ),
        ),
        child: canInteract
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: foreground,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "$text · $label",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        )
            : const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        ),
      ),
    );
  }
}