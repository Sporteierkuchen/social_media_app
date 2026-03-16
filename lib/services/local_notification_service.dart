import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static void Function(String payload)? onNotificationTap;

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
  }) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String filePath = await _downloadAndSaveFile(
          imageUrl,
          'push_image.jpg',
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
        );

        final details = NotificationDetails(android: androidDetails);

        await _plugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          details,
          payload: payload,
        );
        return;
      } catch (e) {
        print("Fehler beim Laden des Bildes für Notification: $e");
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Wichtige Benachrichtigungen',
      channelDescription: 'Zeigt Push Benachrichtigungen im Vordergrund an',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
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