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
  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<String> searchValue = ValueNotifier<String>("");

  @override
  void dispose() {
    searchController.dispose();
    searchValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: searchValue,
      builder: (context, search, _) {
        final query = widget.userRepository.usersQuery(
          search: search,
          limit: widget.pageSize,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 40, bottom: 14),
              child: Text(
                "Benutzerübersicht",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  maxLength: 25,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => searchValue.value = value.trim(),
                  onSubmitted: (value) => searchValue.value = value.trim(),
                  decoration: InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    prefixIcon: const Icon(
                      Icons.search_outlined,
                      color: Colors.black,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        searchController.clear();
                        searchValue.value = "";
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                    )
                        : null,
                    hintText: "Suche nach Benutzern...",
                    hintStyle: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),

            FirestoreQueryBuilder<Map<String, dynamic>>(
              query: query,
              pageSize: widget.pageSize,
              builder: (context, snapshot, _) {
                if (snapshot.isFetching && snapshot.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
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
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      "Keine Benutzer gefunden.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.docs.length + 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (index == snapshot.docs.length) {
                      if (!snapshot.hasMore) {
                        return const SizedBox(height: 10);
                      }

                      if (snapshot.isFetchingMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 10),
                          child: TextButton(
                            onPressed: snapshot.fetchMore,
                            child: const Text(
                              "Mehr laden",
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ),
                      );
                    }

                    final doc = snapshot.docs[index];
                    final user = UserDto.fromSnapshot(doc);

                    return UserWidget(
                      key: ValueKey(doc.id),
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