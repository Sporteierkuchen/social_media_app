
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import '../models/PostDto.dart';
import '../models/CommentDto.dart';
import '../models/UserDto.dart';
import '../util/HelperUtil.dart';

class CommentPageResult {
  /// Liste der Kommentare als DTOs
  final List<CommentDto> comments;

  /// Letztes Dokument für Paging (startAfter)
  final DocumentSnapshot? lastComment;

  /// Gibt es noch weitere Seiten?
  final bool hasMore;

  CommentPageResult({
    required this.comments,
    required this.lastComment,
    required this.hasMore,
  });
}

class PostRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference get _posts => _firestore.collection('posts');
  CollectionReference get _comments => _firestore.collection('comments');
  CollectionReference get _replies => _firestore.collection('replies');

  Future<PostDto?> getPostById(String postId) async {
    try {
      final doc = await _posts.doc(postId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return PostDto.fromDoc(doc);
    } catch (e) {
      debugPrint("[PostRepository] Fehler beim Laden des Posts: $e");
      return null;
    }
  }

  Future<List<PostDto>> getPostsByIds(List<String> postIds) async {
    try {
      if (postIds.isEmpty) {
        return [];
      }

      final futures = postIds.map((id) => _posts.doc(id).get()).toList();
      final docs = await Future.wait(futures);

      final posts = docs
          .where((doc) => doc.exists && doc.data() != null)
          .map((doc) => PostDto.fromDoc(doc))
          .toList();

      posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return posts;
    } catch (e) {
      debugPrint("[PostRepository] Fehler beim Laden mehrerer Posts: $e");
      return [];
    }
  }

  Stream<PostDto?> getPostStream(String postId) {
    return _posts.doc(postId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PostDto.fromDoc(snap);
    });
  }

  Stream<List<PostDto>> bestPostsStream({
    required String type, // 'video' oder 'image'
    int limit = 4,
    bool sortByViews = true,
  }) {
    final col = _firestore.collection('posts');

    Query<Map<String, dynamic>> q = col
        .where('type', isEqualTo: type)
        .orderBy(sortByViews ? 'views' : 'timestamp', descending: true)
        .limit(limit);

    return q.snapshots().map(
          (snap) => snap.docs.map((d) => PostDto.fromSnapshot(d)).toList(),
    );
  }

  Stream<List<PostDto>> bestVideosPostsStream({int limit = 4}) =>
      bestPostsStream(type: 'video', limit: limit, sortByViews: true);

  Stream<List<PostDto>> bestImagesPostsStream({int limit = 4}) =>
      bestPostsStream(type: 'image', limit: limit, sortByViews: true);


  Query<Map<String, dynamic>> postsFeedQuery({
    List<String> selectedCategories = const [],
    PostMediaFilter mediaFilter = PostMediaFilter.all,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true);

    if (selectedCategories.isNotEmpty) {
      query = query.where('category', arrayContainsAny: selectedCategories);
    }

    if (mediaFilter == PostMediaFilter.videos) {
      query = query.where('type', isEqualTo: 'video');
    } else if (mediaFilter == PostMediaFilter.images) {
      query = query.where('type', isEqualTo: 'image');
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  Query<Map<String, dynamic>> searchPostsByTitleQuery({
    required String searchText,
    List<String> selectedCategories = const [],
    PostMediaFilter mediaFilter = PostMediaFilter.all,
    int? limit,
  }) {
    final normalized = searchText.toLowerCase().trim();

    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .orderBy('titleLower')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff']);

    if (selectedCategories.isNotEmpty) {
      query = query.where('category', arrayContainsAny: selectedCategories);
    }

    if (mediaFilter == PostMediaFilter.videos) {
      query = query.where('type', isEqualTo: 'video');
    } else if (mediaFilter == PostMediaFilter.images) {
      query = query.where('type', isEqualTo: 'image');
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  Query<Map<String, dynamic>> searchPostsByFullNameQuery({
    required String searchText,
    List<String> selectedCategories = const [],
    PostMediaFilter mediaFilter = PostMediaFilter.all,
    int? limit,
  }) {
    final normalized = searchText.toLowerCase().trim();

    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .orderBy('fullNameLower')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff']);

    if (selectedCategories.isNotEmpty) {
      query = query.where('category', arrayContainsAny: selectedCategories);
    }

    if (mediaFilter == PostMediaFilter.videos) {
      query = query.where('type', isEqualTo: 'video');
    } else if (mediaFilter == PostMediaFilter.images) {
      query = query.where('type', isEqualTo: 'image');
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  // ------------------------------------------------------------
  // POST LÖSCHEN + KOMMENTARE / REPLIES / REACTIONS
  // (nur reine Datenlogik – UI/Toasts macht der Caller)
  // ------------------------------------------------------------
  Future<bool> deletePost(String postId) async {
    try {
      final postRef = _posts.doc(postId);
      final snap = await postRef.get();

      if (!snap.exists) {
        debugPrint("deletePost: Post $postId existiert nicht");
        return false;
      }

      final data = snap.data() as Map<String, dynamic>? ?? {};

      final String type = (data['type'] as String? ?? '').trim();
      final String mediaUrl = (data['mediaUrl'] as String? ?? '').trim();
      final String thumbnailUrl = (data['thumbnailUrl'] as String? ?? '').trim();
      final String previewUrl = (data['previewUrl'] as String? ?? '').trim();
      final String fullImageUrl = (data['fullImageUrl'] as String? ?? '').trim();

      // Alle eindeutigen Storage-URLs sammeln
      final Set<String> storageUrls = {
        if (mediaUrl.isNotEmpty) mediaUrl,
        if (thumbnailUrl.isNotEmpty) thumbnailUrl,
        if (previewUrl.isNotEmpty) previewUrl,
        if (fullImageUrl.isNotEmpty) fullImageUrl,
      };

      // 1) Kommentare + Replies löschen
      await _deleteCommentsAndReplies(postId);

      // 2) Subcollections direkt am Post löschen
      await _deleteSubcollection(postRef, 'userInteractions');

      // Falls du später weitere direkte Subcollections am Post hast,
      // hier ebenfalls ergänzen:
      // await _deleteSubcollection(postRef, 'xyz');

      // 3) Post-Dokument löschen
      await postRef.delete();

      // 4) Dateien aus Firebase Storage löschen
      for (final url in storageUrls) {
        try {
          final storageRef = _storage.refFromURL(url);
          await storageRef.delete();
          debugPrint("deletePost: Storage-Datei gelöscht: $url");
        } catch (e) {
          debugPrint("deletePost: Storage-Datei konnte nicht gelöscht werden ($url): $e");
        }
      }

      debugPrint(
        "deletePost: Post ($type) inkl. Firestore-Daten und Storage-Dateien erfolgreich gelöscht.",
      );
      return true;
    } catch (e) {
      debugPrint("Fehler beim Löschen des Posts: $e");
      return false;
    }
  }

  // ------------------------------------------------------------
  // Kategorien
  // ------------------------------------------------------------
  Future<List<String>> fetchCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('categorie')
        .get();

    return snapshot.docs
        .map((doc) => (doc.data())['categorie'] as String)
        .toList();
  }

  // STREAM: Kategorien (String-only)
  Stream<List<String>> categoriesStream() {
    return _firestore
        .collection('categories')
        .orderBy('categorie')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => (doc.data())['categorie'] as String)
          .toList(),
    );
  }

  // categories hinzufügen (String-only)
  Future<void> addCategory(String categoryName) async {
    final name = categoryName.trim();
    if (name.isEmpty) {
      throw Exception("Kategorie darf nicht leer sein.");
    }

    // Duplikate verhindern (case-sensitiv wie Firestore speichert)
    final existing = await _firestore
        .collection('categories')
        .where('categorie', isEqualTo: name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Kategorie existiert bereits.");
    }

    await _firestore.collection('categories').add({
      'categorie': name,
      'timestamp': FieldValue.serverTimestamp(), // optional
    });
  }

// categories löschen (String-only: per Name)
  Future<void> deleteCategoryByName(String categoryName) async {
    final name = categoryName.trim();
    if (name.isEmpty) return;

    final snap = await _firestore
        .collection('categories')
        .where('categorie', isEqualTo: name)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception("Kategorie nicht gefunden.");
    }

    await snap.docs.first.reference.delete();
  }

  // =========================================================
  // VIEWCOUNT
  // =========================================================

  Future<void> incrementViewCount(String postId) async {
    try {
      final ref = _posts.doc(postId);
      await ref.update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print("[PostRepository] Fehler bei incrementViewCount($postId): $e");
      rethrow;
    }
  }

  /// ✅ Live: Views gesamt über alle VIDEOS eines Uploaders (posts.type == "video")
  Stream<int> userVideoViewsStream(String uploaderId) {
    return _firestore
        .collection('posts')
        .where('userid', isEqualTo: uploaderId)
        .where('type', isEqualTo: 'video')
        .snapshots()
        .map((snap) {
      int sum = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final v = data['views'];

        if (v is num) sum += v.toInt();
      }

      return sum;
    });
  }

  /// ✅ Live: Views gesamt über alle BILDER eines Uploaders (posts.type == "image")
  Stream<int> userImageViewsStream(String uploaderId) {
    return _firestore
        .collection('posts')
        .where('userid', isEqualTo: uploaderId)
        .where('type', isEqualTo: 'image')
        .snapshots()
        .map((snap) {
      int sum = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        final v = data['views'];

        if (v is num) sum += v.toInt();
      }

      return sum;
    });
  }


  // im VideoRepository (bzw. PostRepository)
  // Annahme: Collection heißt "posts", Feld "type" ist "video" oder "image"
  Query<Map<String, dynamic>> userPostsQuery({
    required String userId,
    String? type, // null => alle
  }) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('posts')
        .where('userid', isEqualTo: userId);

    if (type != null && type.trim().isNotEmpty) {
      q = q.where('type', isEqualTo: type.trim());
    }

    return q.orderBy('timestamp', descending: true);
  }

  // Live-Counts (für Header in der Section)
  Stream<int> userPostCountStream(String uploaderId) {
    return _firestore
        .collection('posts')
        .where('userid', isEqualTo: uploaderId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ✅ Videos eines Uploaders zählen
    Stream<int> userVideoCountStream(String uploaderId) {
      return _posts
          .where('userid', isEqualTo: uploaderId)
          .where('type', isEqualTo: 'video') // wichtig: exakt wie du speicherst
          .snapshots()
          .map((snap) => snap.docs.length);
    }

  // ✅ Bilder eines Uploaders zählen
    Stream<int> userImageCountStream(String uploaderId) {
      return _posts
          .where('userid', isEqualTo: uploaderId)
          .where('type', isEqualTo: 'image')
          .snapshots()
          .map((snap) => snap.docs.length);
    }


  // =========================================================
  // USER-INTERACTIONS (Like / Dislike)
  // =========================================================

  Future<Map<String, bool>> getUserLikeDislikeStatus({
    required String postId,
    required String userId,
  }) async {
    try {
      final interactionRef = _posts
          .doc(postId)
          .collection('userInteractions')
          .doc(userId);
      final snap = await interactionRef.get();

      if (!snap.exists) {
        return {
          'liked': false,
          'disliked': false,
        };
      }

      final data = snap.data() as Map<String, dynamic>;
      final bool liked = data['liked'] == true;
      final bool disliked = data['disliked'] == true;

      return {
        'liked': liked,
        'disliked': disliked,
      };
    } catch (e) {
      print(
          "[PostRepository] Fehler bei getUserLikeDislikeStatus(postId=$postId, userId=$userId): $e");
      rethrow;
    }
  }

  /// Like-Logik:
  /// - Wenn bisher nichts: like +1
  /// - Wenn bereits liked: like -1 (entfernen)
  /// - Wenn disliked -> switch: dislike -1, like +1
  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
    required bool isDisliked,
  }) async {
    final postRef = _posts.doc(postId);
    final interactionRef =
    postRef.collection('userInteractions').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final postSnap = await transaction.get(postRef);
        if (!postSnap.exists) {
          throw Exception("Post existiert nicht (ID=$postId)");
        }

        final postData = postSnap.data() as Map<String, dynamic>;
        int currentLikes = (postData['likes'] ?? 0) as int;
        int currentDislikes = (postData['dislikes'] ?? 0) as int;

        bool newLiked = isLiked;
        bool newDisliked = isDisliked;

        if (!isLiked && !isDisliked) {
          // Noch nichts -> like setzen
          newLiked = true;
          currentLikes += 1;
        } else if (isLiked && !isDisliked) {
          // Like entfernen
          newLiked = false;
          currentLikes = (currentLikes > 0) ? currentLikes - 1 : 0;
        } else if (!isLiked && isDisliked) {
          // Dislike -> Like
          newLiked = true;
          newDisliked = false;
          currentLikes += 1;
          currentDislikes =
          (currentDislikes > 0) ? currentDislikes - 1 : 0;
        }

        transaction.update(postRef, {
          'likes': currentLikes,
          'dislikes': currentDislikes,
        });

        transaction.set(
          interactionRef,
          {
            'liked': newLiked,
            'disliked': newDisliked,
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print("[PostRepository] Fehler bei toggleLike(postId=$postId): $e");
      rethrow;
    }
  }

  /// Dislike-Logik:
  /// - Wenn bisher nichts: dislike +1
  /// - Wenn bereits disliked: dislike -1 (entfernen)
  /// - Wenn liked -> switch: like -1, dislike +1
  Future<void> toggleDislike({
    required String postId,
    required String userId,
    required bool isLiked,
    required bool isDisliked,
  }) async {
    final postRef = _posts.doc(postId);
    final interactionRef =
    postRef.collection('userInteractions').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final postSnap = await transaction.get(postRef);
        if (!postSnap.exists) {
          throw Exception("Post existiert nicht (ID=$postId)");
        }

        final postData = postSnap.data() as Map<String, dynamic>;
        int currentLikes = (postData['likes'] ?? 0) as int;
        int currentDislikes = (postData['dislikes'] ?? 0) as int;

        bool newLiked = isLiked;
        bool newDisliked = isDisliked;

        if (!isLiked && !isDisliked) {
          // Noch nichts -> dislike setzen
          newDisliked = true;
          currentDislikes += 1;
        } else if (!isLiked && isDisliked) {
          // Dislike entfernen
          newDisliked = false;
          currentDislikes =
          (currentDislikes > 0) ? currentDislikes - 1 : 0;
        } else if (isLiked && !isDisliked) {
          // Like -> Dislike
          newLiked = false;
          newDisliked = true;
          currentLikes = (currentLikes > 0) ? currentLikes - 1 : 0;
          currentDislikes += 1;
        }

        transaction.update(postRef, {
          'likes': currentLikes,
          'dislikes': currentDislikes,
        });

        transaction.set(
          interactionRef,
          {
            'liked': newLiked,
            'disliked': newDisliked,
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print(
          "[PostRepository] Fehler bei toggleDislike(postId=$postId): $e");
      rethrow;
    }
  }


  // =========================================================
  // KOMMENTARE
  // =========================================================
  Future<CommentPageResult> fetchComments({
    required String videoId,
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    // +1-Pattern: wir holen limit+1, um sicher beurteilen zu können,
    // ob noch weitere Seiten existieren.
    Query query = _comments
        .where('videoId', isEqualTo: videoId)
        .orderBy('timestamp', descending: true)
        .limit(limit + 1);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    late final List<CommentDto> comments;
    late final DocumentSnapshot? lastDoc;
    late final bool hasMore;

    if (docs.length > limit) {
      // Es gibt mehr als "limit" Kommentare → es gibt eine weitere Seite.
      comments = docs
          .take(limit)
          .map((doc) => CommentDto.fromDocument(doc))
          .toList();
      lastDoc = docs[limit - 1];
      hasMore = true;
    } else {
      // Letzte Seite
      comments = docs
          .map((doc) => CommentDto.fromDocument(doc))
          .toList();
      lastDoc = docs.isNotEmpty ? docs.last : null;
      hasMore = false;
    }

    return CommentPageResult(
      comments: comments,
      lastComment: lastDoc,
      hasMore: hasMore,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsLiveStream({
    required String videoId,
    int limit = 10,
  }) {
    return _firestore.collection('comments')
        .where('videoId', isEqualTo: videoId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }


  Stream<int> commentsCountStream(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snap) => snap.size);
  }

  // =========================================================
  // STREAM: Einzelner Kommentar als DTO
  // =========================================================
  Stream<CommentDto?> getCommentStream(String commentId) {
    return _comments.doc(commentId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return CommentDto.fromDocument(snap);
    });
  }

  Query<Map<String, dynamic>> commentsQuery(String postId) {
    return FirebaseFirestore.instance
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: true);
  }

  // =========================================================
  // USER-INTERACTIONS (Like / Dislike)
  // =========================================================

  /// Holt den Like/Dislike-Status für einen Kommentar
  Future<Map<String, bool>> getCommentLikeDislikeStatus({
    required String commentId,
    required String userId,
  }) async {
    try {
      final interactionRef = _comments
          .doc(commentId)
          .collection('userInteractions')
          .doc(userId);
      final snap = await interactionRef.get();

      if (!snap.exists) {
        return {
          'liked': false,
          'disliked': false,
        };
      }

      final data = snap.data() as Map<String, dynamic>;
      final bool liked = data['liked'] == true;
      final bool disliked = data['disliked'] == true;

      return {
        'liked': liked,
        'disliked': disliked,
      };
    } catch (e) {
      print(
          "[VideoRepository] Fehler bei getUserLikeDislikeStatus(commentId=$commentId, userId=$userId): $e");
      rethrow;
    }
  }

  /// Like-Logik:
  /// - Wenn bisher nichts: like +1
  /// - Wenn bereits liked: like -1 (entfernen)
  /// - Wenn disliked -> switch: dislike -1, like +1
  Future<void> toggleLikeComment({
    required String commentId,
    required String userId,
    required bool isLiked,
    required bool isDisliked,
  }) async {
    final commentRef = _comments.doc(commentId);
    final interactionRef =
    commentRef.collection('userInteractions').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final commentSnap = await transaction.get(commentRef);
        if (!commentSnap.exists) {
          throw Exception("Comment existiert nicht (ID=$commentId)");
        }

        final commentData = commentSnap.data() as Map<String, dynamic>;
        int currentLikes = (commentData['likes'] ?? 0) as int;
        int currentDislikes = (commentData['dislikes'] ?? 0) as int;

        bool newLiked = isLiked;
        bool newDisliked = isDisliked;

        if (!isLiked && !isDisliked) {
          // Noch nichts -> like setzen
          newLiked = true;
          currentLikes += 1;
        } else if (isLiked && !isDisliked) {
          // Like entfernen
          newLiked = false;
          currentLikes = (currentLikes > 0) ? currentLikes - 1 : 0;
        } else if (!isLiked && isDisliked) {
          // Dislike -> Like
          newLiked = true;
          newDisliked = false;
          currentLikes += 1;
          currentDislikes =
          (currentDislikes > 0) ? currentDislikes - 1 : 0;
        }

        transaction.update(commentRef, {
          'likes': currentLikes,
          'dislikes': currentDislikes,
        });

        transaction.set(
          interactionRef,
          {
            'liked': newLiked,
            'disliked': newDisliked,
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print("[VideoRepository] Fehler bei toggleLike(commentId=$commentId): $e");
      rethrow;
    }
  }

  /// Dislike-Logik:
  /// - Wenn bisher nichts: dislike +1
  /// - Wenn bereits disliked: dislike -1 (entfernen)
  /// - Wenn liked -> switch: like -1, dislike +1
  Future<void> toggleDislikeComment({
    required String commentId,
    required String userId,
    required bool isLiked,
    required bool isDisliked,
  }) async {
    final commentRef = _comments.doc(commentId);
    final interactionRef =
    commentRef.collection('userInteractions').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final commentSnap = await transaction.get(commentRef);
        if (!commentSnap.exists) {
          throw Exception("Comment existiert nicht (ID=$commentId)");
        }

        final commentData = commentSnap.data() as Map<String, dynamic>;
        int currentLikes = (commentData['likes'] ?? 0) as int;
        int currentDislikes = (commentData['dislikes'] ?? 0) as int;

        bool newLiked = isLiked;
        bool newDisliked = isDisliked;

        if (!isLiked && !isDisliked) {
          // Noch nichts -> dislike setzen
          newDisliked = true;
          currentDislikes += 1;
        } else if (!isLiked && isDisliked) {
          // Dislike entfernen
          newDisliked = false;
          currentDislikes =
          (currentDislikes > 0) ? currentDislikes - 1 : 0;
        } else if (isLiked && !isDisliked) {
          // Like -> Dislike
          newLiked = false;
          newDisliked = true;
          currentLikes = (currentLikes > 0) ? currentLikes - 1 : 0;
          currentDislikes += 1;
        }

        transaction.update(commentRef, {
          'likes': currentLikes,
          'dislikes': currentDislikes,
        });

        transaction.set(
          interactionRef,
          {
            'liked': newLiked,
            'disliked': newDisliked,
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print(
          "[VideoRepository] Fehler bei toggleDislike(commentId=$commentId): $e");
      rethrow;
    }
  }


  /// Kommentar anlegen
  /// userData ist die Map aus UserDto.toMap() und wird genutzt
  /// für z.B. benutzername, profilbild, rolle usw.
  Future<void> addComment({
    required String postId,
    required String userId,
    required UserDto userData,
    required String content,
  }) async {
    try {
      final String username = userData.benutzername ?? '';
      final String vorname = userData.vorname ?? '';
      final String nachname = userData.nachname ?? '';
      final String profilePic = userData.profilePictureUrl ?? '';
      final String role = userData.role ?? 'USER';

      await _comments.add({
        'postId': postId,
        'userId': userId,
        'username': username,
        'vorname': vorname,
        'nachname': nachname,
        'profilePictureUrl': profilePic,
        'role': role,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'dislikes': 0,
      });
    } catch (e) {
      print("[PostRepository] Fehler bei addComment(postId=$postId): $e");
      rethrow;
    }
  }

  /// Kommentar + zugehörige Replies + Reaktionen löschen
  Future<void> deleteCommentWithReplies(String commentId) async {
    try {
      final commentRef = _comments.doc(commentId);
      final commentSnap = await commentRef.get();
      if (!commentSnap.exists) {
        print(
            "[VideoRepository] deleteCommentWithReplies: Kommentar existiert nicht (id=$commentId)");
        return;
      }

      final batch = _firestore.batch();

      await _deleteSingleCommentWithReplies(
        commentRef: commentRef,
        batch: batch,
      );

      await batch.commit();

      print(
          "[VideoRepository] Kommentar + Replies + Reaktionen gelöscht (id=$commentId)");
    } catch (e) {
      print(
          "[VideoRepository] Fehler bei deleteCommentWithReplies(commentId=$commentId): $e");
      rethrow;
    }
  }

  Future<void> _deleteCommentsAndReplies(String videoId) async {
    final batch = _firestore.batch();

    // Kommentare zum Video
    final commentSnapshot =
    await _comments.where('videoId', isEqualTo: videoId).get();

    for (var commentDoc in commentSnapshot.docs) {
      await _deleteSingleCommentWithReplies(
        commentRef: commentDoc.reference,
        batch: batch,
      );
    }

    await batch.commit();
    print("Alle Kommentare, Antworten und Reaktionen erfolgreich gelöscht.");
  }

  /// Interner Helper: löscht genau EINEN Kommentar + alle Replies + Reaktionen
  Future<void> _deleteSingleCommentWithReplies({
    required DocumentReference commentRef,
    required WriteBatch batch,
  }) async {
    // Reaktionen des Kommentars
    await _deleteSubcollection(
      commentRef,
      'userInteractions',
      batch: batch,
    );

    // Replies zu diesem Kommentar
    final replySnapshot =
    await _replies.where('commentId', isEqualTo: commentRef.id).get();

    for (var replyDoc in replySnapshot.docs) {
      // userInteractions der Reply
      await _deleteSubcollection(
        replyDoc.reference,
        'userInteractions',
        batch: batch,
      );

      // Reply selbst löschen
      batch.delete(replyDoc.reference);
    }

    // Kommentar selbst löschen
    batch.delete(commentRef);
  }

  Future<void> _deleteSubcollection(
      DocumentReference parentDoc,
      String subcollectionName, {
        WriteBatch? batch,
      }) async {
    final subSnap = await parentDoc.collection(subcollectionName).get();
    if (subSnap.docs.isEmpty) return;

    final b = batch ?? _firestore.batch();
    for (var subDoc in subSnap.docs) {
      b.delete(subDoc.reference);
    }

    // Wenn kein Batch von außen übergeben wurde, hier selbst committen
    if (batch == null) {
      await b.commit();
    }
  }




  Query<Map<String, dynamic>> replyQuery(String commentId) {
    return FirebaseFirestore.instance
        .collection('replies')
        .where('commentId', isEqualTo: commentId)
        .orderBy('timestamp', descending: true);
  }

  Stream<int> repliesCountStream(String commentId) {
    return FirebaseFirestore.instance
        .collection('replies')
        .where('commentId', isEqualTo: commentId)
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Holt den Like/Dislike-Status für einen Kommentar
  Future<Map<String, bool>> getReplyLikeDislikeStatus({
    required String replyId,
    required String userId,
  }) async {
    try {
      final interactionRef = _replies
          .doc(replyId)
          .collection('userInteractions')
          .doc(userId);
      final snap = await interactionRef.get();

      if (!snap.exists) {
        return {
          'liked': false,
          'disliked': false,
        };
      }

      final data = snap.data() as Map<String, dynamic>;
      final bool liked = data['liked'] == true;
      final bool disliked = data['disliked'] == true;

      return {
        'liked': liked,
        'disliked': disliked,
      };
    } catch (e) {
      print(
          "[VideoRepository] Fehler bei getUserLikeDislikeStatus(replyId=$replyId, userId=$userId): $e");
      rethrow;
    }
  }

  Future<void> toggleLikeReply({
    required String replyId,
    required String userId,
    required bool isLiked,
    required bool isDisliked,
  }) async {
    final replyRef = _replies.doc(replyId);
    final interactionRef =
    replyRef.collection('userInteractions').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final replySnap = await transaction.get(replyRef);
        if (!replySnap.exists) {
          throw Exception("Reply existiert nicht (ID=$replyId)");
        }

        final replyData = replySnap.data() as Map<String, dynamic>;
        int currentLikes = (replyData['likes'] ?? 0) as int;
        int currentDislikes = (replyData['dislikes'] ?? 0) as int;

        bool newLiked = isLiked;
        bool newDisliked = isDisliked;

        if (!isLiked && !isDisliked) {
          // Noch nichts -> like setzen
          newLiked = true;
          currentLikes += 1;
        } else if (isLiked && !isDisliked) {
          // Like entfernen
          newLiked = false;
          currentLikes = (currentLikes > 0) ? currentLikes - 1 : 0;
        } else if (!isLiked && isDisliked) {
          // Dislike -> Like
          newLiked = true;
          newDisliked = false;
          currentLikes += 1;
          currentDislikes =
          (currentDislikes > 0) ? currentDislikes - 1 : 0;
        }

        transaction.update(replyRef, {
          'likes': currentLikes,
          'dislikes': currentDislikes,
        });

        transaction.set(
          interactionRef,
          {
            'liked': newLiked,
            'disliked': newDisliked,
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print("[VideoRepository] Fehler bei toggleLike(replyId=$replyId): $e");
      rethrow;
    }
  }

  /// Dislike-Logik:
  /// - Wenn bisher nichts: dislike +1
  /// - Wenn bereits disliked: dislike -1 (entfernen)
  /// - Wenn liked -> switch: like -1, dislike +1
  Future<void> toggleDislikeReply({
    required String replyId,
    required String userId,
    required bool isLiked,
    required bool isDisliked,
  }) async {
    final replyRef = _replies.doc(replyId);
    final interactionRef =
    replyRef.collection('userInteractions').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final replySnap = await transaction.get(replyRef);
        if (!replySnap.exists) {
          throw Exception("Reply existiert nicht (ID=$replyId)");
        }

        final replyData = replySnap.data() as Map<String, dynamic>;
        int currentLikes = (replyData['likes'] ?? 0) as int;
        int currentDislikes = (replyData['dislikes'] ?? 0) as int;

        bool newLiked = isLiked;
        bool newDisliked = isDisliked;

        if (!isLiked && !isDisliked) {
          // Noch nichts -> dislike setzen
          newDisliked = true;
          currentDislikes += 1;
        } else if (!isLiked && isDisliked) {
          // Dislike entfernen
          newDisliked = false;
          currentDislikes =
          (currentDislikes > 0) ? currentDislikes - 1 : 0;
        } else if (isLiked && !isDisliked) {
          // Like -> Dislike
          newLiked = false;
          newDisliked = true;
          currentLikes = (currentLikes > 0) ? currentLikes - 1 : 0;
          currentDislikes += 1;
        }

        transaction.update(replyRef, {
          'likes': currentLikes,
          'dislikes': currentDislikes,
        });

        transaction.set(
          interactionRef,
          {
            'liked': newLiked,
            'disliked': newDisliked,
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print(
          "[VideoRepository] Fehler bei toggleDislike(replyId=$replyId): $e");
      rethrow;
    }
  }

  Future<void> addReply({
    required String commentId,
    required String userId,
    required UserDto userData,
    required String content,
  }) async {
    try {
      final String username = userData.benutzername ?? '';
      final String profilePic = userData.profilePictureUrl ?? '';
      final String role = userData.role ?? 'USER';

      await _replies.add({
        'commentId': commentId,
        'userId': userId,
        'username': username,
        'profilePictureUrl': profilePic,
        'role': role,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'dislikes': 0,
      });
    } catch (e) {
      print("[VideoRepository] Fehler bei addReply(commentId=$commentId): $e");
      rethrow;
    }
  }

  Future<void> deleteReply(String replyId) async {
    try {
      final replyRef = _replies.doc(replyId);

      // Existenz prüfen (optional, aber nice für Debug)
      final replySnap = await replyRef.get();
      if (!replySnap.exists) {
        debugPrint("[VideoRepository] deleteReply: Reply existiert nicht (id=$replyId)");
        return;
      }

      // 1) Alle userInteractions löschen (ggf. in Seiten)
      QuerySnapshot<Map<String, dynamic>> reactionsSnap;

      while (true) {
        reactionsSnap = await replyRef
            .collection('userInteractions')
            .get();

        if (reactionsSnap.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in reactionsSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 2) Reply selbst löschen
      await replyRef.delete();

      debugPrint("[VideoRepository] Reply + userInteractions gelöscht (id=$replyId)");
    } catch (e) {
      debugPrint("[VideoRepository] Fehler bei deleteReply(replyId=$replyId): $e");
      rethrow;
    }
  }

}


