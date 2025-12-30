import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { video, image }

class PostDto {
  final String id;
  final PostType type;

  final String title;
  final String mediaUrl;
  final String thumbnailUrl; // bei image kann leer sein
  final String userid;

  final String vorname;
  final String nachname;
  final String benutzername;
  final String profilePictureUrl;
  final String role;

  final int views;
  final int likes;
  final int dislikes;
  final List<String> categories;
  final Timestamp timestamp;

  final bool? likedByCurrentUser;
  final bool? dislikedByCurrentUser;

  const PostDto({
    required this.id,
    required this.type,
    required this.title,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.userid,
    required this.vorname,
    required this.nachname,
    required this.benutzername,
    required this.profilePictureUrl,
    required this.role,
    required this.views,
    required this.likes,
    required this.dislikes,
    required this.categories,
    required this.timestamp,
    this.likedByCurrentUser,
    this.dislikedByCurrentUser,
  });

  factory PostDto.fromDoc(DocumentSnapshot doc) {

    final data = doc.data() as Map<String, dynamic>? ?? {};

    final typeStr = (data['type'] as String? ?? 'post').toLowerCase();
    final type = (typeStr == 'image') ? PostType.image : PostType.video;

    return PostDto(
      id: doc.id,
      type: type,
      title: data['title'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      userid: data['userid'] as String? ?? '',
      vorname: data['vorname'] as String? ?? '',
      nachname: data['nachname'] as String? ?? '',
      benutzername: data['benutzername'] as String? ?? '',
      profilePictureUrl: data['profilePictureUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'USER',
      views: _toIntSafe(data['views']),
      likes: _toIntSafe(data['likes']),
      dislikes: _toIntSafe(data['dislikes']),
      categories: _toStringList(data['category']),
      timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  PostDto copyWithUserInteraction({bool? likedByCurrentUser, bool? dislikedByCurrentUser}) {
    return PostDto(
      id: id,
      type: type,
      title: title,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      userid: userid,
      vorname: vorname,
      nachname: nachname,
      benutzername: benutzername,
      profilePictureUrl: profilePictureUrl,
      role: role,
      views: views,
      likes: likes,
      dislikes: dislikes,
      categories: categories,
      timestamp: timestamp,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      dislikedByCurrentUser: dislikedByCurrentUser ?? this.dislikedByCurrentUser,
    );
  }

  factory PostDto.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final typeStr = (data['type'] as String? ?? 'post').toLowerCase();
    final type = typeStr == 'image' ? PostType.image : PostType.video;

    return PostDto(
      id: doc.id,
      type: type,
      title: data['title'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      userid: data['userid'] as String? ?? '',
      vorname: data['vorname'] as String? ?? '',
      nachname: data['nachname'] as String? ?? '',
      benutzername: data['benutzername'] as String? ?? '',
      profilePictureUrl: data['profilePictureUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'USER',
      views: _toIntSafe(data['views']),
      likes: _toIntSafe(data['likes']),
      dislikes: _toIntSafe(data['dislikes']),
      categories: _toStringList(data['category']),
      timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  static int _toIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}
