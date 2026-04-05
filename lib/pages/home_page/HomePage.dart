import 'package:flutter/material.dart';
import 'package:social_media_app/pages/home_page/widgets/best_bilder_section.dart';

import '../../models/PostDto.dart';
import '../../models/UserDto.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/post_repository.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/Info_block.dart';
import 'widgets/best_videos_section.dart';

class HomePage extends StatefulWidget {
  final double contentHeight;

  const HomePage({
    super.key,
    required this.contentHeight,
  });

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  String? userID;

  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();

  UserDto? _lastUser;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint("[HomePage] initState() aufgerufen");

    userID = _authRepository.currentUserId;
    debugPrint("[HomePage] currentUserId = $userID");
  }

  @override
  void dispose() {
    debugPrint("[HomePage] dispose() aufgerufen");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    debugPrint("[HomePage] build() ausgeführt. userID=$userID");

    if (userID == null) {
      debugPrint("[HomePage] Kein User eingeloggt -> Hinweis anzeigen");
      return const Center(
        child: Text(
          "Bitte einloggen, um den Feed zu sehen.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final double heroHeight = widget.contentHeight;
    debugPrint("[HomePage] HeroHeight (contentHeight) = $heroHeight");

    return Container(
      key: const PageStorageKey<String>('home_page_scroll_root'),
      color: Colors.black,
      child: StreamBuilder<UserDto?>(
        stream: _userRepository.userStream(userID!),
        initialData: _lastUser,
        builder: (context, snapshot) {
          debugPrint(
            "[HomePage] StreamBuilder<UserDto?> build: "
                "connectionState=${snapshot.connectionState}, "
                "hasError=${snapshot.hasError}, "
                "hasData=${snapshot.hasData}",
          );

          if (snapshot.hasError) {
            debugPrint("[HomePage] Fehler im User-Stream: ${snapshot.error}");
            return const Center(
              child: Text(
                "Fehler beim Laden der Benutzerdaten.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final user = snapshot.data;

          if (user == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              debugPrint("[HomePage] User-Stream wartet noch...");
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            debugPrint("[HomePage] User-Stream liefert null -> Konto nicht gefunden");
            return const Center(
              child: Text(
                "Benutzerkonto nicht gefunden.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          _lastUser = user;

          final String userrole = user.role ?? "USER";
          debugPrint("[HomePage] User loaded: uid=${user.userid}, role=$userrole");

          return SingleChildScrollView(
            key: const PageStorageKey<String>('home_page_scroll'),
            child: Column(
              children: [
                HomeHeroImage(
                  userRole: userrole,
                  height: heroHeight,
                ),

                StreamBuilder<List<PostDto>>(
                  stream: _postRepository.bestImagesPostsStream(limit: 4),
                  builder: (context, snap) {
                    final loading =
                        snap.connectionState == ConnectionState.waiting && !snap.hasData;
                    final posts = snap.data ?? const <PostDto>[];

                    if (snap.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Fehler beim Laden der besten Bilder",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return BestBilderSection(
                      isLoading: loading,
                      posts: posts,
                      userRole: userrole,
                      currentUserId: userID,
                      postRepository: _postRepository,
                    );
                  },
                ),

                StreamBuilder<List<PostDto>>(
                  stream: _postRepository.bestVideosPostsStream(limit: 4),
                  builder: (context, snap) {
                    final loading =
                        snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData;
                    final posts = snap.data ?? const <PostDto>[];

                    if (snap.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Fehler beim Laden der besten Videos",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return BestVideosSection(
                      isLoading: loading,
                      posts: posts,
                      userRole: userrole,
                      currentUserId: userID,
                      postRepository: _postRepository,
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      InfoBlock(
                        imagePath: 'assets/images/page/home_page/bild1.jpg',
                        title: 'Was ist diese App?',
                        text:
                        "Diese App ist eine Social-Media-Plattform, auf der du kurze Clips, Fotos und Stories mit deiner Community teilen kannst. Im Fokus stehen Spaß, Kreativität und authentische Momente.",
                      ),
                      InfoBlock(
                        imagePath: 'assets/images/page/home_page/bild2.jpg',
                        title: 'Dein persönlicher Feed',
                        text:
                        "Entdecke neue Beiträge von Freunden und Creator:innen, like und kommentiere Inhalte und bleibe immer auf dem Laufenden, was in deiner Community passiert.",
                      ),
                      InfoBlock(
                        imagePath: 'assets/images/page/home_page/bild3.png',
                        title: 'Technik dahinter',
                        text:
                        "Die App wurde mit Flutter entwickelt und nutzt Firebase für Authentifizierung, Datenhaltung und Medien-Hosting. So können Inhalte in Echtzeit geladen und aktualisiert werden.",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}