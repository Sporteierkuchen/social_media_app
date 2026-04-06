import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../user_info_page/UserInfoPage.dart';

class UserWidget extends StatefulWidget {
  final UserDto user;
  final UserDto viewerData;
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

  String get _targetId => widget.user.userid ?? "";

  String get _profileImageUrl =>
      (widget.user.profilePictureUrl ?? '').trim();

  String get _displayName {
    final value = (widget.user.benutzername ?? '').trim();
    return value.isNotEmpty ? value : "Unbekannter Nutzer";
  }

  String get _realName {
    return "${widget.user.vorname ?? ""} ${widget.user.nachname ?? ""}".trim();
  }

  @override
  Widget build(BuildContext context) {
    final viewerId = widget.viewerData.userid;

    if (_targetId.isEmpty || viewerId == null) {
      return const SizedBox.shrink();
    }

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
          onTap: _isUploader()
              ? null
              : () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserInfoPage(
                  userID: _targetId,
                  viewerID: viewerId,
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
                if (!_isUploader()) ...[
                  const SizedBox(width: 8),
                  _buildSubscribeButton(viewerId),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (_isUploader()) {
      return content;
    }

    return StreamBuilder<bool>(
      stream: widget.userRepository.isSubscribedStream(
        viewerId: viewerId,
        targetId: _targetId,
      ),
      builder: (context, snap) {
        final subscribed = snap.data ?? false;

        return Dismissible(
          key: ValueKey("user_${_targetId}"),
          direction:
          subscribed ? DismissDirection.endToStart : DismissDirection.none,
          confirmDismiss: (direction) async {
            if (!subscribed || !canInteract) return false;

            await _toggleAbo(true);
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
        child: HelperUtil.getUserIcon(widget.user.role ?? ""),
      ),
    );
  }

  Widget _buildSubscribeButton(String viewerId) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 100,
        maxWidth: 118,
      ),
      child: StreamBuilder<bool>(
        stream: widget.userRepository.isSubscribedStream(
          viewerId: viewerId,
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
            onTap: () async => _toggleAbo(subscribed),
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
              text:
              "Du hast ${widget.user.vorname ?? ""} ${widget.user.nachname ?? ""} deabonniert!",
            ),
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

        final userDataMap = {
          'benutzername': widget.user.benutzername ?? '',
          'vorname': widget.user.vorname ?? '',
          'nachname': widget.user.nachname ?? '',
          'profilePictureUrl': (widget.user.profilePictureUrl ?? '').trim(),
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
              text:
              "Du hast ${widget.user.vorname ?? ""} ${widget.user.nachname ?? ""} abonniert!",
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