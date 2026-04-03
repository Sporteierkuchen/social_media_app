
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_media_app/services/PushService.dart';
import 'auth_gate.dart';
import 'constants/app_strings.dart';
import 'theme/app_colors.dart';
import 'services/local_notification_service.dart';
import 'services/navigation_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await LocalNotificationService.init();
  await PushService.handleIncomingMessage(message);

  debugPrint("[BG] Nachricht verarbeitet: ${message.data}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await LocalNotificationService.init();

  final NotificationAppLaunchDetails? launchDetails =
  await LocalNotificationService.plugin.getNotificationAppLaunchDetails();

  final String? initialLocalNotificationPayload =
  launchDetails?.didNotificationLaunchApp == true
      ? launchDetails?.notificationResponse?.payload
      : null;

  debugPrint(
    "[Main] initialLocalNotificationPayload=$initialLocalNotificationPayload",
  );

  runApp(
    MyApp(
      initialLocalNotificationPayload: initialLocalNotificationPayload,
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initialLocalNotificationPayload;

  const MyApp({
    super.key,
    this.initialLocalNotificationPayload,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AuthGate(
        initialLocalNotificationPayload: initialLocalNotificationPayload,
      ),
    );
  }
}