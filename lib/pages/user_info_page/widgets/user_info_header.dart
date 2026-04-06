import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';

class UserInfoHeader extends StatefulWidget {
  final UserDto userData;
  final UserDto viewerData;

  final Stream<int> videoCountStream;
  final Stream<int> imageCountStream;
  final Stream<int> videoViewsStream;
  final Stream<int> imageViewsStream;
  final Stream<int> subscribersCountStream;
  final Stream<bool> isSubscribedStream;

  final UserRepository userRepository;

  const UserInfoHeader({
    super.key,
    required this.userData,
    required this.viewerData,
    required this.videoCountStream,
    required this.imageCountStream,
    required this.videoViewsStream,
    required this.imageViewsStream,
    required this.subscribersCountStream,
    required this.isSubscribedStream,
    required this.userRepository,
  });

  @override
  State<UserInfoHeader> createState() => _UserInfoHeaderState();
}

class _UserInfoHeaderState extends State<UserInfoHeader> {
  bool canInteract = true;

  String get _displayName {
    return "${widget.userData.vorname ?? ''} ${widget.userData.nachname ?? ''}"
        .trim();
  }

  String get _subTitle {
    if ((widget.userData.benutzername ?? '').trim().isNotEmpty) {
      return widget.userData.benutzername!.trim();
    }
    return _displayName;
  }

  bool get _hasProfileImage {
    return (widget.userData.profilePictureUrl ?? '').trim().isNotEmpty;
  }

  bool get _hasBackgroundImage {
    return (widget.userData.backgroundImageUrl ?? '').trim().isNotEmpty;
  }

  bool get _isOwnProfile {
    return widget.userData.userid == widget.viewerData.userid;
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
                          imageUrl: widget.userData.backgroundImageUrl!.trim(),
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
                      if (!_isOwnProfile)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: canInteract
                              ? StreamBuilder<bool>(
                            stream: widget.isSubscribedStream,
                            builder: (context, snap) {
                              final subscribed = snap.data ?? false;

                              return GestureDetector(
                                onTap: () async {
                                  await _toggleAbo(subscribed);
                                },
                                child: AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: subscribed
                                        ? Colors.black.withValues(alpha: 0.72)
                                        : Colors.orange.withValues(alpha: 0.95),
                                    borderRadius:
                                    BorderRadius.circular(16),
                                    border: Border.all(
                                      color: subscribed
                                          ? Colors.white24
                                          : Colors.orangeAccent,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.22),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        subscribed
                                            ? Icons.check_outlined
                                            : Icons.add_alert_outlined,
                                        size: 20,
                                        color: subscribed
                                            ? Colors.green
                                            : Colors.black,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        subscribed
                                            ? "Abonniert"
                                            : "Abonnieren",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: subscribed
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                              : Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
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
                                    imageUrl: widget
                                        .userData.profilePictureUrl!
                                        .trim(),
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
                                  child: HelperUtil.getUserIcon(
                                    widget.userData.role ?? "USER",
                                  ),
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
                              stream: widget.videoCountStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) => v == 1 ? "Video" : "Videos",
                              icon: Icons.play_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SingleStreamStatCard(
                              stream: widget.imageCountStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) => v == 1 ? "Bild" : "Bilder",
                              icon: Icons.image_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DualStreamStatCard(
                              firstStream: widget.videoCountStream,
                              secondStream: widget.imageCountStream,
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
                              stream: widget.videoViewsStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) =>
                              v == 1 ? "Video-Ansicht" : "Video-Ansichten",
                              icon: Icons.visibility_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SingleStreamStatCard(
                              stream: widget.imageViewsStream,
                              valueBuilder: (v) => "$v",
                              titleBuilder: (v) =>
                              v == 1 ? "Bild-Ansicht" : "Bild-Ansichten",
                              icon: Icons.photo_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DualStreamStatCard(
                              firstStream: widget.videoViewsStream,
                              secondStream: widget.imageViewsStream,
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
                              stream: widget.subscribersCountStream,
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

  Future<void> _toggleAbo(bool subscribed) async {
    if (!canInteract) return;

    setState(() => canInteract = false);

    final viewerId = widget.viewerData.userid!;
    final targetId = widget.userData.userid;

    try {
      if (subscribed) {
        final success = await widget.userRepository.unsubscribe(
          viewerId: viewerId,
          userId: targetId!,
        );

        if (success) {
          HelperUtil.getToast(
            meldung: Meldung(
              meldungsart: Meldungsart.INFO,
              text:
              "Du hast ${widget.userData.vorname} ${widget.userData.nachname} deabonniert!",
            ),
          );
        }
      } else {
        final viewerDataMap = {
          'benutzername': widget.viewerData.benutzername ?? '',
          'vorname': widget.viewerData.vorname ?? '',
          'nachname': widget.viewerData.nachname ?? '',
          'profilePictureUrl': widget.viewerData.profilePictureUrl ?? '',
          'role': widget.viewerData.role ?? 'USER',
        };

        final targetDataMap = {
          'benutzername': widget.userData.benutzername,
          'vorname': widget.userData.vorname,
          'nachname': widget.userData.nachname,
          'profilePictureUrl': widget.userData.profilePictureUrl,
          'role': widget.userData.role,
        };

        final success = await widget.userRepository.subscribe(
          viewerId: viewerId,
          userId: targetId!,
          viewerData: viewerDataMap,
          userData: targetDataMap,
        );

        if (success) {
          HelperUtil.getToast(
            meldung: Meldung(
              meldungsart: Meldungsart.SUCCESS,
              text:
              "Du hast ${widget.userData.vorname} ${widget.userData.nachname} abonniert!",
            ),
          );
        }
      }
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Abonnieren:\n$e",
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => canInteract = true);
    }
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