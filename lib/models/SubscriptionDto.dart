// lib/models/subscription_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionDto {
  final String id;

  final String subscribedToId;
  final String subscriberId;

  final String subscriberVorname;
  final String subscriberNachname;
  final String subscriberName;
  final String subscriberProfilePic;
  final String subscriberRole;

  final String subscriberToVorname;
  final String subscriberToNachname;
  final String subscriberToName;
  final String subscriberToProfilePic;
  final String subscriberToRole;

  final Timestamp? timestamp;

  const SubscriptionDto({
    required this.id,
    required this.subscribedToId,
    required this.subscriberId,
    required this.subscriberVorname,
    required this.subscriberNachname,
    required this.subscriberName,
    required this.subscriberProfilePic,
    required this.subscriberRole,
    required this.subscriberToVorname,
    required this.subscriberToNachname,
    required this.subscriberToName,
    required this.subscriberToProfilePic,
    required this.subscriberToRole,
    required this.timestamp,
  });

  /// Aus Firestore-Dokument erstellen
  factory SubscriptionDto.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return SubscriptionDto(
      id: doc.id,
      subscribedToId: data['subscribedToId'] as String? ?? '',
      subscriberId: data['subscriberId'] as String? ?? '',
      subscriberVorname: data['subscriberVorname'] as String? ?? '',
      subscriberNachname: data['subscriberNachname'] as String? ?? '',
      subscriberName: data['subscriberName'] as String? ?? '',
      subscriberProfilePic:
      data['subscriberProfilePic'] as String? ?? '',
      subscriberRole: data['subscriberRole'] as String? ?? 'USER',
      subscriberToVorname:
      data['subscriberToVorname'] as String? ?? '',
      subscriberToNachname:
      data['subscriberToNachname'] as String? ?? '',
      subscriberToName:
      data['subscriberToName'] as String? ?? '',
      subscriberToProfilePic:
      data['subscriberToProfilePic'] as String? ?? '',
      subscriberToRole:
      data['subscriberToRole'] as String? ?? 'USER',
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  factory SubscriptionDto.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return SubscriptionDto(
      id: doc.id,
      subscribedToId: data['subscribedToId'] as String? ?? '',
      subscriberId: data['subscriberId'] as String? ?? '',
      subscriberVorname: data['subscriberVorname'] as String? ?? '',
      subscriberNachname: data['subscriberNachname'] as String? ?? '',
      subscriberName: data['subscriberName'] as String? ?? '',
      subscriberProfilePic:
      data['subscriberProfilePic'] as String? ?? '',
      subscriberRole: data['subscriberRole'] as String? ?? 'USER',
      subscriberToVorname:
      data['subscriberToVorname'] as String? ?? '',
      subscriberToNachname:
      data['subscriberToNachname'] as String? ?? '',
      subscriberToName:
      data['subscriberToName'] as String? ?? '',
      subscriberToProfilePic:
      data['subscriberToProfilePic'] as String? ?? '',
      subscriberToRole:
      data['subscriberToRole'] as String? ?? 'USER',
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscribedToId': subscribedToId,
      'subscriberId': subscriberId,
      'subscriberVorname': subscriberVorname,
      'subscriberNachname': subscriberNachname,
      'subscriberName': subscriberName,
      'subscriberProfilePic': subscriberProfilePic,
      'subscriberRole': subscriberRole,
      'subscriberToVorname': subscriberToVorname,
      'subscriberToNachname': subscriberToNachname,
      'subscriberToName': subscriberToName,
      'subscriberToProfilePic': subscriberToProfilePic,
      'subscriberToRole': subscriberToRole,
      'timestamp': timestamp,
    };
  }
}
