import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/pages/LoginPage.dart';
import 'package:social_media_app/pages/authenticated_root.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        debugPrint(
          "[AuthGate] connection=${snapshot.connectionState}, "
              "hasData=${snapshot.hasData}, "
              "uid=${snapshot.data?.uid}",
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint("[AuthGate] Fehler: ${snapshot.error}");
          return const Scaffold(
            body: Center(child: Text("Fehler beim Laden der App.")),
          );
        }

        if (snapshot.data != null) {
          debugPrint("[AuthGate] -> AuthenticatedRoot");
          return const AuthenticatedRoot(index: 0);
        }

        debugPrint("[AuthGate] -> LoginPage");
        return const LoginPage();
      },
    );
  }
}