import 'package:flutter/material.dart';
import '../../../models/PostDto.dart';
import '../../../repositories/post_repository.dart';
import '../../../widgets/PostWidget.dart';

class BestBilderSection extends StatelessWidget {
  final bool isLoading;
  final List<PostDto> posts;
  final String userRole;
  final String? currentUserId;
  final PostRepository postRepository;

  const BestBilderSection({
    super.key,
    required this.isLoading,
    required this.posts,
    required this.userRole,
    required this.currentUserId,
    required this.postRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // ✅ volle Breite
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(width: 3, color: Colors.orange),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 10),
            child: Text(
              "Die Besten Bilder",
              style: TextStyle(
                fontSize: 35,
                height: 0,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.width * 0.5,
                  child: const CircularProgressIndicator(),
                ),
              ),
            )
          else if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "Keine Bilder gefunden",
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostWidget(
                  post: post,
                  userId: currentUserId,
                  userRole: userRole,
                  postRepository: postRepository,
                );
              },
            ),
        ],
      ),
    );
  }
}
