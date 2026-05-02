import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/UserDto.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/chat_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/chat_state_service.dart';
import '../../../services/local_notification_service.dart';
import '../../user_info_page/UserInfoPage.dart';

class ChatPage extends StatefulWidget {
  static const String routeName = "chat_page";

  final String? chatId;
  final UserDto me;
  final UserDto other;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.me,
    required this.other,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final _chatRepo = ChatRepository();
  final _userRepo = UserRepository();
  final _textCtrl = TextEditingController();
  final _authRepo = AuthRepository();

  String? _chatId;
  bool _creatingChat = false;

  Timer? _markReadDebounce;
  bool _markReadInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _chatId = widget.chatId;

    if (_chatId != null && _chatId!.isNotEmpty) {
      _setActiveChat();
      _scheduleMarkRead();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await LocalNotificationService.clearChatNotifications(_chatId!);
        } catch (e, s) {
          debugPrint("[ChatPage] Fehler beim Löschen der Notifications: $e");
          debugPrint("$s");
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markReadDebounce?.cancel();

    _clearActiveChat();

    _textCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authRepo.currentUserId == null) return;

    if (state == AppLifecycleState.resumed) {
      _setActiveChat();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _clearActiveChat();
    }
  }

  Future<void> _setActiveChat() async {
    final uid = _authRepo.currentUserId;
    final cid = _chatId;

    if (uid == null || cid == null || cid.isEmpty) return;

    ChatStateService.currentOpenChatId = cid;

    try {
      await _chatRepo.setActiveChat(
        userId: uid,
        chatId: cid,
      );
    } catch (e) {
      debugPrint("Fehler beim Setzen des ActiveChats: $e");
    }
  }

  Future<void> _clearActiveChat() async {
    final uid = _authRepo.currentUserId;
    final cid = _chatId;

    if (uid == null) return;

    if (cid != null && ChatStateService.currentOpenChatId == cid) {
      ChatStateService.currentOpenChatId = null;
    }

    try {
      await _chatRepo.setActiveChat(
        userId: uid,
        chatId: null,
      );
    } catch (e) {
      debugPrint("Fehler beim ClearActiveChat: $e");
    }
  }

  void _scheduleMarkRead() {
    final cid = _chatId;
    if (cid == null) return;

    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (_markReadInFlight) return;
      _markReadInFlight = true;
      try {
        await _chatRepo.markChatAsRead(
          chatId: cid,
          myUid: widget.me.userid!,
        );
      } finally {
        _markReadInFlight = false;
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();

    if (_chatId == null) {
      if (_creatingChat) return;
      _creatingChat = true;

      try {
        _chatId = await _chatRepo.getOrCreateChat(
          myUid: widget.me.userid!,
          otherUid: widget.other.userid!,
        );
      } finally {
        _creatingChat = false;
      }

      if (!mounted) return;

      if (_chatId != null) {
        ChatStateService.currentOpenChatId = _chatId;
        await _setActiveChat();

        try {
          await LocalNotificationService.clearChatNotifications(_chatId!);
        } catch (e, s) {
          debugPrint("[ChatPage] Fehler beim Löschen der Notifications nach Chat-Erstellung: $e");
          debugPrint("$s");
        }
      }

      setState(() {});
    }

    await _chatRepo.sendMessage(
      chatId: _chatId!,
      senderId: widget.me.userid!,
      receiverId: widget.other.userid!,
      text: text,
    );

    _scheduleMarkRead();
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "…";
    final d = ts.toDate();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  DateTime? _dateOnlyFromTs(Timestamp? ts) {
    if (ts == null) return null;
    final d = ts.toDate();
    return DateTime(d.year, d.month, d.day);
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (_sameDay(day, today)) return "Heute";
    if (_sameDay(day, yesterday)) return "Gestern";

    final dd = day.day.toString().padLeft(2, '0');
    final mm = day.month.toString().padLeft(2, '0');
    final yyyy = day.year.toString();
    return "$dd.$mm.$yyyy";
  }

  String _lastSeenLabel(Timestamp? ts) {
    if (ts == null) return "zuletzt aktiv: …";
    final d = ts.toDate();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);

    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');

    if (day == today) return "zuletzt aktiv: $hh:$mm";

    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return "zuletzt aktiv: $dd.$mo. $hh:$mm";
  }

  @override
  Widget build(BuildContext context) {
    final cid = _chatId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: StreamBuilder<UserDto?>(
          stream: _userRepo.userStream(widget.other.userid!),
          builder: (context, snap) {
            final other = snap.data ?? widget.other;

            final isOnline = other.isOnline ?? false;
            final lastActiveAt = other.lastActiveAt;

            final otherName = other.benutzername ?? "Chat";
            final otherPic = other.profilePictureUrl ?? "";

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final uid = other.userid;
                  if (uid == null) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserInfoPage(
                        userID: uid,
                        viewerID: widget.me.userid!,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage:
                        otherPic.isNotEmpty ? NetworkImage(otherPic) : null,
                        child: otherPic.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            otherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOnline ? "online" : _lastSeenLabel(lastActiveAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.orange : Colors.white54,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: cid == null
                ? _EmptyChatHint(
              otherName: widget.other.benutzername ?? "User",
              creating: _creatingChat,
            )
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _chatRepo.chatDocStream(cid),
              builder: (context, chatSnap) {
                final chatData = chatSnap.data?.data() ?? {};
                final lastReadAtMap =
                    (chatData["lastReadAtMap"] as Map?)
                        ?.cast<String, dynamic>() ??
                        {};

                final otherLastReadTs =
                lastReadAtMap[widget.other.userid] as Timestamp?;
                final otherLastReadAt = otherLastReadTs?.toDate();

                return FirestoreQueryBuilder<Map<String, dynamic>>(
                  query: _chatRepo.messagesQuery(cid),
                  pageSize: 50,
                  builder: (context, snap, _) {
                    if (snap.hasError) {
                      return const Center(
                        child: Text(
                          "Fehler beim Laden",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (snap.isFetching && snap.docs.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    }

                    final docs = snap.docs;

                    if (docs.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _scheduleMarkRead();
                      });
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      reverse: true,
                      itemCount: docs.length + (snap.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (snap.hasMore && index == docs.length) {
                          snap.fetchMore();
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }

                        final doc = docs[index];
                        final data = doc.data();

                        final isMe = data["senderId"] == widget.me.userid;
                        final text = (data["text"] ?? "").toString();
                        final createdAt = data["createdAt"] as Timestamp?;

                        final thisDay = _dateOnlyFromTs(createdAt);

                        DateTime? olderDay;
                        if (index + 1 < docs.length) {
                          final olderData = docs[index + 1].data();
                          final olderTs =
                          olderData["createdAt"] as Timestamp?;
                          olderDay = _dateOnlyFromTs(olderTs);
                        }

                        final showDayHeader = (thisDay != null) &&
                            (index == docs.length - 1 ||
                                !_sameDay(thisDay, olderDay));

                        final msgTime = createdAt?.toDate();

                        final isReadByOther = isMe &&
                            msgTime != null &&
                            otherLastReadAt != null &&
                            !otherLastReadAt.isBefore(msgTime);

                        final isDelivered = isMe && createdAt != null;

                        return Column(
                          children: [
                            if (showDayHeader) ...[
                              _DayHeader(label: _dayLabel(thisDay)),
                              const SizedBox(height: 6),
                            ],
                            _ChatBubble(
                              isMe: isMe,
                              text: text,
                              timeLabel: _formatTime(createdAt),
                              otherName:
                              widget.other.benutzername ?? "User",
                              otherPic:
                              widget.other.profilePictureUrl ?? "",
                              showTicks: isMe,
                              delivered: isDelivered,
                              read: isReadByOther,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade900, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _textCtrl,
                        style: const TextStyle(color: Colors.white),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: "Nachricht schreiben…",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SendButton(
                    enabled: !_creatingChat,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;

  const _DayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String timeLabel;
  final String otherName;
  final String otherPic;
  final bool showTicks;
  final bool delivered;
  final bool read;

  const _ChatBubble({
    required this.isMe,
    required this.text,
    required this.timeLabel,
    required this.otherName,
    required this.otherPic,
    required this.showTicks,
    required this.delivered,
    required this.read,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.74;

    final bubbleColor = isMe ? Colors.orange.shade700 : Colors.grey.shade900;
    final borderColor = isMe ? Colors.orange.shade600 : Colors.grey.shade800;

    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final margin = isMe
        ? const EdgeInsets.fromLTRB(60, 6, 0, 6)
        : const EdgeInsets.fromLTRB(0, 6, 60, 6);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    Widget buildTicks() {
      if (!delivered) return const SizedBox.shrink();

      return Icon(
        Icons.done_all,
        size: 16,
        color: read ? Colors.lightBlueAccent : Colors.white70,
      );
    }

    return Align(
      alignment: align,
      child: Container(
        margin: margin,
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage:
                      otherPic.isNotEmpty ? NetworkImage(otherPic) : null,
                      child: otherPic.isEmpty
                          ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 14,
                      )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      otherName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11,
                        ),
                      ),
                      if (showTicks) ...[
                        const SizedBox(width: 6),
                        buildTicks(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _SendButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? Colors.orange : Colors.grey.shade800,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onPressed : null,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.send, color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptyChatHint extends StatelessWidget {
  final String otherName;
  final bool creating;

  const _EmptyChatHint({
    required this.otherName,
    required this.creating,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              "Schreibe $otherName eine Nachricht,\num den Chat zu starten.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.25),
            ),
            if (creating) ...[
              const SizedBox(height: 14),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}