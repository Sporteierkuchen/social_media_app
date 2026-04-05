import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { video, image }

class PostDto {
  final String id;
  final PostType type;

  final String title;
  final String mediaUrl;
  final String thumbnailUrl;
  final String previewUrl;
  final String fullImageUrl;

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

  final String titleLower;
  final String fullNameLower;
  final String searchText;

  final bool? likedByCurrentUser;
  final bool? dislikedByCurrentUser;

  const PostDto({
    required this.id,
    required this.type,
    required this.title,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.previewUrl,
    required this.fullImageUrl,
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
    required this.titleLower,
    required this.fullNameLower,
    required this.searchText,
    this.likedByCurrentUser,
    this.dislikedByCurrentUser,
  });

  factory PostDto.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostDto.fromMap(doc.id, data);
  }

  factory PostDto.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PostDto.fromMap(doc.id, data);
  }

  factory PostDto.fromMap(String docId, Map<String, dynamic> data) {
    final typeStr = (data['type'] as String? ?? 'video').toLowerCase();
    final type = typeStr == 'image' ? PostType.image : PostType.video;

    final String mediaUrl = data['mediaUrl'] as String? ?? '';
    final String thumbnailUrl = data['thumbnailUrl'] as String? ?? '';
    final String previewUrl = data['previewUrl'] as String? ?? '';
    final String fullImageUrl = data['fullImageUrl'] as String? ?? '';

    final String vorname = data['vorname'] as String? ?? '';
    final String nachname = data['nachname'] as String? ?? '';
    final String title = data['title'] as String? ?? '';

    return PostDto(
      id: docId,
      type: type,
      title: title,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      previewUrl: previewUrl,
      fullImageUrl: fullImageUrl,
      userid: data['userid'] as String? ?? '',
      vorname: vorname,
      nachname: nachname,
      benutzername: data['benutzername'] as String? ?? '',
      profilePictureUrl: data['profilePictureUrl'] as String? ?? '',
      role: data['role'] as String? ?? 'USER',
      views: _toIntSafe(data['views']),
      likes: _toIntSafe(data['likes']),
      dislikes: _toIntSafe(data['dislikes']),
      categories: _toStringList(data['category']),
      timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),

      // neue Suchfelder mit Fallback für alte Dokumente
      titleLower:
      data['titleLower'] as String? ?? title.toLowerCase().trim(),
      fullNameLower: data['fullNameLower'] as String? ??
          "$vorname $nachname".toLowerCase().trim(),
      searchText: data['searchText'] as String? ??
          [
            title,
            vorname,
            nachname,
            "$vorname $nachname",
            data['benutzername'] as String? ?? '',
            ..._toStringList(data['category']),
          ].join(' ').toLowerCase().trim(),

      likedByCurrentUser: data['likedByCurrentUser'] as bool?,
      dislikedByCurrentUser: data['dislikedByCurrentUser'] as bool?,
    );
  }

  PostDto copyWithUserInteraction({
    bool? likedByCurrentUser,
    bool? dislikedByCurrentUser,
  }) {
    return PostDto(
      id: id,
      type: type,
      title: title,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      previewUrl: previewUrl,
      fullImageUrl: fullImageUrl,
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
      titleLower: titleLower,
      fullNameLower: fullNameLower,
      searchText: searchText,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      dislikedByCurrentUser:
      dislikedByCurrentUser ?? this.dislikedByCurrentUser,
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
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}