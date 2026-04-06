import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/UserDto.dart';
import '../../../util/HelperUtil.dart';

class ProfileHeader extends StatelessWidget {
  final UserDto userData;

  final Stream<int> videoCountStream;
  final Stream<int> imageCountStream;
  final Stream<int> videoViewsStream;
  final Stream<int> imageViewsStream;
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

  String get _displayName {
    return "${userData.vorname ?? ''} ${userData.nachname ?? ''}".trim();
  }

  String get _subTitle {
    if ((userData.benutzername ?? '').trim().isNotEmpty) {
      return userData.benutzername!.trim();
    }
    return _displayName;
  }

  bool get _hasProfileImage {
    return (userData.profilePictureUrl ?? '').trim().isNotEmpty;
  }

  bool get _hasBackgroundImage {
    return (userData.backgroundImageUrl ?? '').trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double bannerHeight = mediaQuery.size.height * 0.5;
    final double avatarSize = 200;

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF101010),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: bannerHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _hasBackgroundImage
                            ? CachedNetworkImage(
                          imageUrl: userData.backgroundImageUrl!.trim(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Image.asset(
                            "assets/images/page/background.png",
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (context, url, error) =>
                              Image.asset(
                                "assets/images/page/background.png",
                                fit: BoxFit.cover,
                              ),
                        )
                            : Image.asset(
                          "assets/images/page/background.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromARGB(20, 0, 0, 0),
                                Color.fromARGB(70, 0, 0, 0),
                                Color(0xFF101010),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _hasProfileImage
                                      ? CachedNetworkImage(
                                    imageUrl:
                                    userData.profilePictureUrl!.trim(),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Image.asset(
                                          "assets/images/page/empty.png",
                                          fit: BoxFit.cover,
                                        ),
                                    errorWidget: (context, url, error) =>
                                        Image.asset(
                                          "assets/images/page/empty.png",
                                          fit: BoxFit.cover,
                                        ),
                                  )
                                      : Image.asset(
                                    "assets/images/page/empty.png",
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _displayName.isEmpty
                                    ? "Unbekannter Nutzer"
                                    : _displayName,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _subTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 28,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child:
                                  HelperUtil.getUserIcon(userData.role ?? "USER"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SingleStreamStatCard(
                              stream: videoCountStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) => v == 1 ? "Video" : "Videos",
                              icon: Icons.play_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SingleStreamStatCard(
                              stream: imageCountStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) => v == 1 ? "Bild" : "Bilder",
                              icon: Icons.image_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DualStreamStatCard(
                              firstStream: videoCountStream,
                              secondStream: imageCountStream,
                              valueBuilder: (a, b) => "${a + b}",
                              titleBuilder: (a, b) =>
                              (a + b) == 1 ? "Post" : "Posts",
                              icon: Icons.grid_view_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _SingleStreamStatCard(
                              stream: videoViewsStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) =>
                              v == 1 ? "Video-Ansicht" : "Video-Ansichten",
                              icon: Icons.visibility_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SingleStreamStatCard(
                              stream: imageViewsStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) =>
                              v == 1 ? "Bild-Ansicht" : "Bild-Ansichten",
                              icon: Icons.photo_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DualStreamStatCard(
                              firstStream: videoViewsStream,
                              secondStream: imageViewsStream,
                              valueBuilder: (a, b) => "${a + b}",
                              titleBuilder: (a, b) =>
                              (a + b) == 1 ? "Ansicht" : "Ansichten",
                              icon: Icons.bar_chart_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _SingleStreamStatCard(
                              stream: subscribersCountStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) =>
                              v == 1 ? "Abonnent" : "Abonnenten",
                              icon: Icons.people_alt_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleStreamStatCard extends StatelessWidget {
  final Stream<int> stream;
  final String Function(int value) valueBuilder;
  final String Function(int value) titleBuilder;
  final IconData icon;

  const _SingleStreamStatCard({
    required this.stream,
    required this.valueBuilder,
    required this.titleBuilder,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final value = snap.data ?? 0;

        return _StatCard(
          value: valueBuilder(value),
          label: titleBuilder(value),
          icon: icon,
        );
      },
    );
  }
}

class _DualStreamStatCard extends StatelessWidget {
  final Stream<int> firstStream;
  final Stream<int> secondStream;
  final String Function(int first, int second) valueBuilder;
  final String Function(int first, int second) titleBuilder;
  final IconData icon;

  const _DualStreamStatCard({
    required this.firstStream,
    required this.secondStream,
    required this.valueBuilder,
    required this.titleBuilder,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: firstStream,
      builder: (context, firstSnap) {
        final first = firstSnap.data ?? 0;

        return StreamBuilder<int>(
          stream: secondStream,
          builder: (context, secondSnap) {
            final second = secondSnap.data ?? 0;

            return _StatCard(
              value: valueBuilder(first, second),
              label: titleBuilder(first, second),
              icon: icon,
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.orange,
            size: 21,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}