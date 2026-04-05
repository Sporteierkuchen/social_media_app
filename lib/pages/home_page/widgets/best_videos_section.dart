import 'package:flutter/material.dart';

import '../../../models/PostDto.dart';
import '../../../repositories/post_repository.dart';
import 'home_post_card.dart';

class BestVideosSection extends StatelessWidget {
  final bool isLoading;
  final List<PostDto> posts;
  final String userRole;
  final String? currentUserId;
  final PostRepository postRepository;

  const BestVideosSection({
    super.key,
    required this.isLoading,
    required this.posts,
    required this.userRole,
    required this.currentUserId,
    required this.postRepository,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border.symmetric(
          horizontal: BorderSide(width: 3, color: Colors.orange),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 14),
            child: Text(
              "Die Besten Videos",
              style: TextStyle(
                fontSize: 30,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 20, top: 6),
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "Keine Videos gefunden",
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final post = posts[index];

                  return RepaintBoundary(
                    child: HomePostCard(
                      key: ValueKey(post.id),
                      post: post,
                      currentUserId: currentUserId!,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}