import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static void Function(String payload)? onNotificationTap;
  static final Map<String, String> _latestGroupPayloads = {};
  static final Map<String, String> _groupSummaryPayloads = {};
  static final Map<String, List<String>> _groupPostIds = {};

  static const String _defaultGroupKey = 'post_uploads_group';
  static const int _groupSummaryId = 999999;

  static Future<void> init() async {
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
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

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
        print("Fehler beim Laden des Bildes für Notification: $e");
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
        data["postIds"] = _groupPostIds[groupKey] ?? [];
        summaryPayload = jsonEncode(data);
      } catch (_) {}
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
}