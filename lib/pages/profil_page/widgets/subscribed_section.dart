import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../models/SubscriptionDto.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import 'abboniert_widget.dart';

class SubscribedSection extends StatelessWidget {
  final UserDto userData;
  final UserRepository userRepository;
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
    final parentContext = context; // <- stabileren Context merken

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        FirestoreQueryBuilder<Map<String, dynamic>>(
          query: subscribedQuery,
          pageSize: pageSize,
          builder: (context, snapshot, _) {
            if (snapshot.isFetching && snapshot.docs.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
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
                if (index == snapshot.docs.length) {
                  if (!snapshot.hasMore) return const SizedBox(height: 20);

                  if (snapshot.isFetchingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  return Center(
                    child: TextButton(
                      onPressed: snapshot.fetchMore,
                      child: const Text("Mehr laden"),
                    ),
                  );
                }

                final doc = snapshot.docs[index];
                final abbonent = SubscriptionDto.fromSnapshot(doc);

                return AbboniertWidget(
                  key: ValueKey(doc.id),
                  abbonent: abbonent,
                  viewerData: userData,
                  userRepository: userRepository,
                  onMessage: (text, art) {
                    HelperUtil.getToast(
                      meldung: Meldung(
                        meldungsart: art,
                        text: text,
                      ),
                      context: parentContext, // <- nicht builder-context
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}