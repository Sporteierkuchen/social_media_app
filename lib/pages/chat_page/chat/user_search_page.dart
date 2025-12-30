

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/chat_repository.dart';
import '../../../repositories/user_repository.dart';
import 'chat_page.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _userRepo = UserRepository();
  final _chatRepo = ChatRepository();
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("User suchen"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _c,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Benutzername...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<UserDto>>(
              // falls du so eine methode nicht hast: sag kurz, ich bau sie dir
              stream:  _userRepo.searchUsersStream(search: _c.text.trim(), limit: 30),
              builder: (context, snap) {
                final users = snap.data ?? [];
                final filtered = users.where((u) => u.userid != myUid).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text("Keine Treffer", style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final u = filtered[i];
                    return ListTile(
                      title: Text(u.benutzername ?? "", style: const TextStyle(color: Colors.white)),
                      subtitle: Text(u.email ?? "", style: const TextStyle(color: Colors.white70)),
                      onTap: () async {
                        final chatId = await _chatRepo.getOrCreateChatId(
                          myUid: myUid,
                          otherUid: u.userid!,
                        );
                        final me = await _userRepo.getUserDetailsDto(myUid);
                        if (me == null) return;

                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(chatId: chatId, me: me, other: u),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
