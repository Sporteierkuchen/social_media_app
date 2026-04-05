import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/PostDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/post_repository.dart';
import '../../../widgets/PostWidget.dart';

enum MyMediaFilter { all, videos, images }

class MyPostsSection extends StatefulWidget {
  final UserDto userData;
  final PostRepository postRepository;
  final int pageSize;

  const MyPostsSection({
    super.key,
    required this.userData,
    required this.postRepository,
    this.pageSize = 10,
  });

  @override
  State<MyPostsSection> createState() => _MyPostsSectionState();
}

class _MyPostsSectionState extends State<MyPostsSection>
    with AutomaticKeepAliveClientMixin {
  MyMediaFilter _filter = MyMediaFilter.all;
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

      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _fetchTriggered = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userId = widget.userData.userid!;
    final type = _typeForFilter(_filter);

    final Query<Map<String, dynamic>> query = widget.postRepository.userPostsQuery(
      userId: userId,
      type: type,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<int>(
          stream: _countStreamForFilter(_filter),
          builder: (context, snap) {
            final countText = snap.hasData ? "${snap.data}" : "…";

            return Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                "Meine ${_titleForFilter(_filter)} ($countText)",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            _FilterChip(
              label: "Alle",
              active: _filter == MyMediaFilter.all,
              onTap: () => setState(() => _filter = MyMediaFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Videos",
              active: _filter == MyMediaFilter.videos,
              onTap: () => setState(() => _filter = MyMediaFilter.videos),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Bilder",
              active: _filter == MyMediaFilter.images,
              onTap: () => setState(() => _filter = MyMediaFilter.images),
            ),
          ],
        ),

        const SizedBox(height: 10),

        FirestoreQueryBuilder<Map<String, dynamic>>(
          key: ValueKey("my_posts_${userId}_${type ?? "all"}"),
          query: query,
          pageSize: widget.pageSize,
          builder: (context, snapshot, _) {
            if (snapshot.isFetching && snapshot.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
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

            if (snapshot.docs.isEmpty) {
              return Text(
                "Noch keine ${_titleForFilter(_filter)} vorhanden.",
                style: const TextStyle(color: Colors.white70),
              );
            }

            final posts = snapshot.docs
                .map((doc) => PostDto.fromSnapshot(doc))
                .toList();

            return ListView.builder(
              key: PageStorageKey<String>('my_posts_list_${type ?? "all"}'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              cacheExtent: 1800,
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
              itemCount:
              posts.length + (snapshot.hasMore || snapshot.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= posts.length - 2) {
                  _triggerFetchMoreIfNeeded(snapshot);
                }

                if (index >= posts.length) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 12),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  );
                }

                final post = posts[index];

                return RepaintBoundary(
                  child: PostWidget(
                    key: ValueKey(post.id),
                    post: post,
                    userId: widget.userData.userid,
                    userRole: widget.userData.role ?? "USER",
                    postRepository: widget.postRepository,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String? _typeForFilter(MyMediaFilter f) {
    switch (f) {
      case MyMediaFilter.videos:
        return 'video';
      case MyMediaFilter.images:
        return 'image';
      case MyMediaFilter.all:
        return null;
    }
  }

  String _titleForFilter(MyMediaFilter f) {
    switch (f) {
      case MyMediaFilter.videos:
        return "Videos";
      case MyMediaFilter.images:
        return "Bilder";
      case MyMediaFilter.all:
        return "Beiträge";
    }
  }

  Stream<int> _countStreamForFilter(MyMediaFilter f) {
    final id = widget.userData.userid!;
    switch (f) {
      case MyMediaFilter.videos:
        return widget.postRepository.userVideoCountStream(id);
      case MyMediaFilter.images:
        return widget.postRepository.userImageCountStream(id);
      case MyMediaFilter.all:
        return widget.postRepository.userPostCountStream(id);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: active ? Colors.orange : Colors.grey[800],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}