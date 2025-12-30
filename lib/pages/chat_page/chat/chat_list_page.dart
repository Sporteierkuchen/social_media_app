import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/pages/chat_page/chat/presence_observer.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/chat_repository.dart';
import '../../../repositories/user_repository.dart';
import 'chat_page.dart';
import 'new_chat_page.dart';

class ChatListPage extends StatelessWidget {

  final ChatRepository _chatRepo = ChatRepository();
  final UserRepository _userRepo = UserRepository();
  final AuthRepository _authRepo = AuthRepository();

  ChatListPage({super.key});

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "";
    final d = ts.toDate();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  @override
  Widget build(BuildContext context) {

    final myUid = _authRepo.currentUserId;

    return PresenceObserver(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Chats"),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewChatPage()),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _chatRepo.myChatsQuery(myUid!).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                child: Text(
                  "Fehler beim Laden",
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            if (!snap.hasData) return const SizedBox.shrink();

            final chats = snap.data!.docs;
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  "Noch keine Chats",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade900,
              ),
              itemBuilder: (context, i) {
                final data = chats[i].data();

                final participants = (data['participants'] as List).cast<String>();
                final otherUid = participants.firstWhere((u) => u != myUid);

                final lastMessage = (data['lastMessage'] ?? "") as String;
                final lastMessageAt = data['lastMessageAt'] as Timestamp?;
                final lastSenderId = (data['lastSenderId'] ?? "") as String;

                final lastReadAtMap =
                    (data['lastReadAtMap'] as Map?)?.cast<String, dynamic>() ?? {};
                final otherReadAt = lastReadAtMap[otherUid] as Timestamp?;

                final unreadCounts =
                    (data['unreadCounts'] as Map?)?.cast<String, dynamic>() ?? {};
                final unread = (unreadCounts[myUid] ?? 0) as int;

                // ✅ WhatsApp-Style: Badge eher nur wenn letzte Nachricht nicht von mir kam
                final showUnread = unread > 0 && lastSenderId != myUid;

                return StreamBuilder<UserDto?>(
                  stream: _userRepo.userStream(otherUid),
                  builder: (context, userSnap) {
                    final other = userSnap.data;

                    final pic = other?.profilePictureUrl ?? "";
                    final username = other?.benutzername ?? "User";

                    return ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
                        child: pic.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          _TickPreview(
                            show: lastSenderId == myUid,
                            lastMessageAt: lastMessageAt,
                            otherReadAt: otherReadAt,
                          ),
                          Expanded(
                            child: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastMessageAt != null)
                            Text(
                              _formatTime(lastMessageAt),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          const SizedBox(height: 6),
                          if (showUnread) _UnreadBadge(count: unread),
                        ],
                      ),
                      onTap: () async {
                        final chatId = chats[i].id;

                        final me = await _userRepo.getUserDetailsDto(myUid);
                        if (me == null || other == null) return;
                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              chatId: chatId,
                              me: me,
                              other: other,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? "99+" : "$count";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        display,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TickPreview extends StatelessWidget {
  final bool show;
  final Timestamp? lastMessageAt;
  final Timestamp? otherReadAt;

  const _TickPreview({
    required this.show,
    required this.lastMessageAt,
    required this.otherReadAt,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    // ✅ otherReadAt >= lastMessageAt
    final bool read = (lastMessageAt != null &&
        otherReadAt != null &&
        !otherReadAt!.toDate().isBefore(lastMessageAt!.toDate()));

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Icon(
        Icons.done_all,
        size: 18,
        color: read ? Colors.lightBlueAccent : Colors.white38,
      ),
    );
  }
}
