
import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyDto {
  final String id;

  final String commentId;
  final String userId;
  final String username;
  final String content;
  final String profilePictureUrl;
  final String role;

  final int likes;
  final int dislikes;

  final Timestamp? timestamp;

  /// Optional: Status für den AKTUELL eingeloggten User
  /// (aus Subcollection `userreactions`)
  final bool? likedByCurrentUser;
  final bool? dislikedByCurrentUser;

  const ReplyDto({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.username,
    required this.content,
    required this.profilePictureUrl,
    required this.role,
    required this.likes,
    required this.dislikes,
    required this.timestamp,
    this.likedByCurrentUser,
    this.dislikedByCurrentUser,
  });

  /// Aus Firestore-Dokument erstellen (ohne userreactions)
  factory ReplyDto.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReplyDto(
      id: doc.id,
      commentId: data['commentId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      content: data['content'] as String? ?? '',
      profilePictureUrl: data['profilePictureUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'USER',
      likes: _toIntSafe(data['likes']),
      dislikes: _toIntSafe(data['dislikes']),
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  /// DTO um Likes/Dislikes des aktuellen Users ergänzen
  /// (z. B. aus `comments/{commentId}/userreactions/{userId}`)
  ReplyDto copyWithUserReaction({
    bool? likedByCurrentUser,
    bool? dislikedByCurrentUser,
  }) {
    return ReplyDto(
      id: id,
      commentId: commentId,
      userId: userId,
      username: username,
      content: content,
      profilePictureUrl: profilePictureUrl,
      role: role,
      likes: likes,
      dislikes: dislikes,
      timestamp: timestamp,
      likedByCurrentUser:
      likedByCurrentUser ?? this.likedByCurrentUser,
      dislikedByCurrentUser:
      dislikedByCurrentUser ?? this.dislikedByCurrentUser,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'userId': userId,
      'username': username,
      'content': content,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      'likes': likes,
      'dislikes': dislikes,
      'timestamp': timestamp,
    };
  }

  // ---------- Helper ----------

  static int _toIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
