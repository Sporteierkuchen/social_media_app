
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/SubscriptionDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../user_info_page/UserInfoPage.dart';

class AbboniertWidget extends StatefulWidget {
  final SubscriptionDto abbonent;
  final UserDto viewerData;
  final UserRepository userRepository;

  final void Function(String text, Meldungsart art)? onMessage;

  const AbboniertWidget({
    super.key,
    required this.abbonent,
    required this.viewerData,
    required this.userRepository,
    this.onMessage,
  });

  @override
  State<AbboniertWidget> createState() => _AbboniertWidgetState();
}

class _AbboniertWidgetState extends State<AbboniertWidget> {
  bool canInteract = true;

  @override
  Widget build(BuildContext context) {

    final targetId = widget.abbonent.subscribedToId;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserInfoPage(
              userID: targetId,
              viewerID: widget.viewerData.userid!,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Profilbild
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(120),
                child: Image.network(
                  widget.abbonent.subscriberToProfilePic,
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      "assets/images/page/empty.png",
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                    );
                  },
                ),
              ),
            ),

            // Name / Vorname Nachname
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 12,
                  left: 15,
                  right: 5,
                ),
                child: Column(
                  children: [

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.abbonent.subscriberToName,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${widget.abbonent.subscriberToVorname} ${widget.abbonent.subscriberToNachname}",
                              style: const TextStyle(
                                fontSize: 14,
                                height: 0,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Role Icon
            Padding(
              padding: const EdgeInsets.only(
                  top: 12, bottom: 12, right: 10, left: 3),
              child: HelperUtil.getUserIcon(widget.abbonent.subscriberToRole),
            ),

            // Subscribe Button
            !_isSelf(targetId)
                ? Expanded(
              flex: 45,
              child: StreamBuilder<bool>(
                stream: widget.userRepository.isSubscribedStream(
                  viewerId: widget.viewerData.userid!,
                  targetId: targetId,
                ),
                builder: (context, snap) {

                  final subscribed = snap.data ?? false;

                  if (snap.connectionState ==
                      ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        ),
                      ),
                    );
                  }

                  return canInteract
                      ? Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    child: GestureDetector(
                      onTap: () async {
                        await _toggleAbo(
                            subscribed: subscribed,
                            targetId: targetId);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: subscribed
                              ? Colors.black
                              : Colors.indigo[900],
                          border: subscribed
                              ? Border.all(
                              color: Colors.white, width: 1)
                              : Border.all(
                              color: Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 8),
                        child: Text(
                          subscribed
                              ? "Deabbonieren"
                              : "Abbonieren",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                      : const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      ),
                    ),
                  );
                },
              ),
            )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  bool _isSelf(String targetId) {
    return widget.viewerData.userid == targetId;
  }

  Future<void> _toggleAbo({
    required bool subscribed,
    required String targetId,
  }) async {

    if (!canInteract) return;

    setState(() => canInteract = false);

    final viewerId = widget.viewerData.userid!;

    final vorname = widget.abbonent.subscriberToVorname;
    final nachname = widget.abbonent.subscriberToNachname;
    final benutzername = widget.abbonent.subscriberToName;
    final profilePic = widget.abbonent.subscriberToProfilePic;
    final role = widget.abbonent.subscriberToRole;

    try {

      if (subscribed) {

        final success = await widget.userRepository.unsubscribe(
          viewerId: viewerId,
          userId: targetId,
        );

        if (success) {
          widget.onMessage?.call(
            "Du hast $vorname $nachname deabboniert!",
            Meldungsart.INFO,
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
          'benutzername': benutzername,
          'vorname': vorname,
          'nachname': nachname,
          'profilePictureUrl': profilePic,
          'role': role,
        };

        final success = await widget.userRepository.subscribe(
          viewerId: viewerId,
          userId: targetId,
          viewerData: viewerDataMap,
          userData: targetDataMap,
        );

        if (success) {
          widget.onMessage?.call(
            "Du hast $vorname $nachname abboniert!",
            Meldungsart.SUCCESS,
          );
        }
      }

    } catch (e) {

      widget.onMessage?.call(
        "Fehler beim Abbonieren:\n$e",
        Meldungsart.ERROR,
      );

    } finally {

      if (!mounted) return;
      setState(() => canInteract = true);

    }
  }
}