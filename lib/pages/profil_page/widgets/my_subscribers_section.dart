import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/SubscriptionDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import 'abbonent_widget.dart';

class MySubscribersSection extends StatelessWidget {
  final UserDto userData;
  final UserRepository userRepository;

  final Query<Map<String, dynamic>> subscribersQuery;
  final Stream<int> subscribersCountStream;

  final int pageSize;

  const MySubscribersSection({
    super.key,
    required this.userData,
    required this.subscribersQuery,
    required this.subscribersCountStream,
    this.pageSize = 15,
    required this.userRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 12),
          child: StreamBuilder<int>(
            stream: subscribersCountStream,
            builder: (context, snap) {
              final countText = snap.hasData ? "${snap.data}" : "…";

              return Text(
                "Meine Abonnenten ($countText)",
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        FirestoreQueryBuilder<Map<String, dynamic>>(
          query: subscribersQuery,
          pageSize: pageSize,
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
                "Fehler beim Laden der Abonnenten: ${snapshot.error}",
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
                  "Noch keine Abonnenten vorhanden.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.docs.length + 1,
              itemBuilder: (context, index) {
                if (index == snapshot.docs.length) {
                  if (!snapshot.hasMore) {
                    return const SizedBox(height: 10);
                  }

                  if (snapshot.isFetchingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
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
                final abbonent = SubscriptionDto.fromSnapshot(doc);

                return AbbonentWidget(
                  key: ValueKey(doc.id),
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