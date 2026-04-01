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
  final double contentHeight; // sichtbare Höhe (ohne BottomNavBar)

  const HomePage({
    super.key,
    required this.contentHeight,
  });

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? userID; // aktuell eingeloggter User (oder null)

  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    debugPrint("[HomePage] initState() aufgerufen");

    // Aktuellen User holen (falls nicht eingeloggt => null)
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
    debugPrint("[HomePage] build() ausgeführt. userID=$userID");

    // Falls kein User eingeloggt ist
    if (userID == null) {
      debugPrint("[HomePage] Kein User eingeloggt -> Hinweis anzeigen");
      return const Center(
        child: Text("Bitte einloggen, um den Feed zu sehen."),
      );
    }

    final double heroHeight = widget.contentHeight;
    debugPrint("[HomePage] HeroHeight (contentHeight) = $heroHeight");

    return StreamBuilder<UserDto?>(
      stream: _userRepository.userStream(userID!),
      builder: (context, snapshot) {
        debugPrint(
          "[HomePage] StreamBuilder<UserDto?> build: "
              "connectionState=${snapshot.connectionState}, "
              "hasError=${snapshot.hasError}, "
              "hasData=${snapshot.hasData}",
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("[HomePage] User-Stream wartet noch...");
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("[HomePage] Fehler im User-Stream: ${snapshot.error}");
          return const Center(
            child: Text("Fehler beim Laden der Benutzerdaten."),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          debugPrint("[HomePage] User-Stream liefert null -> Konto nicht gefunden");
          return const Center(
            child: Text("Benutzerkonto nicht gefunden."),
          );
        }

        final String userrole = user.role ?? "USER";
        debugPrint("[HomePage] User loaded: uid=${user.userid}, role=$userrole");

        return Container(
          color: Colors.black,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ---------- HERO-BILD ----------
                HomeHeroImage(
                  userRole: userrole,
                  height: heroHeight,
                ),

                // ✅ Beste Bilder
                StreamBuilder<List<PostDto>>(
                  stream: _postRepository.bestImagesPostsStream(limit: 4),
                  builder: (context, snap) {
                    final loading =
                        snap.connectionState == ConnectionState.waiting;
                    final posts = snap.data ?? [];

                    if (snap.hasError) {
                      return const Text("Fehler beim Laden der besten Bilder");
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

                // ✅ Beste Videos
                StreamBuilder<List<PostDto>>(
                  stream: _postRepository.bestVideosPostsStream(limit: 4),
                  builder: (context, snap) {
                    final loading =
                        snap.connectionState == ConnectionState.waiting;
                    final posts = snap.data ?? [];

                    if (snap.hasError) {
                      return const Text("Fehler beim Laden der besten Videos");
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

                // ---------- INFO-BLÖCKE ----------
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Column(
                    children: const [
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
          ),
        );
      },
    );
  }
}