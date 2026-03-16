// lib/pages/profile_settings/widgets/logout_button.dart
import 'package:flutter/material.dart';

import '../../../services/PushService.dart';
import '../../LoginPage.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {



  bool isLoading = false;

  final AuthRepository _authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 15),
      child: ElevatedButton(
        onPressed: isLoading ? null : _logout,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          side: const BorderSide(color: Colors.white, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
      debugPrint("[LogoutButton] Logout start (uid=${_authRepository.currentUserId})");

      // 1) UI-Navigation sofort (fühlt sich schneller an)
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

      // 2) SignOut
      await PushService().removeCurrentToken();
      await widget.authRepository.signOut();

      debugPrint("[LogoutButton] Logout done");
      // Toast macht hier nur Sinn, wenn du nach LoginPage noch Kontext hast.
      // Deswegen lieber vor Navigation oder weglassen.
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
      setState(() => isLoading = false);
    }
  }

}
