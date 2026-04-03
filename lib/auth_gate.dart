import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/services/PushService.dart';
import 'pages/LoginPage.dart';
import 'pages/authenticated_root.dart';


class AuthGate extends StatefulWidget {
  final String? initialLocalNotificationPayload;

  const AuthGate({
    super.key,
    this.initialLocalNotificationPayload,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _handledInitialLocalNotification = false;

  Future<void> _tryHandleInitialLocalNotification() async {
    if (_handledInitialLocalNotification) return;

    final payload = widget.initialLocalNotificationPayload;
    if (payload == null || payload.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint("[AuthGate] Kein eingeloggter User für Initial-Payload.");
      return;
    }

    _handledInitialLocalNotification = true;

    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload));
      debugPrint("[AuthGate] Initial-Payload: $data");

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        await PushService().handleNotificationTapData(data);
      });
    } catch (e) {
      debugPrint("[AuthGate] Fehler beim Initial-Payload: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Fehler beim Laden der App.")),
          );
        }

        if (snapshot.hasData) {
          _tryHandleInitialLocalNotification();
          return const AuthenticatedRoot(index: 0);
        }

        return const LoginPage();
      },
    );
  }
}