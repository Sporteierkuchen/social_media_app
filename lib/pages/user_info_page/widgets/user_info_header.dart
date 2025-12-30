
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';

class UserInfoHeader extends StatefulWidget {
  // ✅ Streams von außen
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

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 10, right: 10, top: 40, bottom: 20),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/page/egon3.jpg"),
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
              child: (widget.userData.profilePictureUrl != null &&
                  widget.userData.profilePictureUrl!.isNotEmpty)
                  ? Image.network(
                widget.userData.profilePictureUrl!,
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
                  "${widget.userData.vorname ?? ''} ${widget.userData.nachname ?? ''}",
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
            child: HelperUtil.getUserIcon(widget.userData.role ?? "USER"),
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
                  stream: widget.videoCountStream,
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
                  stream: widget.imageCountStream,
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
                  stream: widget.videoCountStream,
                  builder: (context, vSnap) {
                    final v = vSnap.data ?? 0;
                    return StreamBuilder<int>(
                      stream: widget.imageCountStream,
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
                  stream: widget.videoViewsStream,
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
                  stream: widget.imageViewsStream,
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
                  stream: widget.videoViewsStream,
                  builder: (context, vSnap) {
                    final v = vSnap.data ?? 0;
                    return StreamBuilder<int>(
                      stream: widget.imageViewsStream,
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
          // Abonnenten (bleibt)
          // ------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 15, right: 15, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder<int>(
                  stream: widget.subscribersCountStream,
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

          // ------------------------------------------------------------
          // Abo Button
          // ------------------------------------------------------------
          Align(
            alignment: Alignment.centerRight,
            child: canInteract
                ? Padding(
              padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
              child: StreamBuilder<bool>(
                stream: widget.isSubscribedStream,
                builder: (context, snap) {
                  final subscribed = snap.data ?? false;

                  return GestureDetector(
                    onTap: () async {
                      await _toggleAbo(subscribed);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.black,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            subscribed ? Icons.check_outlined : Icons.add_alert_outlined,
                            size: 25,
                            color: subscribed ? Colors.green : Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            subscribed ? "Abboniert" : "Abbonieren",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
                : const Padding(
              padding: EdgeInsets.only(top: 20, right: 10),
              child: SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
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
              "Du hast ${widget.userData.vorname} ${widget.userData.nachname} deabboniert!",
            ),
            context: context,
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
              "Du hast ${widget.userData.vorname} ${widget.userData.nachname} abboniert!",
            ),
            context: context,
          );
        }
      }
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Abbonieren:\n$e",
        ),
        context: context,
      );
    } finally {
      if (!mounted) return;
      setState(() => canInteract = true);
    }
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
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}