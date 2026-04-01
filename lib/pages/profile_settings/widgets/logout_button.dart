import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../repositories/auth_repository.dart';
import '../../../services/PushService.dart';
import '../../../services/navigation_service.dart';
import '../../../util/HelperUtil.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    debugPrint("[LoginPage] build()");
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 15),
      child: ElevatedButton(
        onPressed: isLoading ? null : _logout,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          side: const BorderSide(color: Colors.white, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Ausloggen',
          style: TextStyle(fontSize: 25),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      debugPrint(
        "[LogoutButton] Logout start (uid=${widget.authRepository.currentUserId})",
      );

      await PushService().removeCurrentToken();
      await widget.authRepository.signOut();

      debugPrint("[LogoutButton] Logout done");

      // WICHTIG:
      // Alle zusätzlich geöffneten Seiten schließen,
      // damit die Root-Route mit AuthGate sichtbar wird.
      final navigator = NavigationService.navigatorKey.currentState;
      navigator?.popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint("[LogoutButton] Logout error: $e");

      if (!mounted) return;

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Ausloggen:\n$e",
        ),
        context: context,
      );

      if (mounted) {
        setState(() => isLoading = false);
      }

    }
  }
}