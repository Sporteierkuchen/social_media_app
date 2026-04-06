import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../repositories/auth_repository.dart';
import '../../../services/PushService.dart';
import '../../../services/app_shell_service.dart';
import '../../../services/navigation_service.dart';
import '../../../util/HelperUtil.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({
    super.key,
    required this.authRepository,
  });

  final AuthRepository authRepository;

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sitzung",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Melde dich sicher von deinem Konto ab. Du kannst dich danach jederzeit wieder anmelden.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: isLoading
                ? const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.redAccent,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ausloggen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      AppShellService.reset();

      await HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Erfolgreich ausgeloggt",
        ),
      );

      debugPrint("[LogoutButton] Logout done");

      final navigator = NavigationService.navigatorKey.currentState;
      navigator?.popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint("[LogoutButton] Logout error: $e");

      await HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Ausloggen:\n$e",
        ),
      );

      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }
}