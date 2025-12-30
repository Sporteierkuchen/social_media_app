import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';

import '../../../models/PostDto.dart';
import '../../../util/HelperUtil.dart';

class PostHeaderSection extends StatelessWidget {
  final Stream<PostDto?> postStream;

  // Video-only
  final bool playerReady;
  final ChewieController? chewieController;

  // Like/Dislike
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

  @override
  Widget build(BuildContext context) {
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
              child: Text("Beitrag nicht gefunden", style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final categories = post.categories;
        final dislikes = post.dislikes;
        final likes = post.likes;
        final uploadDate = post.timestamp;
        final title = post.title;
        final views = post.views;

        return Column(
          children: [
            // ----------- Media ----------
            Container(
              padding: const EdgeInsets.only(top: 20),
              color: Colors.black,
              child: post.type == PostType.video
                  ? (playerReady && chewieController != null
                  ? AspectRatio(
                aspectRatio: 16 / 9,
                child: Chewie(controller: chewieController!),
              )
                  : SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.width * 0.5,
                child: const Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, bottom: 20),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ))
                  : Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                errorBuilder: (context, error, _) {
                  return Image.asset(
                    "assets/images/page/empty.png",
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                  );
                },
              ),
            ),

            // Titel
            Container(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 0,
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

            // Views + Like-Quote + Zeitpunkt
            Container(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      views == 1 ? "$views Aufruf" : "$views Aufrufe",
                      style: const TextStyle(fontSize: 16, height: 0, color: Colors.grey),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("|", style: TextStyle(fontSize: 16, height: 0, color: Colors.grey)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up, color: Colors.grey, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          HelperUtil.calculateLikePercentage(likes: likes, dislikes: dislikes),
                          style: const TextStyle(fontSize: 16, height: 0, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("|", style: TextStyle(fontSize: 16, height: 0, color: Colors.grey)),
                    ),
                    Expanded(
                      child: Text(
                        HelperUtil.getTimeAgo(uploadDate),
                        style: const TextStyle(fontSize: 16, height: 0, color: Colors.grey),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Like / Dislike Buttons
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
                    onTap: onLike,
                  ),
                  _LikeButton(
                    labelCount: dislikes,
                    isActive: isDisliked,
                    canInteract: canInteract,
                    icon: Icons.thumb_down,
                    onTap: onDislike,
                  ),
                ],
              ),
            ),

            // Kategorien
            if (categories.isNotEmpty)
              Container(
                color: Colors.black,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(8.0),
                child: const Text(
                  "Kategorien",
                  style: TextStyle(fontSize: 16, height: 0, color: Colors.white, fontWeight: FontWeight.bold),
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
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      categories[index].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, height: 0, color: Colors.white),
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
  final Future<void> Function() onTap;

  const _LikeButton({
    required this.labelCount,
    required this.isActive,
    required this.canInteract,
    required this.icon,
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
              color: isActive ? Colors.blue : Colors.white,
              size: 20,
            ),
          )
              : const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              "$labelCount",
              style: const TextStyle(fontSize: 20, height: 0, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
