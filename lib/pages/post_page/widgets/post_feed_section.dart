import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/PostDto.dart';

import '../../../repositories/post_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../../widgets/PostWidget.dart';


class PostFeedSection extends StatelessWidget {
  final PostRepository postRepository;
  final String userRole;
  final String currentUserId;

  final String search; // client-side filter
  final List<String> selectedCategories;
  final PostMediaFilter mediaFilter;
  final int pageSize;

  const PostFeedSection({
    super.key,
    required this.postRepository,
    required this.userRole,
    required this.currentUserId,
    required this.search,
    required this.selectedCategories,
    required this.mediaFilter,
    this.pageSize = 20,
  });

  @override
  Widget build(BuildContext context) {

    final query = postRepository.postsQuery(
      search: search,
      selectedCategories: selectedCategories,
      mediaFilter: mediaFilter,
      limit: pageSize,
    );

    return FirestoreQueryBuilder<Map<String, dynamic>>(
      query: query,
      pageSize: pageSize,
      builder: (context, snapshot, _) {
        if (snapshot.isFetching && snapshot.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            "Fehler beim Laden: ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          );
        }

        // 1) docs -> posts
        final normalized = search.toLowerCase().trim();

        final posts = snapshot.docs
            .map((d) => PostDto.fromSnapshot(d))
            .where((p) {
          if (normalized.isEmpty) return true;
          final title = p.title.toLowerCase();
          final name = "${p.vorname.toLowerCase()} ${p.nachname.toLowerCase()}";
          return title.contains(normalized) || name.contains(normalized);
        })
            .toList();

        if (posts.isEmpty) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                  "Keine Beiträge vorhanden!",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: posts.length + 1,
          itemBuilder: (context, index) {
            if (index == posts.length) {
              if (!snapshot.hasMore) return const SizedBox.shrink();

              if (snapshot.isFetchingMore) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }

              return TextButton(
                onPressed: snapshot.fetchMore,
                child: const Text("Mehr laden", style: TextStyle(color: Colors.grey)),
              );
            }

            final post = posts[index];

            return PostWidget(
              post: post,
              userId: currentUserId,
              userRole: userRole,
              postRepository: postRepository,
            );
          },
        );
      },
    );
  }
}
