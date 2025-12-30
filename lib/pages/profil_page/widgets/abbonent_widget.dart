
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/SubscriptionDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../user_info_page/UserInfoPage.dart';

class AbbonentWidget extends StatefulWidget {
  final SubscriptionDto abbonent;
  final UserDto viewerData;
  final UserRepository userRepository;

  const AbbonentWidget({
    super.key,
    required this.abbonent,
    required this.viewerData,
    required this.userRepository,
  });

  @override
  AbbonentWidgetState createState() => AbbonentWidgetState();
}

class AbbonentWidgetState extends State<AbbonentWidget> {

  bool canInteract = true;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        print("Ausgewählter Abbonent: ${widget.abbonent.subscriberName}");

        if (!_isUploader()) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserInfoPage(
                userID: widget.abbonent.subscriberId,
                viewerID: widget.viewerData.userid!
              ),
            ),
          );

        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(120),
                child: Image.network(
                  widget.abbonent.subscriberProfilePic,
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    // Leeres Bild oder alternative UI-Komponente im Fehlerfall anzeigen
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
                            widget.abbonent.subscriberName,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.start,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${widget.abbonent.subscriberVorname} ${widget.abbonent.subscriberNachname}",
                              style: const TextStyle(
                                fontSize: 14,
                                height: 0,
                                color: Colors.grey,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.start,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 12,
                right: 10,
                left: 3,
              ),
              child: Container(
                child: HelperUtil.getUserIcon(widget.abbonent.subscriberRole),
                // color: Colors.green,
              ),
            ),

            !_isUploader()
                ? Expanded(
              flex: 45,
              child: StreamBuilder<bool>(
                stream: widget.userRepository.isSubscribedStream(
                  viewerId: widget.viewerData.userid!,
                  targetId: widget.abbonent.subscriberId,
                ),
                builder: (context, snap) {
                  final subscribed = snap.data ?? false;

                  // optional: während der Stream noch lädt
                  if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        ),
                      ),
                    );
                  }

                  return
                    canInteract
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: GestureDetector(
                      onTap: () async {
                        await _toggleAbo(subscribed);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: subscribed ? Colors.black : Colors.indigo[900],
                          border: subscribed
                              ? Border.all(color: Colors.white, width: 1)
                              : Border.all(color: Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        child: Text(
                          subscribed ? "Deabbonieren" : "Abbonieren",
                          softWrap: true,
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),
                  );
                },
              ),
            )
                : Container(),
          ],
        ),
      ),
    );
  }

  bool _isUploader() {
    return widget.viewerData.userid == widget.abbonent.subscriberId;
  }

  Future<void> _toggleAbo(bool subscribed) async {
    if (!canInteract) return;

    setState(() => canInteract = false);

    final viewerId = widget.viewerData.userid!;
    final targetId = widget.abbonent.subscriberId;

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
              "Du hast ${widget.abbonent.subscriberVorname} ${widget.abbonent.subscriberNachname} deabboniert!",
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
          'benutzername': widget.abbonent.subscriberName,
          'vorname': widget.abbonent.subscriberVorname,
          'nachname': widget.abbonent.subscriberNachname,
          'profilePictureUrl': widget.abbonent.subscriberProfilePic,
          'role': widget.abbonent.subscriberRole,
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
              "Du hast ${widget.abbonent.subscriberVorname} ${widget.abbonent.subscriberNachname} abboniert!",
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
