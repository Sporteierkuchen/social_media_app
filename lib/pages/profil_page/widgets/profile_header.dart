
import 'package:flutter/material.dart';
import '../../../models/UserDto.dart';
import '../../../util/HelperUtil.dart';

class ProfileHeader extends StatelessWidget {
  final UserDto userData;

  // Counts
  final Stream<int> videoCountStream;
  final Stream<int> imageCountStream;

  // Views
  final Stream<int> videoViewsStream;
  final Stream<int> imageViewsStream;

  // Subs
  final Stream<int> subscribersCountStream;

  const ProfileHeader({
    super.key,
    required this.userData,
    required this.videoCountStream,
    required this.imageCountStream,
    required this.videoViewsStream,
    required this.imageViewsStream,
    required this.subscribersCountStream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 10, right: 10, top: 40, bottom: 20),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/page/background.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profilbild
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(120),
              child: (userData.profilePictureUrl != null && userData.profilePictureUrl!.isNotEmpty)
                  ? Image.network(
                userData.profilePictureUrl!,
                fit: BoxFit.cover,
                width: 240,
                height: 240,
                errorBuilder: (_, __, ___) => Image.asset(
                  "assets/images/page/empty.png",
                  fit: BoxFit.cover,
                  width: 240,
                  height: 240,
                ),
              )
                  : Image.asset(
                "assets/images/page/empty.png",
                fit: BoxFit.cover,
                width: 240,
                height: 240,
              ),
            ),
          ),

          // Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "${userData.vorname ?? ''} ${userData.nachname ?? ''}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),

          // Role-Icon
          Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 0, right: 20, left: 20),
            child: HelperUtil.getUserIcon(userData.role ?? "USER"),
          ),

          // ------------------------------------------------------------
          // Stats: Videos / Bilder / Posts gesamt
          // ------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Videos
                StreamBuilder<int>(
                  stream: videoCountStream,
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return _StatColumn(
                      value: "$count",
                      label: count == 1 ? "Video" : "Videos",
                    );
                  },
                ),

                // Bilder
                StreamBuilder<int>(
                  stream: imageCountStream,
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return _StatColumn(
                      value: "$count",
                      label: count == 1 ? "Bild" : "Bilder",
                    );
                  },
                ),

                // Posts gesamt = Videos + Bilder
                StreamBuilder<int>(
                  stream: videoCountStream,
                  builder: (context, vSnap) {
                    final v = vSnap.data ?? 0;
                    return StreamBuilder<int>(
                      stream: imageCountStream,
                      builder: (context, iSnap) {
                        final i = iSnap.data ?? 0;
                        final total = v + i;
                        return _StatColumn(
                          value: "$total",
                          label: total == 1 ? "Post" : "Posts",
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------
          // Stats: Video-Ansichten / Bild-Ansichten / Gesamt-Ansichten
          // ------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(top: 0, left: 15, right: 15, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Video-Ansichten
                StreamBuilder<int>(
                  stream: videoViewsStream,
                  builder: (context, snap) {
                    final views = snap.data ?? 0;
                    return _StatColumn(
                      value: "$views",
                      label: views == 1 ? "Video-Ansicht" : "Video-Ansichten",
                    );
                  },
                ),

                // Bild-Ansichten
                StreamBuilder<int>(
                  stream: imageViewsStream,
                  builder: (context, snap) {
                    final views = snap.data ?? 0;
                    return _StatColumn(
                      value: "$views",
                      label: views == 1 ? "Bild-Ansicht" : "Bild-Ansichten",
                    );
                  },
                ),

                // Gesamt-Ansichten = VideoViews + ImageViews
                StreamBuilder<int>(
                  stream: videoViewsStream,
                  builder: (context, vSnap) {
                    final v = vSnap.data ?? 0;
                    return StreamBuilder<int>(
                      stream: imageViewsStream,
                      builder: (context, iSnap) {
                        final i = iSnap.data ?? 0;
                        final total = v + i;
                        return _StatColumn(
                          value: "$total",
                          label: total == 1 ? "Ansicht" : "Ansichten",
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------
          // Abonnenten (wie bei UserInfoHeader)
          // ------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 15, right: 15, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder<int>(
                  stream: subscribersCountStream,
                  builder: (context, snap) {
                    final subs = snap.data ?? 0;
                    return _StatColumn(
                      value: "$subs",
                      label: subs == 1 ? "Abonnent" : "Abonnenten",
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            height: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            height: 0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
