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
    final imageMaxHeight = mediaQuery.size.height * 0.6;

    return StreamBuilder<PostDto?>(
      stream: postStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(fontSize: 16, color: Colors.red),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- MEDIA ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: post.type == PostType.video
                    ? (playerReady && chewieController != null
                    ? AspectRatio(
                  aspectRatio: chewieController!.aspectRatio ?? 16 / 9,
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
                    memCacheWidth:
                    (screenWidth * mediaQuery.devicePixelRatio)
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
            ),

            // ---------------- TITEL ----------------
            Container(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 8,
                bottom: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.start,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- META ----------------
            Container(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      views == 1 ? "$views Aufruf" : "$views Aufrufe",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.thumb_up,
                          color: Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          HelperUtil.calculateLikePercentage(
                            likes: likes,
                            dislikes: dislikes,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      HelperUtil.getTimeAgo(uploadDate),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- LIKE / DISLIKE ----------------
            Container(
              color: Colors.black,
              padding: const EdgeInsets.only(top: 5, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LikeButton(
                    labelCount: likes,
                    isActive: isLiked,
                    canInteract: canInteract,
                    icon: Icons.thumb_up,
                    activeColor: Colors.blue,
                    onTap: onLike,
                  ),
                  _LikeButton(
                    labelCount: dislikes,
                    isActive: isDisliked,
                    canInteract: canInteract,
                    icon: Icons.thumb_down,
                    activeColor: Colors.red,
                    onTap: onDislike,
                  ),
                ],
              ),
            ),

            // ---------------- KATEGORIEN ----------------
            if (categories.isNotEmpty)
              Container(
                color: Colors.black,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(8.0),
                child: const Text(
                  "Kategorien",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (categories.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 3, right: 3, bottom: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3.0,
                  mainAxisSpacing: 3.0,
                  childAspectRatio: 80 / 20,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      border: Border.all(),
                      borderRadius:
                      const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      categories[index].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _LikeButton extends StatelessWidget {
  final int labelCount;
  final bool isActive;
  final bool canInteract;
  final IconData icon;
  final Color activeColor;
  final Future<void> Function() onTap;

  const _LikeButton({
    required this.labelCount,
    required this.isActive,
    required this.canInteract,
    required this.icon,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          canInteract
              ? GestureDetector(
            onTap: onTap,
            child: Icon(
              icon,
              color: isActive ? activeColor : Colors.white,
              size: 20,
            ),
          )
              : const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              "$labelCount",
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}