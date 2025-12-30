
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/repositories/auth_repository.dart';

import 'constants/app_strings.dart';
import 'theme/app_colors.dart';
import 'pages/BottomNavigationBar.dart';
import 'pages/LoginPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  debugPrint("[Main] Firebase initialisiert, starte App...");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AuthRepository _authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    debugPrint("[MyApp] build() aufgerufen");

    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: _authRepository.authStateChanges,
        builder: (context, snapshot) {
          // Nur loggen, wenn sich der Status wirklich ändert / relevant ist
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint("[MyApp] Auth-State: WAITING");
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            debugPrint("[MyApp] Auth-State: ERROR -> ${snapshot.error}");
            return const Scaffold(
              body: Center(child: Text("Fehler beim Laden der App.")),
            );
          }

          if (snapshot.hasData) {
            debugPrint(
              "[MyApp] Auth-State: LOGGED IN -> uid=${snapshot.data!.uid}",
            );
            return const BottomNavBar(index: 0);
          } else {
            debugPrint("[MyApp] Auth-State: LOGGED OUT -> LoginPage");
            return const LoginPage();
          }
        },
      ),
      // Wenn du später SplashScreen nutzen willst:
      // home: const SplashScreen(),
    );
  }
}
