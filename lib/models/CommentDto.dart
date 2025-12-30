// lib/models/comment_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentDto {
  final String id;

  final String videoId;
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

  const CommentDto({
    required this.id,
    required this.videoId,
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
  factory CommentDto.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CommentDto(
      id: doc.id,
      videoId: data['videoId'] as String? ?? '',
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
  CommentDto copyWithUserReaction({
    bool? likedByCurrentUser,
    bool? dislikedByCurrentUser,
  }) {
    return CommentDto(
      id: id,
      videoId: videoId,
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
      'videoId': videoId,
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
