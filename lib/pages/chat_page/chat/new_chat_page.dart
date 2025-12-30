import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import 'chat_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {

  final _userRepo = UserRepository();

  final _searchCtrl = TextEditingController();
  String _search = "";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    final query = _userRepo.usersQuery(search: _search, limit: 25);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Neuer Chat"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "User suchen…",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          Expanded(
            child: FirestoreListView<Map<String, dynamic>>(
              query: query,
              itemBuilder: (context, doc) {

                final user = UserDto.fromMap(doc.data(), id: doc.id);

                // sich selbst nicht anzeigen
                if (user.userid == myUid) return const SizedBox.shrink();

                final pic = user.profilePictureUrl ?? "";
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
                    child: pic.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    user.benutzername ?? "User",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    [
                      (user.vorname ?? "").trim(),
                      (user.nachname ?? "").trim(),
                    ].where((s) => s.isNotEmpty).join(" ").isNotEmpty
                        ? [
                      (user.vorname ?? "").trim(),
                      (user.nachname ?? "").trim(),
                    ].where((s) => s.isNotEmpty).join(" ")
                        : " ",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  onTap: () async {
                    final me = await _userRepo.getUserDetailsDto(myUid);
                    if (!mounted) return;
                    if (me == null) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          chatId: null,      // ✅ noch kein Chat!
                          me: me,
                          other: user,
                        ),
                      ),
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
