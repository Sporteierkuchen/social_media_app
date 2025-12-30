import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final _db = FirebaseFirestore.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chats => _firestore.collection('chats');

  // ------------------------------------------------------------
  // Chat finden oder erstellen (1:1)
  // ------------------------------------------------------------
  Future<String> getOrCreateChat({
    required String myUid,
    required String otherUid,
  }) async {
    final query = await _chats
        .where('participantsMap.$myUid', isEqualTo: true)
        .where('participantsMap.$otherUid', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    final doc = await _firestore.collection('chats').add({
      'participants': [myUid, otherUid],
      'participantsMap': {
        myUid: true,
        otherUid: true,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });


    return doc.id;
  }






  String chatIdFor(String uid1, String uid2) {
    final pair = [uid1, uid2]..sort();
    return "${pair[0]}_${pair[1]}";
  }

  Future<String> getOrCreateChatId({
    required String myUid,
    required String otherUid,
  }) async {
    final chatId = chatIdFor(myUid, otherUid);
    final chatRef = _db.collection('chats').doc(chatId);

    final snap = await chatRef.get();
    if (!snap.exists) {
      await chatRef.set({
        "participants": [myUid, otherUid],
        "createdAt": FieldValue.serverTimestamp(),
        "lastMessage": "",
        "lastMessageAt": FieldValue.serverTimestamp(),
        "lastSenderId": "",
      });
    }
    return chatId;
  }

  Query<Map<String, dynamic>> myChatsQuery(String myUid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true);
  }

  Query<Map<String, dynamic>> messagesQuery(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> chatDocStream(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    await _db.runTransaction((tx) async {
      // (optional) chat doc lesen, falls du irgendwas prüfen willst:
      // final chatSnap = await tx.get(chatRef);

      // 1) message schreiben
      tx.set(msgRef, {
        "senderId": senderId,
        "receiverId": receiverId,
        "text": text,
        "createdAt": FieldValue.serverTimestamp(),
        "type": "text",
      });

      // 2) chat meta updaten
      tx.update(chatRef, {
        "lastMessage": text,
        "lastMessageAt": FieldValue.serverTimestamp(),
        "lastSenderId": senderId,

        // ✅ unread receiver hoch
        "unreadCounts.$receiverId": FieldValue.increment(1),

        // ✅ sender hat natürlich alles gelesen
        "unreadCounts.$senderId": 0,
        "lastReadAtMap.$senderId": FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String myUid,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);

    await chatRef.update({
      "unreadCounts.$myUid": 0,
      "lastReadAtMap.$myUid": FieldValue.serverTimestamp(),
    });
  }




}
