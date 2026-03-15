import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notification_service.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> init() async {
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
      // hier später Navigation zum Post
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("Foreground Nachricht: ${message.notification?.title}");
      debugPrint("Foreground Text: ${message.notification?.body}");
      debugPrint("Foreground Daten: ${message.data}");

      final title = message.notification?.title ?? "Neue Benachrichtigung";
      final body = message.notification?.body ?? "";
      final imageUrl = message.data["imageUrl"];

      await LocalNotificationService.showNotification(
        title: title,
        body: body,
        imageUrl: imageUrl,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification angeklickt: ${message.data}");
      // hier später Navigation zum Post
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
}