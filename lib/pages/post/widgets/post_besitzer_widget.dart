import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../models/PostDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../user_info_page/UserInfoPage.dart';

class PostBesitzerWidget extends StatefulWidget {
  final PostDto post;
  final UserDto viewerData;
  final VoidCallback onTapped;

  final Stream<UserDto?> ownerStream;
  final Stream<int> ownerVideoCountStream;
  final Stream<int> ownerImageCountStream;
  final Stream<int> ownerSubscriberCountStream;
  final Stream<bool> isSubscribedStream;
  final UserRepository userRepository;

  const PostBesitzerWidget({
    super.key,
    required this.post,
    required this.viewerData,
    required this.onTapped,
    required this.ownerStream,
    required this.ownerVideoCountStream,
    required this.ownerImageCountStream,
    required this.ownerSubscriberCountStream,
    required this.isSubscribedStream,
    required this.userRepository,
  });

  @override
  State<PostBesitzerWidget> createState() => _PostBesitzerWidgetState();
}

class _PostBesitzerWidgetState extends State<PostBesitzerWidget> {
  bool canInteract = true;

  bool _isUploader() {
    return widget.viewerData.userid == widget.post.userid;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserDto?>(
      stream: widget.ownerStream,
      builder: (context, ownerSnap) {
        if (ownerSnap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              "Fehler beim Laden des Besitzers: ${ownerSnap.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final owner = ownerSnap.data;

        final String displayVorname = owner?.vorname ?? widget.post.vorname;
        final String displayNachname = owner?.nachname ?? widget.post.nachname;
        final String displayRole = owner?.role ?? widget.post.role;
        final String displayProfilePicture =
            owner?.profilePictureUrl ?? widget.post.profilePictureUrl;
        final String displayUsername =
        (owner?.benutzername ?? '').trim().isNotEmpty
            ? owner!.benutzername!.trim()
            : "$displayVorname $displayNachname";

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _handleOwnerTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  border: Border.all(
                    color: Colors.white38,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _OwnerAvatar(
                      imageUrl: displayProfilePicture,
                      size: 72,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "$displayVorname $displayNachname".trim(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              HelperUtil.getUserIcon(displayRole),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            displayUsername,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              StreamBuilder<int>(
                                stream: widget.ownerVideoCountStream,
                                builder: (context, snap) {
                                  final c = snap.data ?? 0;
                                  return _MiniInfoText(
                                    text: c == 1 ? "1 Video" : "$c Videos",
                                  );
                                },
                              ),
                              StreamBuilder<int>(
                                stream: widget.ownerImageCountStream,
                                builder: (context, snap) {
                                  final c = snap.data ?? 0;
                                  return _MiniInfoText(
                                    text: c == 1 ? "1 Bild" : "$c Bilder",
                                  );
                                },
                              ),
                              StreamBuilder<int>(
                                stream: widget.ownerSubscriberCountStream,
                                builder: (context, snap) {
                                  final c = snap.data ?? 0;
                                  return _MiniInfoText(
                                    text: c == 1 ? "1 Abo" : "$c Abos",
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!_isUploader()) ...[
                      const SizedBox(width: 12),
                      StreamBuilder<bool>(
                        stream: widget.isSubscribedStream,
                        builder: (context, subSnap) {
                          final subscribed = subSnap.data ?? false;

                          if (!canInteract) {
                            return const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () async {
                              await _toggleAbo(
                                subscribed: subscribed,
                                owner: owner,
                                fallbackVorname: displayVorname,
                                fallbackNachname: displayNachname,
                                fallbackRole: displayRole,
                                fallbackProfilePicture: displayProfilePicture,
                                fallbackUsername: displayUsername,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: subscribed ? Colors.black : Colors.orange,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: subscribed
                                      ? Colors.white38
                                      : Colors.orangeAccent,
                                  width: 1.3,
                                ),
                              ),
                              child: Icon(
                                subscribed
                                    ? Icons.check_outlined
                                    : Icons.add,
                                size: 20,
                                color: subscribed ? Colors.green : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleOwnerTap() async {
    if (_isUploader()) return;

    widget.onTapped();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserInfoPage(
          userID: widget.post.userid,
          viewerID: widget.viewerData.userid!,
        ),
      ),
    );
  }

  Future<void> _toggleAbo({
    required bool subscribed,
    required UserDto? owner,
    required String fallbackVorname,
    required String fallbackNachname,
    required String fallbackRole,
    required String fallbackProfilePicture,
    required String fallbackUsername,
  }) async {
    if (!canInteract) return;

    setState(() => canInteract = false);

    final viewerId = widget.viewerData.userid!;
    final targetId = owner?.userid ?? widget.post.userid;

    try {
      if (subscribed) {
        final success = await widget.userRepository.unsubscribe(
          viewerId: viewerId,
          userId: targetId,
        );

        if (success) {
          HelperUtil.getToast(
            meldung: Meldung(
              meldungsart: Meldungsart.INFO,
              text:
              "Du hast ${owner?.vorname ?? fallbackVorname} ${owner?.nachname ?? fallbackNachname} deabonniert!",
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
          'benutzername': owner?.benutzername ?? fallbackUsername,
          'vorname': owner?.vorname ?? fallbackVorname,
          'nachname': owner?.nachname ?? fallbackNachname,
          'profilePictureUrl':
          owner?.profilePictureUrl ?? fallbackProfilePicture,
          'role': owner?.role ?? fallbackRole,
        };

        final success = await widget.userRepository.subscribe(
          viewerId: viewerId,
          userId: targetId,
          viewerData: viewerDataMap,
          userData: targetDataMap,
        );

        if (success) {
          HelperUtil.getToast(
            meldung: Meldung(
              meldungsart: Meldungsart.SUCCESS,
              text:
              "Du hast ${owner?.vorname ?? fallbackVorname} ${owner?.nachname ?? fallbackNachname} abonniert!",
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

class _OwnerAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _OwnerAvatar({
    required this.imageUrl,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.8),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Image.asset(
            "assets/images/page/empty.png",
            fit: BoxFit.cover,
          ),
          errorWidget: (context, url, error) => Image.asset(
            "assets/images/page/empty.png",
            fit: BoxFit.cover,
          ),
        )
            : Image.asset(
          "assets/images/page/empty.png",
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _MiniInfoText extends StatelessWidget {
  final String text;

  const _MiniInfoText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        color: Colors.white60,
        fontWeight: FontWeight.w500,
        height: 1.15,
      ),
    );
  }
}