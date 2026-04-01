
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/PostDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../user_info_page/UserInfoPage.dart';

class PostBesitzerWidget extends StatefulWidget {
  final PostDto post;

  /// ✅ aktueller Viewer (der das Video gerade anschaut)
  final UserDto viewerData;

  final VoidCallback onTapped;

  // ✅ Streams von außen
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

  late Color _containerColor;
  bool canInteract = true;
  UserDto? owner;

  @override
  void initState() {
    super.initState();
    _containerColor = (_isUploader() ? Colors.white30 : Colors.white12);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleOwnerTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        margin: const EdgeInsets.symmetric(vertical: 0),
        decoration: BoxDecoration(
          color: _containerColor,
          border: const Border.symmetric(horizontal: BorderSide(color: Colors.red)),
        ),
        child: StreamBuilder<UserDto?>(
          stream: widget.ownerStream,
          builder: (context, ownerSnap) {
            owner = ownerSnap.data;

            // loading owner
            if (ownerSnap.connectionState == ConnectionState.waiting) {
/*              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              );*/
            }

            // owner error
            if (ownerSnap.hasError) {
              return Text(
                "Fehler beim Laden des Besitzers: ${ownerSnap.error}",
                style: const TextStyle(color: Colors.red),
              );
            }

            // owner not found → fallback auf VideoDto Daten
            final String displayVorname = owner?.vorname ?? widget.post.vorname;
            final String displayNachname = owner?.nachname ?? widget.post.nachname;
            final String displayRole = owner?.role ?? widget.post.role;
            final String displayProfilePicture =
                owner?.profilePictureUrl ?? widget.post.profilePictureUrl;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(120),
                        child: Image.network(
                          displayProfilePicture,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              "assets/images/page/empty.png",
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            );
                          },
                        ),
                      ),
                    ),

                    // Name + Counts
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // ✅ wichtig
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "$displayVorname $displayNachname",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.1,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.start,
                                    softWrap: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                HelperUtil.getUserIcon(displayRole),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    StreamBuilder<int>(
                                      stream: widget.ownerVideoCountStream,
                                      builder: (context, vSnap) {
                                        final c = vSnap.data ?? 0;
                                        return Text(
                                          c == 1 ? "$c Video" : "$c Videos",
                                          style: const TextStyle(fontSize: 15, height: 1.1, color: Colors.grey),
                                        );
                                      },
                                    ),
                                    const Text("|", style: TextStyle(fontSize: 15, height: 1.1, color: Colors.grey)),
                                    StreamBuilder<int>(
                                      stream: widget.ownerImageCountStream,
                                      builder: (context, iSnap) {
                                        final c = iSnap.data ?? 0;
                                        return Text(
                                          c == 1 ? "$c Bild" : "$c Bilder",
                                          style: const TextStyle(fontSize: 15, height: 1.1, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                StreamBuilder<int>(
                                  stream: widget.ownerSubscriberCountStream,
                                  builder: (context, sSnap) {
                                    final c = sSnap.data ?? 0;
                                    return Text(
                                      c == 1 ? "$c Abonnent" : "$c Abonnenten",
                                      style: const TextStyle(fontSize: 15, height: 1.1, color: Colors.grey),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),

                // Button nur wenn nicht uploader
                if (!_isUploader())
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: StreamBuilder<bool>(
                      stream: widget.isSubscribedStream,
                      builder: (context, subSnap) {

                        final subscribed = subSnap.data ?? false;

                        if (!canInteract) {
                          return const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          );
                        }

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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  subscribed ? Icons.check_outlined : Icons.add_alert_outlined,
                                  size: 25,
                                  color: subscribed ? Colors.green : Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  subscribed ? "Abboniert" : "Abbonieren",
                                  softWrap: true,
                                  style: const TextStyle(
                                    height: 0,
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _isUploader() {
    return widget.viewerData.userid == widget.post.userid;
  }

  Future<void> _handleOwnerTap() async {
    // kurzer "click" Effekt
    if (!mounted) return;
    setState(() => _containerColor = Colors.orange);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _containerColor = (_isUploader() ? Colors.white30 : Colors.white12);
      });
    });

    if (_isUploader()) return;

    widget.onTapped();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserInfoPage(
            userID: widget.post.userid,
            viewerID: widget.viewerData.userid!
        ),
      ),
    );
  }

  Future<void> _toggleAbo(bool subscribed) async {
    if (!canInteract) return;

    setState(() => canInteract = false);

    final viewerId = widget.viewerData.userid!;
    final targetId = owner?.userid;

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
              "Du hast ${owner?.vorname} ${owner?.nachname} deabboniert!",
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
          'benutzername': owner?.benutzername,
          'vorname': owner?.vorname,
          'nachname': owner?.nachname,
          'profilePictureUrl': owner?.profilePictureUrl,
          'role': owner?.role,
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
              "Du hast ${owner?.vorname} ${owner?.nachname} abboniert!",
            ),

          );
        }
      }
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Abbonieren:\n$e",
        ),

      );
    } finally {
      if (!mounted) return;
      setState(() => canInteract = true);
    }
  }

}

