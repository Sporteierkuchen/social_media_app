import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../pages/BottomNavigationBar.dart';
import '../pages/post/Post.dart';
import '../pages/post/creator_posts_page.dart';
import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';
import 'local_notification_service.dart';
import 'navigation_service.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();

  Future<void> init() async {

    LocalNotificationService.onNotificationTap = (String payload) async {
      try {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(jsonDecode(payload));

        final message = RemoteMessage(data: data);
        await _handleMessageNavigation(message);
      } catch (e) {
        debugPrint("Fehler beim Verarbeiten des Local Notification Payloads: $e");
      }
    };

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("Push permission: ${settings.authorizationStatus}");

    final token = await _messaging.getToken();
    debugPrint("FCM Token: $token");

    if (token != null) {
      await _saveToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint("Neuer FCM Token: $newToken");
      await _saveToken(newToken);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("App per Notification gestartet: ${initialMessage.data}");
      await _handleMessageNavigation(initialMessage);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("Foreground Nachricht: ${message.notification?.title}");
      debugPrint("Foreground Text: ${message.notification?.body}");
      debugPrint("Foreground Daten: ${message.data}");

      final title = message.notification?.title ?? "Neue Benachrichtigung";
      final body = message.notification?.body ?? "";
      final imageUrl = message.data["imageUrl"];
      final payload = jsonEncode(message.data);

      final postId = message.data["postId"];
      final creatorId = message.data["creatorId"] ?? "unknown_creator";
      final type = (message.data["type"] ?? "post").toString().toLowerCase();
      final creatorName = title.replaceFirst(RegExp(r'^[^\w]*Neues von '), '').trim();

      String groupKey = "creator_${creatorId}_post";
      String groupTitle = "Neue Uploads von $creatorName";

      if (type == "image" || type == "bild") {
        groupKey = "creator_${creatorId}_image";
        groupTitle = "📸 Neue Bilder von $creatorName";
      } else if (type == "video") {
        groupKey = "creator_${creatorId}_video";
        groupTitle = "🎬 Neue Videos von $creatorName";
      }

      final summaryPayload = jsonEncode({
        "action": "open_creator_group",
        "creatorId": creatorId,
        "type": type,
        "creatorName": creatorName,
      });

      await LocalNotificationService.showNotification(
        title: title,
        body: body,
        imageUrl: imageUrl,
        payload: payload,
        groupKey: groupKey,
        groupTitle: groupTitle,
        summaryPayload: summaryPayload,
        postId: postId,
      );

    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint("Notification angeklickt: ${message.data}");
      await _handleMessageNavigation(message);
    });

  }

  Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String platform = "unknown";
    if (!kIsWeb) {
      if (Platform.isAndroid) platform = "android";
      if (Platform.isIOS) platform = "ios";
    }

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("fcmTokens")
        .doc(token)
        .set({
      "token": token,
      "createdAt": FieldValue.serverTimestamp(),
      "platform": platform,
    }, SetOptions(merge: true));
  }

  Future<void> removeCurrentToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("fcmTokens")
        .doc(token)
        .delete()
        .catchError((e) {
      debugPrint("Fehler beim Löschen des FCM-Tokens: $e");
    });
  }

  Future<void> _handleMessageNavigation(RemoteMessage message) async {
    try {
      final action = message.data["action"];

      if (action == "open_creator_group") {
        await _openCreatorGroup(message.data);
        return;
      }

      final postId = message.data["postId"];
      final currentUser = _auth.currentUser;

      if (postId == null || postId.toString().isEmpty) {
        debugPrint("Keine postId in der Push-Nachricht gefunden.");
        return;
      }

      if (currentUser == null) {
        debugPrint("Kein eingeloggter User vorhanden.");
        return;
      }

      final post = await _postRepository.getPostById(postId.toString());

      if (post == null) {
        debugPrint("Post mit ID $postId konnte nicht geladen werden.");
        return;
      }

      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        debugPrint("Navigation nicht möglich: kein Context vorhanden.");
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const BottomNavBar(index: 0),
        ),
            (route) => false,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      final newContext = NavigationService.navigatorKey.currentContext;
      if (newContext == null) {
        debugPrint("Neuer Context nach BottomNavBar nicht verfügbar.");
        return;
      }

      Navigator.of(newContext).push(
        MaterialPageRoute(
          builder: (_) => PostDetailPage(
            post: post,
            userId: currentUser.uid,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Fehler bei Push-Navigation: $e");
    }
  }

  Future<void> _openCreatorGroup(Map<String, dynamic> data) async {
    try {
      final creatorId = data["creatorId"];
      final type = data["type"];
      final rawPostIds = data["postIds"];
      final currentUser = _auth.currentUser;

      if (creatorId == null || creatorId.toString().isEmpty) {
        debugPrint("Keine creatorId für Gruppen-Navigation gefunden.");
        return;
      }

      if (currentUser == null) {
        debugPrint("Kein eingeloggter User vorhanden.");
        return;
      }

      final postIds = rawPostIds is List
          ? rawPostIds.map((e) => e.toString()).toList()
          : <String>[];

      final currentUserRole = await _userRepository.getUserRole(currentUser.uid);
      final creator = await _userRepository.getUserDetailsDto(creatorId.toString());

      if (creator == null) {
        debugPrint("Creator konnte nicht geladen werden.");
        return;
      }

      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        debugPrint("Navigation nicht möglich: kein Context vorhanden.");
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const BottomNavBar(index: 0),
        ),
            (route) => false,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      final newContext = NavigationService.navigatorKey.currentContext;
      if (newContext == null) {
        debugPrint("Neuer Context nach BottomNavBar nicht verfügbar.");
        return;
      }

      Navigator.of(newContext).push(
        MaterialPageRoute(
          builder: (_) => CreatorPostsPage(
            creatorId: creatorId.toString(),
            currentUserId: currentUser.uid,
            currentUserRole: currentUserRole,
            type: type?.toString(),
            postIds: postIds,
            creator: creator,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Fehler bei Gruppen-Navigation: $e");
    }
  }

}