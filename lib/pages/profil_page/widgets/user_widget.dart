
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../user_info_page/UserInfoPage.dart';

class UserWidget extends StatefulWidget {
  final UserDto user;              // der User aus der Übersicht
  final UserDto viewerData;        // eingeloggter User
  final UserRepository userRepository;

  const UserWidget({
    super.key,
    required this.user,
    required this.viewerData,
    required this.userRepository,
  });

  @override
  State<UserWidget> createState() => UserWidgetState();
}

class UserWidgetState extends State<UserWidget> {
  bool canInteract = true;

  @override
  Widget build(BuildContext context) {
    final targetId = widget.user.userid;
    final viewerId = widget.viewerData.userid;

    // safety
    if (targetId == null || viewerId == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        if (_isUploader()) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserInfoPage(
              userID: targetId,
              viewerID: viewerId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Avatar ----
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(120),
                child: (widget.user.profilePictureUrl ?? "").trim().isNotEmpty
                    ? Image.network(
                  widget.user.profilePictureUrl!,
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  errorBuilder: (_, __, ___) => Image.asset(
                    "assets/images/page/empty.png",
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                  ),
                )
                    : Image.asset(
                  "assets/images/page/empty.png",
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                ),
              ),
            ),

            // ---- Name + Vor/Nachname ----
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12, left: 15, right: 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.user.benutzername ?? "",
                            style: const TextStyle(
                              fontSize: 15,
                              height: 0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true,
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
                              "${widget.user.vorname ?? ""} ${widget.user.nachname ?? ""}".trim(),
                              style: const TextStyle(
                                fontSize: 14,
                                height: 0,
                                color: Colors.grey,
                                fontWeight: FontWeight.normal,
                              ),
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

            // ---- Role Icon ----
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12, right: 10, left: 3),
              child: HelperUtil.getUserIcon(widget.user.role ?? ""),
            ),

            // ---- Abo Button (live) ----
            !_isUploader()
                ? Expanded(
              flex: 45,
              child: StreamBuilder<bool>(
                stream: widget.userRepository.isSubscribedStream(
                  viewerId: viewerId,
                  targetId: targetId,
                ),
                builder: (context, snap) {
                  final subscribed = snap.data ?? false;

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

                  return canInteract
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: GestureDetector(
                      onTap: () async => _toggleAbo(subscribed),
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
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  bool _isUploader() => widget.viewerData.userid == widget.user.userid;

  Future<void> _toggleAbo(bool subscribed) async {
    if (!canInteract) return;

    setState(() => canInteract = false);

    final viewerId = widget.viewerData.userid!;
    final targetId = widget.user.userid!;

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
              text: "Du hast ${widget.user.vorname ?? ""} ${widget.user.nachname ?? ""} deabboniert!",
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

        final userDataMap = {
          'benutzername': widget.user.benutzername ?? '',
          'vorname': widget.user.vorname ?? '',
          'nachname': widget.user.nachname ?? '',
          'profilePictureUrl': widget.user.profilePictureUrl ?? '',
          'role': widget.user.role ?? 'USER',
        };

        final success = await widget.userRepository.subscribe(
          viewerId: viewerId,
          userId: targetId,
          viewerData: viewerDataMap,
          userData: userDataMap,
        );

        if (success) {
          HelperUtil.getToast(
            meldung: Meldung(
              meldungsart: Meldungsart.SUCCESS,
              text: "Du hast ${widget.user.vorname ?? ""} ${widget.user.nachname ?? ""} abboniert!",
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
