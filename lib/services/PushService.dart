import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../pages/BottomNavigationBar.dart';
import '../pages/post/Post.dart';
import '../repositories/post_repository.dart';
import 'local_notification_service.dart';
import 'navigation_service.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRepository _postRepository = PostRepository();

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

      await LocalNotificationService.showNotification(
        title: title,
        body: body,
        imageUrl: imageUrl,
        payload: payload,
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

}