import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'BottomNavigationBar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Logik direkt beim ersten Mount starten
    _loadMain();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/page/egon3.jpg",
              fit: BoxFit.scaleDown,
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.3,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
                top: 0,
              ),
              child: LoadingAnimationWidget.progressiveDots(
                color: Colors.orange,
                size: 120,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMain() async {
    // Optional: aktuellen User holen (falls du später damit was machen willst)
    final User? user = FirebaseAuth.instance.currentUser;
    // user wird aktuell nicht genutzt – aber die Zeile schadet nicht

    // Sicherstellen, dass das Widget noch im Tree ist
    if (!mounted) return;

    // Danach auf die Main-Seite wechseln
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const BottomNavBar(index: 0),
      ),
    );
  }
}
