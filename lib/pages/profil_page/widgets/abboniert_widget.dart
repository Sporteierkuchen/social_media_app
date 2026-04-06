import 'package:cached_network_image/cached_network_image.dart';
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

  String get _targetId => widget.abbonent.subscribedToId;

  String get _profileImageUrl =>
      widget.abbonent.subscriberToProfilePic.trim();

  String get _displayName {
    final value = widget.abbonent.subscriberToName.trim();
    return value.isNotEmpty ? value : "Unbekannter Nutzer";
  }

  String get _realName {
    return "${widget.abbonent.subscriberToVorname} ${widget.abbonent.subscriberToNachname}"
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserInfoPage(
                  userID: _targetId,
                  viewerID: widget.viewerData.userid!,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNameSection(),
                ),
                const SizedBox(width: 8),
                _buildRoleIcon(),
                if (!_isSelf(_targetId)) ...[
                  const SizedBox(width: 8),
                  _buildSubscribeButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (_isSelf(_targetId)) {
      return content;
    }

    return StreamBuilder<bool>(
      stream: widget.userRepository.isSubscribedStream(
        viewerId: widget.viewerData.userid!,
        targetId: _targetId,
      ),
      builder: (context, snap) {
        final subscribed = snap.data ?? false;

        return Dismissible(
          key: ValueKey("subscribed_${widget.abbonent.subscribedToId}"),
          direction:
          subscribed ? DismissDirection.endToStart : DismissDirection.none,
          confirmDismiss: (direction) async {
            if (!subscribed || !canInteract) return false;

            await _toggleAbo(
              subscribed: true,
              targetId: _targetId,
            );
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.person_remove_alt_1, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Deabonnieren",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _profileImageUrl.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: _profileImageUrl,
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

  Widget _buildNameSection() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),

            ],
          ),
          const SizedBox(height: 4),
          Text(
            _realName.isNotEmpty ? _realName : "Kein Klarname",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleIcon() {
    return SizedBox(
      height: 24,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: HelperUtil.getUserIcon(widget.abbonent.subscriberToRole),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 100,
        maxWidth: 118,
      ),
      child: StreamBuilder<bool>(
        stream: widget.userRepository.isSubscribedStream(
          viewerId: widget.viewerData.userid!,
          targetId: _targetId,
        ),
        builder: (context, snap) {
          final subscribed = snap.data ?? false;

          if ((snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) ||
              !canInteract) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () async {
              await _toggleAbo(
                subscribed: subscribed,
                targetId: _targetId,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: subscribed ? Colors.black : Colors.orange,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: subscribed ? Colors.white24 : Colors.orangeAccent,
                ),
              ),
              child: Text(
                subscribed ? "Abonniert" : "Abonnieren",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: subscribed ? Colors.white : Colors.black,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
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
    final profilePic = widget.abbonent.subscriberToProfilePic.trim();
    final role = widget.abbonent.subscriberToRole;

    try {
      if (subscribed) {
        final success = await widget.userRepository.unsubscribe(
          viewerId: viewerId,
          userId: targetId,
        );

        if (success) {
          widget.onMessage?.call(
            "Du hast $vorname $nachname deabonniert!",
            Meldungsart.INFO,
          );
        }
      } else {
        final viewerDataMap = {
          'benutzername': widget.viewerData.benutzername ?? '',
          'vorname': widget.viewerData.vorname ?? '',
          'nachname': widget.viewerData.nachname ?? '',
          'profilePictureUrl':
          (widget.viewerData.profilePictureUrl ?? '').trim(),
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
            "Du hast $vorname $nachname abonniert!",
            Meldungsart.SUCCESS,
          );
        }
      }
    } catch (e) {
      widget.onMessage?.call(
        "Fehler beim Abonnieren:\n$e",
        Meldungsart.ERROR,
      );
    } finally {
      if (!mounted) return;
      setState(() => canInteract = true);
    }
  }
}