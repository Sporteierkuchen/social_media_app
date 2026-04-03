import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../pages/chat_page/chat/chat_page.dart';
import '../pages/post/Post.dart';
import '../pages/post/creator_posts_page.dart';
import '../repositories/chat_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';
import 'app_shell_service.dart';
import 'chat_state_service.dart';
import 'content_state_service.dart';
import 'local_notification_service.dart';
import 'navigation_service.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  final ChatRepository _chatRepository = ChatRepository();

  static bool _initialized = false;
  static bool _isNavigating = false;

  Future<void> init() async {
    if (_initialized) {
      debugPrint("PushService bereits initialisiert.");
      return;
    }
    _initialized = true;

    LocalNotificationService.onNotificationTap = (String payload) async {
      try {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(jsonDecode(payload));

        final message = RemoteMessage(data: data);
        await _handleMessageNavigation(message);
      } catch (e) {
        debugPrint(
          "Fehler beim Verarbeiten des Local Notification Payloads: $e",
        );
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

      await PushService.handleIncomingMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint("Notification angeklickt: ${message.data}");
      await _handleMessageNavigation(message);
    });
  }

  static Future<void> handleIncomingMessage(RemoteMessage message) async {
    final action = message.data["action"]?.toString() ?? "";

    switch (action) {
      case "open_chat":
        await _handleIncomingChatMessage(message);
        return;

      case "open_creator_group":
        await _handleIncomingCreatorUpload(message);
        return;

      case "new_comment":
        await _handleIncomingComment(message);
        return;

      case "new_follower":
        await _handleIncomingFollower(message);
        return;

      default:
        await _handleIncomingDefault(message);
        return;
    }
  }

  static String _messageTitle(RemoteMessage message) {
    return message.data["title"]?.toString() ??
        message.notification?.title ??
        "Neue Benachrichtigung";
  }

  static String _messageBody(RemoteMessage message) {
    return message.data["body"]?.toString() ??
        message.notification?.body ??
        "";
  }

  static String _messagePayload(RemoteMessage message) {
    return jsonEncode(message.data);
  }

  static Future<void> _handleIncomingChatMessage(RemoteMessage message) async {
    final chatId = message.data["chatId"]?.toString() ?? "";
    final senderName = message.data["senderName"]?.toString() ?? "Unbekannt";

    if (chatId.isEmpty) return;

    if (ChatStateService.currentOpenChatId == chatId) {
      debugPrint("Chat $chatId ist offen -> keine lokale Notification.");
      return;
    }

    await LocalNotificationService.showChatNotification(
      chatId: chatId,
      senderName: senderName,
      title: _messageTitle(message),
      body: _messageBody(message),
      payload: _messagePayload(message),
    );
  }

  static Future<void> _handleIncomingCreatorUpload(
      RemoteMessage message,
      ) async {
    final title = _messageTitle(message);
    final body = _messageBody(message);
    final originalPayload = _messagePayload(message);

    final imageUrl = message.data["imageUrl"]?.toString();
    final creatorId = message.data["creatorId"]?.toString() ?? "unknown_creator";
    final type = (message.data["type"] ?? "post").toString().toLowerCase();
    final creatorName = message.data["creatorName"]?.toString() ??
        title.replaceFirst(RegExp(r'^[^\w]*Neues von '), '').trim();

    String groupKey = "creator_${creatorId}_post";
    String groupTitle = "Neue Uploads von $creatorName";

    if (type == "image" || type == "bild") {
      groupKey = "creator_${creatorId}_image";
      groupTitle = "📸 Neue Bilder von $creatorName";
    } else if (type == "video") {
      groupKey = "creator_${creatorId}_video";
      groupTitle = "🎬 Neue Videos von $creatorName";
    }

    final postId = message.data["postId"]?.toString();

    // Einzelnotification -> direkt Post öffnen
    final singlePayload = jsonEncode({
      ...message.data,
      "action": "open_post",
    });

    // Gruppensummary -> Creator-Gruppe öffnen
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
      payload: singlePayload,
      groupKey: groupKey,
      groupTitle: groupTitle,
      summaryPayload: summaryPayload,
      postId: postId,
    );
  }

  static Future<void> _handleIncomingComment(RemoteMessage message) async {
    await LocalNotificationService.showNotification(
      title: _messageTitle(message),
      body: _messageBody(message),
      payload: _messagePayload(message),
      groupKey: "comments_${message.data["postId"] ?? "unknown"}",
      groupTitle: "💬 Neue Kommentare",
    );
  }

  static Future<void> _handleIncomingFollower(RemoteMessage message) async {
    await LocalNotificationService.showNotification(
      title: _messageTitle(message),
      body: _messageBody(message),
      payload: _messagePayload(message),
      groupKey: "followers_group",
      groupTitle: "👥 Neue Abonnenten",
    );
  }

  static Future<void> _handleIncomingDefault(RemoteMessage message) async {
    await LocalNotificationService.showNotification(
      title: _messageTitle(message),
      body: _messageBody(message),
      payload: _messagePayload(message),
    );
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

  Future<void> _safeNavigate(Future<void> Function() action) async {
    if (_isNavigating) {
      debugPrint("Push-Navigation übersprungen: bereits Navigation aktiv.");
      return;
    }

    _isNavigating = true;
    try {
      await action();
    } finally {
      await Future.delayed(const Duration(milliseconds: 250));
      _isNavigating = false;
    }
  }

  bool _isCurrentRoute(String routeName) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return false;

    final route = ModalRoute.of(context);
    return route?.settings.name == routeName;
  }

  Future<void> _popToRootAndSetTab(int tabIndex) async {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint("Navigation nicht möglich: kein Navigator vorhanden.");
      return;
    }

    navigator.popUntil((route) => route.isFirst);
    AppShellService.setTab(tabIndex);

    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _handleMessageNavigation(RemoteMessage message) async {
    await _safeNavigate(() async {
      try {
        final action = message.data["action"]?.toString() ?? "";

        switch (action) {
          case "open_chat":
            await _navigateToChat(message.data);
            return;

          case "open_chat_group":
            await _navigateToChatGroup(message.data);
            return;

          case "open_chat_list":
            await _navigateToChatList();
            return;

          case "open_creator_group":
            await _navigateToCreatorGroup(message.data);
            return;

          case "open_post":
            await _navigateToPostDetail(message.data);
            return;

          case "new_comment":
            await _navigateToComment(message.data);
            return;

          case "new_follower":
            await _navigateToFollower(message.data);
            return;

          default:
            await _navigateToPostDetail(message.data);
            return;
        }
      } catch (e) {
        debugPrint("Fehler bei Push-Navigation: $e");
      }
    });
  }

  Future<void> _navigateToPostDetail(Map<String, dynamic> data) async {
    final postId = data["postId"];
    final currentUser = _auth.currentUser;

    if (postId == null || postId.toString().isEmpty) {
      debugPrint("Keine postId in der Push-Nachricht gefunden.");
      return;
    }

    if (currentUser == null) {
      debugPrint("Kein eingeloggter User vorhanden.");
      return;
    }

    if (ContentStateService.currentOpenPostId == postId.toString()) {
      debugPrint("Post ist bereits offen -> skip navigation");
      return;
    }

    final post = await _postRepository.getPostById(postId.toString());
    if (post == null) {
      debugPrint("Post mit ID $postId konnte nicht geladen werden.");
      return;
    }

    await _popToRootAndSetTab(0);

    if (_isCurrentRoute(PostDetailPage.routeName)) {
      debugPrint("PostDetailPage bereits oben -> skip push");
      return;
    }

    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint("Navigation nicht möglich: kein Navigator vorhanden.");
      return;
    }

    await navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: PostDetailPage.routeName),
        builder: (_) => PostDetailPage(
          post: post,
          userId: currentUser.uid,
        ),
      ),
    );
  }

  Future<void> _navigateToCreatorGroup(Map<String, dynamic> data) async {
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

    if (ContentStateService.currentOpenCreatorId == creatorId.toString()) {
      debugPrint("CreatorPostsPage ist bereits offen -> skip navigation");
      return;
    }

    final postIds = rawPostIds is List
        ? rawPostIds.map((e) => e.toString()).toList()
        : <String>[];

    final currentUserRole = await _userRepository.getUserRole(currentUser.uid);
    final creator = await _userRepository.getUserDetailsDto(
      creatorId.toString(),
    );

    if (creator == null) {
      debugPrint("Creator konnte nicht geladen werden.");
      return;
    }

    await _popToRootAndSetTab(0);

    if (_isCurrentRoute(CreatorPostsPage.routeName)) {
      debugPrint("CreatorPostsPage bereits oben -> skip push");
      return;
    }

    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint("Navigation nicht möglich: kein Navigator vorhanden.");
      return;
    }

    await navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: CreatorPostsPage.routeName),
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
  }

  Future<void> _navigateToChat(Map<String, dynamic> data) async {
    final chatId = data["chatId"];
    final senderId = data["senderId"];
    final currentUser = _auth.currentUser;

    if (chatId == null || senderId == null) {
      debugPrint("chatId oder senderId fehlt in Chat-Push.");
      return;
    }

    if (currentUser == null) {
      debugPrint("Kein eingeloggter User vorhanden.");
      return;
    }

    if (ChatStateService.currentOpenChatId == chatId.toString()) {
      debugPrint("Chat ist bereits offen -> skip navigation");
      return;
    }

    final me = await _userRepository.getUserDetailsDto(currentUser.uid);
    final other = await _userRepository.getUserDetailsDto(senderId.toString());

    if (me == null || other == null) {
      debugPrint("Chat-Teilnehmer konnten nicht geladen werden.");
      return;
    }

    await _popToRootAndSetTab(2);
    await LocalNotificationService.clearChatNotifications(chatId.toString());

    if (_isCurrentRoute(ChatPage.routeName)) {
      debugPrint("ChatPage bereits oben -> skip push");
      return;
    }

    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint("Navigation nicht möglich: kein Navigator vorhanden.");
      return;
    }

    await navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ChatPage.routeName),
        builder: (_) => ChatPage(
          chatId: chatId.toString(),
          me: me,
          other: other,
        ),
      ),
    );
  }

  Future<void> _navigateToChatGroup(Map<String, dynamic> data) async {
    final chatId = data["chatId"];
    final currentUser = _auth.currentUser;

    if (chatId == null || chatId.toString().isEmpty) {
      debugPrint("Keine chatId für Chat-Gruppen-Navigation gefunden.");
      return;
    }

    if (currentUser == null) {
      debugPrint("Kein eingeloggter User vorhanden.");
      return;
    }

    if (ChatStateService.currentOpenChatId == chatId.toString()) {
      debugPrint("Chat ist bereits offen -> skip navigation");
      return;
    }

    final me = await _userRepository.getUserDetailsDto(currentUser.uid);
    if (me == null) {
      debugPrint("Aktueller User konnte nicht geladen werden.");
      return;
    }

    final chatSnap = await _chatRepository.getChatById(chatId.toString());
    final chatData = chatSnap.data();

    if (!chatSnap.exists || chatData == null) {
      debugPrint("Chat konnte nicht geladen werden.");
      return;
    }

    final participants =
        (chatData["participants"] as List?)?.cast<String>() ?? [];

    final otherUid = participants.firstWhere(
          (uid) => uid != currentUser.uid,
      orElse: () => "",
    );

    if (otherUid.isEmpty) {
      debugPrint("Kein anderer Teilnehmer im Chat gefunden.");
      return;
    }

    final other = await _userRepository.getUserDetailsDto(otherUid);
    if (other == null) {
      debugPrint("Anderer Chat-Teilnehmer konnte nicht geladen werden.");
      return;
    }

    await _popToRootAndSetTab(2);
    await LocalNotificationService.clearChatNotifications(chatId.toString());

    if (_isCurrentRoute(ChatPage.routeName)) {
      debugPrint("ChatPage bereits oben -> skip push");
      return;
    }

    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint("Navigation nicht möglich: kein Navigator vorhanden.");
      return;
    }

    await navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: ChatPage.routeName),
        builder: (_) => ChatPage(
          chatId: chatId.toString(),
          me: me,
          other: other,
        ),
      ),
    );
  }

  Future<void> _navigateToChatList() async {
    await _popToRootAndSetTab(2);
  }

  Future<void> _navigateToComment(Map<String, dynamic> data) async {
    await _navigateToPostDetail(data);
  }

  Future<void> _navigateToFollower(Map<String, dynamic> data) async {
    debugPrint("Follower-Navigation noch nicht implementiert: $data");
  }

  Future<void> handleNotificationTapData(Map<String, dynamic> data) async {
    final message = RemoteMessage(data: data);
    await _handleMessageNavigation(message);
  }

}