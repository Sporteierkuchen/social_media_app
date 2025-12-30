import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/PostDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/post_repository.dart';
import '../../../widgets/PostWidget.dart';

enum UserMediaFilter { all, videos, images }

class UserInfoPostsSection extends StatefulWidget {
  final UserDto userData;    // Profilbesitzer
  final UserDto viewerData;  // aktueller Viewer
  final PostRepository postRepository;

  final int pageSize;

  const UserInfoPostsSection({
    super.key,
    required this.userData,
    required this.viewerData,
    required this.postRepository,
    this.pageSize = 10,
  });

  @override
  State<UserInfoPostsSection> createState() => _UserInfoPostsSectionState();
}

class _UserInfoPostsSectionState extends State<UserInfoPostsSection> {

  UserMediaFilter _filter = UserMediaFilter.all;

  @override
  Widget build(BuildContext context) {
    final userId = widget.userData.userid!;
    final type = _typeForFilter(_filter);

    final Query<Map<String, dynamic>> query = widget.postRepository.userPostsQuery(
      userId: userId,
      type: type,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Titel + Live-Count ----
        StreamBuilder<int>(
          stream: _countStreamForFilter(_filter),
          builder: (context, snap) {
            final countText = snap.hasData ? "${snap.data}" : "…";
            return Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                "${_titleForFilter(_filter)} von ${widget.userData.vorname} ${widget.userData.nachname} ($countText)",
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

        // ---- Filter (Alle / Videos / Bilder) ----
        Row(
          children: [
            _FilterChip(
              label: "Alle",
              active: _filter == UserMediaFilter.all,
              onTap: () => setState(() => _filter = UserMediaFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Videos",
              active: _filter == UserMediaFilter.videos,
              onTap: () => setState(() => _filter = UserMediaFilter.videos),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Bilder",
              active: _filter == UserMediaFilter.images,
              onTap: () => setState(() => _filter = UserMediaFilter.images),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ---- Paging + Realtime ----
        FirestoreQueryBuilder<Map<String, dynamic>>(
          // Wenn du sicherstellen willst, dass beim Wechsel “frisch” geladen wird,
          // hilft ein Key, damit der Builder neu startet:
          key: ValueKey("${userId}_${type ?? "all"}"),
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

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.docs.length + 1,
              itemBuilder: (context, index) {
                // Load more row
                if (index == snapshot.docs.length) {
                  if (!snapshot.hasMore) return const SizedBox(height: 20);

                  if (snapshot.isFetchingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  return Center(
                    child: TextButton(
                      onPressed: snapshot.fetchMore,
                      child: const Text(
                        "Mehr laden",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final doc = snapshot.docs[index];
                final post = PostDto.fromSnapshot(doc);

                return PostWidget(
                  post: post,
                  userId: widget.viewerData.userid,
                  userRole: widget.viewerData.role ?? "USER",
                  postRepository: widget.postRepository,
                );
              },
            );
          },
        ),
      ],
    );
  }

  String? _typeForFilter(UserMediaFilter f) {
    switch (f) {
      case UserMediaFilter.videos:
        return 'video';
      case UserMediaFilter.images:
        return 'image';
      case UserMediaFilter.all:
        return null;
    }
  }

  String _titleForFilter(UserMediaFilter f) {
    switch (f) {
      case UserMediaFilter.videos:
        return "Videos";
      case UserMediaFilter.images:
        return "Bilder";
      case UserMediaFilter.all:
        return "Beiträge";
    }
  }

  Stream<int> _countStreamForFilter(UserMediaFilter f) {
    final id = widget.userData.userid!;
    switch (f) {
      case UserMediaFilter.videos:
        return widget.postRepository.userVideoCountStream(id);
      case UserMediaFilter.images:
        return widget.postRepository.userImageCountStream(id);
      case UserMediaFilter.all:
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
      child: Container(
        decoration: BoxDecoration(
          color: active ? Colors.orange : Colors.grey[800],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            height: 0,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
