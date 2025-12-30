
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import 'user_widget.dart';

class UserOverviewSection extends StatefulWidget {
  final UserRepository userRepository;

  final UserDto viewerData;

  final int pageSize;

  const UserOverviewSection({
    super.key,
    required this.userRepository,
    required this.viewerData,
    this.pageSize = 20,
  });

  @override
  State<UserOverviewSection> createState() => _UserOverviewSectionState();
}

class _UserOverviewSectionState extends State<UserOverviewSection> {

  final searchController = TextEditingController();
  final ValueNotifier<String> searchValue = ValueNotifier<String>("");

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: searchValue,
      builder: (context, search, _) {
        final query = widget.userRepository.usersQuery(search: search, limit: widget.pageSize);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 40, bottom: 20),
              child: Text(
                "Benutzerübersicht",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Suchfeld
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: SizedBox(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  textAlignVertical: TextAlignVertical.center,
                  maxLength: 25,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => searchValue.value = value,
                  onSubmitted: (value) => searchValue.value = value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    counterText: "",
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18.0)),
                      borderSide: BorderSide(color: Colors.orange, width: 2.0),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18.0)),
                      borderSide: BorderSide(color: Colors.grey, width: 2.0),
                    ),
                    prefixIcon: const Icon(Icons.search_outlined, color: Colors.black),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        searchController.clear();
                        searchValue.value = "";
                      },
                      child: const Icon(Icons.close_outlined, color: Colors.black, size: 20),
                    ),
                    hintText: "Suche...",
                  ),
                ),
              ),
            ),

            FirestoreQueryBuilder<Map<String, dynamic>>(
              query: query,
              pageSize: widget.pageSize,
              builder: (context, snapshot, _) {
                if (snapshot.isFetching && snapshot.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    "Fehler beim Laden: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  );
                }

                if (snapshot.docs.isEmpty) {
                  return const Text(
                    "Keine Benutzer gefunden.",
                    style: TextStyle(color: Colors.white70),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.docs.length + 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (index == snapshot.docs.length) {
                      if (!snapshot.hasMore) return const SizedBox(height: 20);

                      if (snapshot.isFetchingMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      }

                      return TextButton(
                        onPressed: snapshot.fetchMore,
                        child: const Text("Mehr laden", style: TextStyle(color: Colors.grey)),
                      );
                    }

                    final doc = snapshot.docs[index];
                    final user = UserDto.fromSnapshot(doc); // musst du evtl. so haben

                    return UserWidget(
                      user: user,
                      viewerData: widget.viewerData,
                      userRepository: widget.userRepository,

                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
