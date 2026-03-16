import 'package:flutter/material.dart';
import 'package:egon_kowalski_app/models/PostDto.dart';
import 'package:egon_kowalski_app/models/UserDto.dart';
import 'package:egon_kowalski_app/repositories/post_repository.dart';
import '../../widgets/PostWidget.dart';

class CreatorPostsPage extends StatelessWidget {
  final String creatorId;
  final String currentUserId;
  final String currentUserRole;
  final String? type;
  final List<String> postIds;
  final UserDto creator;

  CreatorPostsPage({
    super.key,
    required this.creatorId,
    required this.currentUserId,
    required this.currentUserRole,
    required this.postIds,
    required this.creator,
    this.type,
  });

  final PostRepository _postRepository = PostRepository();

  Widget _buildCreatorHeader(UserDto creator, int postCount) {
    final fullName = "${creator.vorname} ${creator.nachname}".trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[800],
            backgroundImage: creator.profilePictureUrl!.isNotEmpty
                ? NetworkImage(creator.profilePictureUrl!)
                : null,
            child: creator.profilePictureUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : creator.benutzername!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "@${creator.benutzername}",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    if (creator.role!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          creator.role!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    Text(
                      "$postCount neue Beiträge",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    String pageTitle = "Neue Uploads";

    final fullName = "${creator.vorname} ${creator.nachname}".trim();

    if (type == "image" || type == "bild") {
      pageTitle = "📸 Neue Bilder";
    } else if (type == "video") {
      pageTitle = "🎬 Neue Videos";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          pageTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: FutureBuilder<List<PostDto>>(
        future: _postRepository.getPostsByIds(postIds),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Fehler beim Laden der Beiträge",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final posts = snapshot.data!;

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                "Keine Beiträge gefunden",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [

              _buildCreatorHeader(creator, posts.length),

              Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    return PostWidget(
                      post: post,
                      userId: currentUserId,
                      userRole: currentUserRole,
                      postRepository: _postRepository,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

    );
  }
}