// lib/repositories/user_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';

import '../models/SubscriptionDto.dart';
import '../models/UserDto.dart';

class SubscriptionPageResult {
  final List<SubscriptionDto> subscriptions;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  SubscriptionPageResult({
    required this.subscriptions,
    required this.lastDoc,
    required this.hasMore,
  });
}

class UserPageResult {
  /// Liste der User als DTOs
  final List<UserDto> users;

  /// Letztes Dokument für Paging (startAfter)
  final DocumentSnapshot? lastUser;

  /// Gibt es noch weitere Seiten?
  final bool hasMore;

  const UserPageResult({
    required this.users,
    required this.lastUser,
    required this.hasMore,
  });
}

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ------------------------------------------------------------
  // Collection-Shortcuts
  // ------------------------------------------------------------

  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _subscriptions =>
      _firestore.collection('subscriptions');
  CollectionReference get _videos => _firestore.collection('videos');
  CollectionReference get _posts => _firestore.collection('posts');
  CollectionReference get _comments => _firestore.collection('comments');
  CollectionReference get _replies => _firestore.collection('replies');

  // 🔹 NEU: User-Stream (z.B. für Rolle, Profil-Daten)
  Stream<UserDto?> userStream(String userId) {
    return _firestore.collection('users')
        .doc(userId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snap) {
      if (!snap.exists) return null;
      return UserDto.fromSnapshot(snap);
    });
  }

  // ============================================================
  // BASIS: USER-DATEN
  // ============================================================

  /// User-Daten als Map (für einfache Zugriffe)
  // (Optional) getUserDetails anpassen, falls du willst:
  Future<UserDto?> getUserDetailsDto(String uid) async {
    try {
      final rawSnap = await _users.doc(uid).get();

      if (!rawSnap.exists) return null;

      final snap = rawSnap as DocumentSnapshot<Map<String, dynamic>>;

      return UserDto.fromSnapshot(snap);
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  Future<String> getUserRole(String uid) async {
    try {
      final rawSnap = await _users.doc(uid).get();

      if (!rawSnap.exists) {
        return "USER";
      }

      final data = rawSnap.data() as Map<String, dynamic>?;
      if (data == null) {
        return "USER";
      }

      return (data["role"] as String?) ?? "USER";
    } catch (e) {
      print("Fehler beim Laden der User-Rolle: $e");
      return "USER";
    }
  }

  Query<Map<String, dynamic>> usersQuery({
    required String search,
    int limit = 20,
  }) {
    final base = FirebaseFirestore.instance.collection('users');

    final s = search.trim().toLowerCase();

    // 🔎 kein Search: einfach nach Username sortieren
    if (s.isEmpty) {
      return base
          .orderBy('benutzername') // empfehlung: extra feld in firestore
          .limit(limit);
    }

    // 🔎 Prefix search
    return base
        .orderBy('benutzername')
        .startAt([s])
        .endAt(['$s\uf8ff'])
        .limit(limit);
  }


  /// Raw DocumentSnapshot (z. B. für Profile-Seiten)
/*  Future<DocumentSnapshot> getViewerData(String viewerId) {
    return _users.doc(viewerId).get();
  }*/

  // ============================================================
  // PROFIL-UPDATE (Adresse, Name, Beschreibung, E-Mail, Passwort-Feld)
  // ============================================================

  Future<bool> updateUserProfile(UserDto user) async {
    try {
      await _users.doc(user.userid).update({
        'vorname': user.vorname,
        'nachname': user.nachname,
        'strase': user.strase,
        'hausnummer': user.hausnummer,
        'plz': user.plz,
        'stadt': user.stadt,
      });

      if (user.userid != null &&
          user.vorname != null &&
          user.nachname != null) {
        await _updateNameInRelatedCollections(
          user.userid!,
          user.vorname!,
          user.nachname!,
        );
      }

      return true;
    } catch (e) {
      print("Error updateUserProfile: $e");
      return false;
    }
  }

  Future<bool> updateUserBeschreibung(
      String beschreibung, String userid) async {
    try {
      await _users.doc(userid).update({
        'beschreibung': beschreibung,
      }).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print("Error updateUserBeschreibung: $e");
      return false;
    }
  }

  /// ⚠️ Nur Firestore-Feld, nicht das echte Auth-Passwort!
  Future<bool> updatePasswordFieldInUserDoc(
      String password, String uid) async {
    try {
      await _users.doc(uid).update({
        'password': password,
      }).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print("Error updatePasswordFieldInUserDoc: $e");
      return false;
    }
  }

  Future<bool> updateEmailFieldInUserDoc(String email, String uid) async {
    try {
      await _users.doc(uid).update({
        'email': email,
      }).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print("Error updateEmailFieldInUserDoc: $e");
      return false;
    }
  }

  // ============================================================
  // PROFILBILD + PROPAGATION
  // ============================================================

  Future<bool> uploadProfileImage(
      CroppedFile? imageFile, String userId) async {
    if (imageFile == null) return false;

    try {
      final ref = _storage
          .ref()
          .child('profile_pictures')
          .child('${_auth.currentUser!.uid}.jpg');

      await ref.putFile(File(imageFile.path));

      final downloadUrl = await ref.getDownloadURL();

      // Auth-User updaten
      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      // Users-Collection updaten
      await _users.doc(userId).update({
        'profilePictureUrl': downloadUrl,
      });

      // In allen relevanten Collections übernehmen
      await _updateProfilePictureInRelatedCollections(userId, downloadUrl);

      return true;
    } catch (e) {
      print('Fehler beim Hochladen des Profilbilds: $e');
      return false;
    }
  }

  Future<void> _updateProfilePictureInRelatedCollections(
      String userId, String url) async {
    try {
      // Videos
      await _batchUpdateCollection(
        query: _videos.where('userid', isEqualTo: userId),
        data: {'profilePictureUrl': url},
      );

      // Subscriptions (als Subscriber)
      await _batchUpdateCollection(
        query: _subscriptions.where('subscriberId', isEqualTo: userId),
        data: {'subscriberProfilePic': url},
      );

      // Subscriptions (als Ziel)
      await _batchUpdateCollection(
        query: _subscriptions.where('subscribedToId', isEqualTo: userId),
        data: {'subscriberToProfilePic': url},
      );

      // Comments
      await _batchUpdateCollection(
        query: _comments.where('userId', isEqualTo: userId),
        data: {'profilePictureUrl': url},
      );

      // Replies
      await _batchUpdateCollection(
        query: _replies.where('userId', isEqualTo: userId),
        data: {'profilePictureUrl': url},
      );
    } catch (e) {
      print('Fehler beim Update Profilbild in Relationen: $e');
    }
  }

  Future<void> _updateNameInRelatedCollections(
      String userId, String vorname, String nachname) async {
    try {
      // Videos
      await _batchUpdateCollection(
        query: _videos.where('userid', isEqualTo: userId),
        data: {
          'vorname': vorname,
          'nachname': nachname,
        },
      );

      // Subscriptions (als Subscriber)
      await _batchUpdateCollection(
        query: _subscriptions.where('subscriberId', isEqualTo: userId),
        data: {
          'subscriberVorname': vorname,
          'subscriberNachname': nachname,
        },
      );

      // Subscriptions (als Ziel)
      await _batchUpdateCollection(
        query: _subscriptions.where('subscribedToId', isEqualTo: userId),
        data: {
          'subscriberToVorname': vorname,
          'subscriberToNachname': nachname,
        },
      );
    } catch (e) {
      print('Fehler beim Update Name in Relationen: $e');
    }
  }

  Future<void> _batchUpdateCollection({
    required Query query,
    required Map<String, dynamic> data,
  }) async {
    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, data);
    }
    await batch.commit();
  }

  // ============================================================
  // ROLLEN-UPDATE IN ALLEN RELATIONEN
  // ============================================================

  Future<void> updateUserRoleEverywhere({
    required String userId,
    required String role,
  }) async {
    // 1) User-Dokument
    await _users.doc(userId).update({
      'role': role,
    });

    // 2) Rolle in allen Posts aktualisieren
    final postsSnapshot =
    await _posts.where('userid', isEqualTo: userId).get();

    final batchPosts = _firestore.batch();
    for (var doc in postsSnapshot.docs) {
      batchPosts.update(doc.reference, {'role': role});
    }
    await batchPosts.commit();

    // 3) Rolle in Subscriptions als Subscriber
    final subAsSubscriber =
    await _subscriptions.where('subscriberId', isEqualTo: userId).get();

    final batchSub1 = _firestore.batch();
    for (var doc in subAsSubscriber.docs) {
      batchSub1.update(doc.reference, {'subscriberRole': role});
    }
    await batchSub1.commit();

    // 4) Rolle in Subscriptions als subscribedTo
    final subAsTarget =
    await _subscriptions.where('subscribedToId', isEqualTo: userId).get();

    final batchSub2 = _firestore.batch();
    for (var doc in subAsTarget.docs) {
      batchSub2.update(doc.reference, {'subscriberToRole': role});
    }
    await batchSub2.commit();

    // 5) Rolle in Kommentaren
    final commentsSnapshot =
    await _comments.where('userId', isEqualTo: userId).get();

    final batchComments = _firestore.batch();
    for (var doc in commentsSnapshot.docs) {
      batchComments.update(doc.reference, {'role': role});
    }
    await batchComments.commit();

    // 6) Rolle in Replies
    final repliesSnapshot =
    await _replies.where('userId', isEqualTo: userId).get();

    final batchReplies = _firestore.batch();
    for (var doc in repliesSnapshot.docs) {
      batchReplies.update(doc.reference, {'role': role});
    }
    await batchReplies.commit();
  }


  // ============================================================
  // SUBSCRIPTIONS (Abos) – Paging & Aktionen
  // ============================================================

  /// Prüft, ob subscriberId bereits subscribedToId abonniert
  Future<bool> checkAbo(String subscriberId, String subscribedToId) async {
    try {
      final result = await _subscriptions
          .where('subscriberId', isEqualTo: subscriberId)
          .where('subscribedToId', isEqualTo: subscribedToId)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      print("Fehler beim Abrufen des Abonnentenstatus: $e");
      return false;
    }
  }

  // ============================================================
  // SUBSCRIPTIONS (Abos) – vereinheitlichtes Subscribe
  // ============================================================

  /// Unified Subscribe:
  /// - Prüft, ob viewerId (Subscriber) userId (Channel) schon abonniert hat
  /// - Wenn nein: legt eine vollständige Subscription mit allen relevanten
  ///   User-Daten (Viewer + Ziel) an.
  /// - Rückgabe: true = neu abonniert, false = Abo existierte bereits oder Fehler.
  Future<bool> subscribe({
    required String viewerId,
    required String userId,
    required Map<String, dynamic> viewerData,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Existiert die Subscription schon?
      final existing = await _subscriptions
          .where('subscriberId', isEqualTo: viewerId)
          .where('subscribedToId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print("Benutzer ist bereits abonniert.");
        return false;
      }

      // Neue, vollständige Subscription anlegen
      await _subscriptions.add({
        'subscriberId': viewerId,
        'subscribedToId': userId,

        'subscriberName': viewerData["benutzername"],
        'subscriberVorname': viewerData["vorname"],
        'subscriberNachname': viewerData["nachname"],
        'subscriberProfilePic': viewerData["profilePictureUrl"],
        'subscriberRole': viewerData["role"],

        'subscriberToName': userData["benutzername"],
        'subscriberToVorname': userData["vorname"],
        'subscriberToNachname': userData["nachname"],
        'subscriberToProfilePic': userData["profilePictureUrl"],
        'subscriberToRole': userData["role"],

        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Fehler beim Abonnieren: $e");
      return false;
    }
  }

  Future<bool> unsubscribe({
    required String viewerId,
    required String userId,
  }) async {
    try {
      final snapshot = await _subscriptions
          .where('subscriberId', isEqualTo: viewerId)
          .where('subscribedToId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print("unsubscribe: kein Abo gefunden (viewerId=$viewerId, userId=$userId)");
        return false;
      }

      await snapshot.docs.first.reference.delete();
      return true;
    } catch (e) {
      print("Fehler beim Deabonnieren: $e");
      return false;
    }
  }


/*
  Future<QuerySnapshot> getSubscriptionSnapshot({
    required String viewerId,
    required String userId,
  }) {
    return _subscriptions
        .where('subscriberId', isEqualTo: viewerId)
        .where('subscribedToId', isEqualTo: userId)
        .get();
  }

  Future<void> deleteSubscription(DocumentSnapshot doc) async {
    await doc.reference.delete();
  }


*/


  Future<SubscriptionPageResult> fetchSubscribersPage({
    required String userId,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _subscriptions
        .where('subscribedToId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit + 1); // +1 für "gibt es noch mehr?"

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    late final List<SubscriptionDto> subs;
    late final DocumentSnapshot? lastDoc;
    late final bool hasMore;

    if (docs.length > limit) {
      subs = docs
          .take(limit)
          .map((doc) => SubscriptionDto.fromDocument(doc))
          .toList();
      lastDoc = docs[limit - 1];
      hasMore = true;
    } else {
      subs = docs
          .map((doc) => SubscriptionDto.fromDocument(doc))
          .toList();
      lastDoc = docs.isNotEmpty ? docs.last : null;
      hasMore = false;
    }

    return SubscriptionPageResult(
      subscriptions: subs,
      lastDoc: lastDoc,
      hasMore: hasMore
    );
  }


  /// Meine Abos (wen ich abonniere) – initial (alte Variante)
  Future<SubscriptionPageResult> fetchMySubscriptionsPage({
    required String userId,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _subscriptions
        .where('subscriberId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit + 1);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    late final List<SubscriptionDto> subs;
    late final DocumentSnapshot? lastDoc;
    late final bool hasMore;

    if (docs.length > limit) {
      subs = docs
          .take(limit)
          .map((doc) => SubscriptionDto.fromDocument(doc))
          .toList();
      lastDoc = docs[limit - 1];
      hasMore = true;
    } else {
      subs = docs
          .map((doc) => SubscriptionDto.fromDocument(doc))
          .toList();
      lastDoc = docs.isNotEmpty ? docs.last : null;
      hasMore = false;
    }

    return SubscriptionPageResult(
      subscriptions: subs,
      lastDoc: lastDoc,
      hasMore: hasMore,
    );
  }

  Query<Map<String, dynamic>> subscribersQuery(String userId) {
    return FirebaseFirestore.instance
        .collection('subscriptions')
        .where('subscribedToId', isEqualTo: userId)
        .orderBy('timestamp', descending: true); // falls vorhanden!
  }

  Stream<int> subscribersCountStream(String userId) {
    return _subscriptions
        .where('subscribedToId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.size); // oder snap.docs.length
  }

  Query<Map<String, dynamic>> subscribedQuery(String userId) {
    return FirebaseFirestore.instance
        .collection('subscriptions')
        .where('subscriberId', isEqualTo: userId)
        .orderBy('timestamp', descending: true); // falls vorhanden!
  }

  Stream<int> subscribedCountStream(String userId) {
    return _subscriptions
        .where('subscriberId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.size); // oder snap.docs.length
  }

  // ✅ Ist viewerId aktuell Abonnent von targetId?
  // (streamt live und updated sofort den Button "Abbonieren/Abboniert")
  Stream<bool> isSubscribedStream({
    required String viewerId,
    required String targetId,
  }) {
    return _subscriptions
        .where('subscriberId', isEqualTo: viewerId)
        .where('subscribedToId', isEqualTo: targetId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }


  // ============================================================
  // USER-LISTE (Entdeckung / Admin-Listen)
  // ============================================================

  Future<UserPageResult> fetchUsers({
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _users
        .orderBy('timestamp', descending: true)
        .limit(limit + 1); // +1 für "gibt es noch mehr?"

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    late final List<UserDto> users;
    late final DocumentSnapshot? lastDoc;
    late final bool hasMore;

    if (docs.length > limit) {
      // Es gibt mehr als "limit" Einträge → weitere Seite vorhanden
      users = docs.take(limit).map((doc) {
        final typed = doc as DocumentSnapshot<Map<String, dynamic>>;
        return UserDto.fromSnapshot(typed);
      }).toList();

      lastDoc = docs[limit - 1];
      hasMore = true;
    } else {
      // Letzte Seite
      users = docs.map((doc) {
        final typed = doc as DocumentSnapshot<Map<String, dynamic>>;
        return UserDto.fromSnapshot(typed);
      }).toList();

      lastDoc = docs.isNotEmpty ? docs.last : null;
      hasMore = false;
    }

    return UserPageResult(
      users: users,
      lastUser: lastDoc,
      hasMore: hasMore,
    );
  }

  // ============================================================
  // NICKNAME
  // ============================================================

// ============================================================
// USER SUCHE (Stream) – für Chat/UserSearchPage
// ============================================================
  Stream<List<UserDto>> searchUsersStream({
    required String search,
    int limit = 20,
  }) {
    return usersQuery(search: search, limit: limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) {
      return snap.docs
          .map((d) => UserDto.fromMap(d.data(), id: d.id))
          .toList();
    });
  }


  // ============================================================
  // USER + DATEN KOMPLETT LÖSCHEN (nur Firestore+Storage, kein Auth)
  // ============================================================

  Future<void> deleteUserAndDataFirestoreOnly(String userId) async {
    final batch = _firestore.batch();

    // Alle Videos des Users
    final videosSnapshot =
    await _videos.where('userid', isEqualTo: userId).get();

    for (var videoDoc in videosSnapshot.docs) {
      final videoId = videoDoc.id;
      final data = videoDoc.data() as Map<String, dynamic>;
      final videoUrl = data['videoUrl'];
      final thumbnailUrl = data['thumbnailUrl'];

      batch.delete(videoDoc.reference);

      if (videoUrl != null) {
        await _storage.refFromURL(videoUrl).delete();
      }
      if (thumbnailUrl != null) {
        await _storage.refFromURL(thumbnailUrl).delete();
      }

      // Kommentare zu diesem Video
      final commentsSnapshot =
      await _comments.where('videoId', isEqualTo: videoId).get();

      for (var commentDoc in commentsSnapshot.docs) {
        final commentId = commentDoc.id;
        batch.delete(commentDoc.reference);

        // Replies zu diesem Kommentar
        final repliesSnapshot =
        await _replies.where('commentId', isEqualTo: commentId).get();

        for (var replyDoc in repliesSnapshot.docs) {
          batch.delete(replyDoc.reference);

          final replyReactions =
          await replyDoc.reference.collection('userInteractions').get();
          for (var reactionDoc in replyReactions.docs) {
            batch.delete(reactionDoc.reference);
          }
        }

        final commentReactions =
        await commentDoc.reference.collection('userInteractions').get();
        for (var reactionDoc in commentReactions.docs) {
          batch.delete(reactionDoc.reference);
        }
      }
    }

    // User-Dokument löschen
    final userRef = _users.doc(userId);
    batch.delete(userRef);

    await batch.commit();
  }

  Future<void> setOnline(String uid) async {
    await _users.doc(uid).set({
      "isOnline": true,
      "lastActiveAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOffline(String uid) async {
    await _users.doc(uid).set({
      "isOnline": false,
      "lastActiveAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setActivePost({
    required String userId,
    required String? postId,
  }) async {
    await _firestore.collection("users").doc(userId).set({
      "activePostId": postId,
      "lastActiveAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setActiveComment({
    required String userId,
    required String? commentId,
  }) async {
    await _firestore.collection("users").doc(userId).set({
      "activeCommentId": commentId,
      "lastActiveAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearActivePostContext({
    required String userId,
  }) async {
    await _firestore.collection("users").doc(userId).set({
      "activePostId": null,
      "activeCommentId": null,
      "lastActiveAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


}
