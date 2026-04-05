import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static bool _initialized = false;

  static void Function(String payload)? onNotificationTap;
  static final Map<String, String> _latestGroupPayloads = {};
  static final Map<String, String> _groupSummaryPayloads = {};
  static final Map<String, List<String>> _groupPostIds = {};

  static const String _defaultGroupKey = 'post_uploads_group';
  static const int _groupSummaryId = 999999;

  static const String _chatGroupKey = 'all_chats_group';
  static const int _chatSummaryId = 888888;

  static final Map<String, int> _chatMessageCounts = {};
  static final Map<String, String> _chatLastPayloads = {};
  static final Map<String, String> _chatSenderNames = {};
  static final Map<String, String> _chatLastBodies = {};

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && onNotificationTap != null) {
          onNotificationTap!(payload);
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Wichtige Benachrichtigungen',
      description: 'Zeigt Push Benachrichtigungen im Vordergrund an',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? payload,
    String? groupKey,
    String? groupTitle,
    String? summaryPayload,
    String? postId,
  }) async {
    final String effectiveGroupKey = groupKey ?? _defaultGroupKey;
    final String effectiveGroupTitle = groupTitle ?? 'Neue Uploads';

    final int notificationId =
    DateTime.now().microsecondsSinceEpoch.remainder(2147483647);

    if (postId != null && postId.isNotEmpty) {
      final existing = _groupPostIds[effectiveGroupKey] ?? [];

      if (!existing.contains(postId)) {
        existing.add(postId);
      }

      _groupPostIds[effectiveGroupKey] = existing;
    }

    if (payload != null) {
      _latestGroupPayloads[effectiveGroupKey] = payload;
    }

    if (summaryPayload != null) {
      _groupSummaryPayloads[effectiveGroupKey] = summaryPayload;
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String filePath = await _downloadAndSaveFile(
          imageUrl,
          'push_image_$notificationId.jpg',
        );

        final bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
          contentTitle: title,
          summaryText: body,
        );

        final androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'Wichtige Benachrichtigungen',
          channelDescription: 'Zeigt Push Benachrichtigungen im Vordergrund an',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: bigPictureStyle,
          groupKey: effectiveGroupKey,
        );

        final details = NotificationDetails(android: androidDetails);

        await _plugin.show(
          notificationId,
          title,
          body,
          details,
          payload: payload,
        );

        await _showGroupSummary(
          groupKey: effectiveGroupKey,
          groupTitle: effectiveGroupTitle,
        );
        return;
      } catch (e) {
        debugPrint("Fehler beim Anzeigen der Bild-Notification: $e");
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Wichtige Benachrichtigungen',
      channelDescription: 'Zeigt Push Benachrichtigungen im Vordergrund an',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: effectiveGroupKey,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );

    await _showGroupSummary(
      groupKey: effectiveGroupKey,
      groupTitle: effectiveGroupTitle,
    );
  }

  static Future<void> _showGroupSummary({
    required String groupKey,
    required String groupTitle,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Wichtige Benachrichtigungen',
      channelDescription: 'Zeigt Push Benachrichtigungen im Vordergrund an',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: groupKey,
      setAsGroupSummary: true,
      styleInformation: const InboxStyleInformation([]),
    );

    final details = NotificationDetails(android: androidDetails);

    String? summaryPayload =
        _groupSummaryPayloads[groupKey] ?? _latestGroupPayloads[groupKey];

    if (_groupSummaryPayloads[groupKey] != null && summaryPayload != null) {
      try {
        final data = Map<String, dynamic>.from(jsonDecode(summaryPayload));
        final postIds = _groupPostIds[groupKey];

        if (postIds != null && postIds.isNotEmpty) {
          data["postIds"] = postIds;
        }

        summaryPayload = jsonEncode(data);
      } catch (e) {
        debugPrint("Fehler beim Erstellen des Summary-Payloads: $e");
      }
    }

    await _plugin.show(
      _groupSummaryId + groupKey.hashCode,
      groupTitle,
      'Mehrere neue Benachrichtigungen',
      details,
      payload: summaryPayload,
    );
  }

  static Future<String> _downloadAndSaveFile(
      String url,
      String fileName,
      ) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName';

    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);

    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }

  static int _chatNotificationId(String chatId) {
    return chatId.hashCode & 0x7fffffff;
  }

  static Future<void> showChatNotification({
    required String chatId,
    required String senderName,
    required String title,
    required String body,
    required String payload,
  }) async {
    _chatMessageCounts[chatId] = (_chatMessageCounts[chatId] ?? 0) + 1;
    _chatLastPayloads[chatId] = payload;
    _chatSenderNames[chatId] = senderName;
    _chatLastBodies[chatId] = body;

    final count = _chatMessageCounts[chatId] ?? 1;

    final effectiveTitle = "💬 $senderName";
    final effectiveBody = count > 1 ? "$count neue Nachrichten" : body;

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Wichtige Benachrichtigungen',
      channelDescription: 'Zeigt Push Benachrichtigungen im Vordergrund an',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: _chatGroupKey,
      tag: 'chat_$chatId',
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      _chatNotificationId(chatId),
      effectiveTitle,
      effectiveBody,
      details,
      payload: payload,
    );

    await _showChatSummary();
  }

  static Future<void> _showChatSummary() async {
    if (_chatMessageCounts.isEmpty) {
      await _plugin.cancel(_chatSummaryId);
      return;
    }

    final totalChats = _chatMessageCounts.length;
    final totalMessages = _chatMessageCounts.values.fold<int>(
      0,
          (sum, count) => sum + count,
    );

    if (totalChats == 1) {
      await _plugin.cancel(_chatSummaryId);
      return;
    }

    final lines = _chatMessageCounts.entries.map((entry) {
      final senderName = _chatSenderNames[entry.key] ?? "Unbekannt";
      final count = entry.value;
      return count == 1
          ? "1 Nachricht von $senderName"
          : "$count Nachrichten von $senderName";
    }).toList();

    final summaryBody = "$totalMessages neue Nachrichten in $totalChats Chats";

    final inboxStyle = InboxStyleInformation(
      lines,
      contentTitle: "💬 Neue Nachrichten",
      summaryText: summaryBody,
    );

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Wichtige Benachrichtigungen',
      channelDescription: 'Zeigt Push Benachrichtigungen im Vordergrund an',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: _chatGroupKey,
      setAsGroupSummary: true,
      styleInformation: inboxStyle,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      _chatSummaryId,
      "💬 Neue Nachrichten",
      summaryBody,
      details,
      payload: '{"action":"open_chat_list"}',
    );
  }

  static Future<void> clearChatNotifications(String chatId) async {
    _chatMessageCounts.remove(chatId);
    _chatLastPayloads.remove(chatId);
    _chatSenderNames.remove(chatId);
    _chatLastBodies.remove(chatId);

    try {
      await _plugin.cancel(_chatNotificationId(chatId));
    } catch (e, s) {
      debugPrint("Fehler cancel chat notification: $e");
      debugPrint("$s");
    }

    if (_chatMessageCounts.isEmpty) {
      try {
        await _plugin.cancel(_chatSummaryId);
      } catch (e, s) {
        debugPrint("Fehler cancel summary notification: $e");
        debugPrint("$s");
      }
    } else {
      await _showChatSummary();
    }
  }

}