
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/SubscriptionDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import 'abboniert_widget.dart';

class SubscribedSection extends StatelessWidget {

  final UserDto userData;
  final UserRepository userRepository;

  // ✅ von außen
  final Query<Map<String, dynamic>> subscribedQuery;
  final Stream<int> subscribersCountStream;

  final int pageSize;


  const SubscribedSection({
    super.key,
    required this.userData,
    required this.subscribedQuery,
    required this.subscribersCountStream,
    this.pageSize = 15,
    required this.userRepository,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Titel + Live-Count ----
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 10),
          child: StreamBuilder<int>(
            stream: subscribersCountStream,
            builder: (context, snap) {
              final countText = snap.hasData ? "${snap.data}" : "…";
              return Text(
                "Abboniert ($countText)",
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),

        // ---- Realtime + Paging ----
        FirestoreQueryBuilder<Map<String, dynamic>>(
          query: subscribedQuery,
          pageSize: pageSize,
          builder: (context, snapshot, _) {
            if (snapshot.isFetching && snapshot.docs.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Text(
                "Fehler beim Laden Abos: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              );
            }
            if (snapshot.docs.isEmpty) {
              return const Text(
                "Noch nieamanden abboniert!.",
                style: TextStyle(color: Colors.white70),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.docs.length + 1,
              itemBuilder: (context, index) {
                // Load more row
                if (index == snapshot.docs.length) {
                  if (!snapshot.hasMore) return const SizedBox(height: 20);

                  if (snapshot.isFetchingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  }

                  return Center(
                    child: TextButton(
                      onPressed: snapshot.fetchMore,
                      child: const Text("Mehr laden"),
                    ),
                  );
                }

                final doc = snapshot.docs[index]; // QueryDocumentSnapshot<Map<String, dynamic>>
                final abbonent = SubscriptionDto.fromSnapshot(doc); // siehe unten

                return AbboniertWidget(
                  abbonent: abbonent,
                  viewerData: userData,
                  userRepository: userRepository,
                );
              },
            );
          },
        ),
      ],
    );
  }


}
