import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../../widgets/TextInput.dart' as textfeld;

class PasswordSection extends StatefulWidget {
  final UserDto userData;
  final UserRepository userRepository;
  final AuthRepository authRepository;

  const PasswordSection({
    super.key,
    required this.userData,
    required this.userRepository,
    required this.authRepository,
  });

  @override
  State<PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends State<PasswordSection> {
  bool isEditing = false;
  bool isLoading = false;

  final newPasswordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  @override
  void dispose() {
    newPasswordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18, bottom: 6),
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
      child: isEditing ? _buildEditMode(context) : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Passwort',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Sicherheit',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '********',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: _onEdit,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                color: Colors.orange,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Passwort ändern',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textfeld.TextInput(
                label: "Neues Passwort",
                obscureText: true,
                controller: newPasswordController,
                prefixIcon: const Icon(Icons.password),
              ),
              const SizedBox(height: 14),
              textfeld.TextInput(
                label: "Neues Passwort wiederholen",
                obscureText: true,
                controller: repeatPasswordController,
                prefixIcon: const Icon(Icons.password_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            else ...[
              GestureDetector(
                onTap: _onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Abbrechen',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _onSavePassword,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_outlined, color: Colors.black, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Speichern',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _onEdit() {
    newPasswordController.clear();
    repeatPasswordController.clear();
    setState(() => isEditing = true);
  }

  void _onCancel() {
    if (isLoading) return;
    newPasswordController.clear();
    repeatPasswordController.clear();
    setState(() => isEditing = false);
  }

  bool _validate() {
    final p1 = newPasswordController.text.trim();
    final p2 = repeatPasswordController.text.trim();

    if (p1.isEmpty || p2.isEmpty) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Bitte gib dein neues Passwort ein und wiederhole es.",
        ),
      );
      return false;
    }

    if (p1.length < 6) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Das Passwort muss mindestens 6 Zeichen lang sein.",
        ),
      );
      return false;
    }

    if (p1 != p2) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Die Passwörter stimmen nicht überein.",
        ),
      );
      return false;
    }

    return true;
  }

  Future<String?> _askCurrentPassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "Altes Passwort bestätigen",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Aktuelles Passwort",
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text("Bestätigen"),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _onSavePassword() async {
    if (isLoading) return;
    if (!_validate()) return;

    final user = widget.authRepository.currentUser;
    if (user == null) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Nicht eingeloggt.",
        ),
      );
      return;
    }

    final oldPassword = await _askCurrentPassword();
    if (oldPassword == null) return;

    setState(() => isLoading = true);

    final newPw = newPasswordController.text.trim();

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPw);

      if (!mounted) return;

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Passwort wurde geändert!",
        ),
      );

      setState(() => isEditing = false);
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: e.toString(),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}