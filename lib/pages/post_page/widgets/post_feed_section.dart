import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/PostDto.dart';
import '../../../repositories/post_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../../widgets/PostWidget.dart';

class PostFeedSection extends StatefulWidget {
  final PostRepository postRepository;
  final String userRole;
  final String currentUserId;
  final String search;
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
  State<PostFeedSection> createState() => _PostFeedSectionState();
}

class _PostFeedSectionState extends State<PostFeedSection>
    with AutomaticKeepAliveClientMixin {
  bool _fetchTriggered = false;

  @override
  bool get wantKeepAlive => true;

  void _triggerFetchMoreIfNeeded(
      FirestoreQueryBuilderSnapshot<Map<String, dynamic>> snapshot,
      ) {
    if (!snapshot.hasMore) return;
    if (snapshot.isFetchingMore) return;
    if (_fetchTriggered) return;

    _fetchTriggered = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      snapshot.fetchMore();

      // erst zurücksetzen, wenn wirklich fertig
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _fetchTriggered = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final normalizedSearch = widget.search.toLowerCase().trim();
    final bool isSearchMode = normalizedSearch.isNotEmpty;

    final Query<Map<String, dynamic>> query = isSearchMode
        ? widget.postRepository.searchPostsByTitleQuery(
      searchText: normalizedSearch,
      selectedCategories: widget.selectedCategories,
      mediaFilter: widget.mediaFilter,
      limit: widget.pageSize,
    )
        : widget.postRepository.postsFeedQuery(
      selectedCategories: widget.selectedCategories,
      mediaFilter: widget.mediaFilter,
      limit: widget.pageSize,
    );

    return FirestoreQueryBuilder<Map<String, dynamic>>(
      query: query,
      pageSize: widget.pageSize,
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
          return Center(
            child: Text(
              "Fehler beim Laden: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        final posts = snapshot.docs
            .map((d) => PostDto.fromSnapshot(d))
            .toList();

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Text(
                isSearchMode
                    ? "Keine Suchergebnisse gefunden!"
                    : "Keine Beiträge vorhanden!",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          key: PageStorageKey<String>(
            isSearchMode ? 'post_search_list' : 'post_feed_list',
          ),
          cacheExtent: 1800,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          itemCount: posts.length +
              ((!isSearchMode && (snapshot.hasMore || snapshot.isFetchingMore))
                  ? 1
                  : 0),
          itemBuilder: (context, index) {
            if (!isSearchMode && index >= posts.length - 3) {
              _triggerFetchMoreIfNeeded(snapshot);
            }

            if (!isSearchMode && index >= posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            final post = posts[index];

            return RepaintBoundary(
              child: PostWidget(
                key: ValueKey(post.id),
                post: post,
                userId: widget.currentUserId,
                userRole: widget.userRole,
                postRepository: widget.postRepository,
              ),
            );
          },
        );
      },
    );
  }
}