// lib/pages/profile_settings/widgets/password_section.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../../widgets/TextInput.dart' as Textfeld;

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
    return isEditing ? _buildEditMode(context) : _buildViewMode();
  }

  // =========================
  // VIEW MODE
  // =========================
  Widget _buildViewMode() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 25, right: 10, top: 20, bottom: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Textbereich
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Passwort',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '********',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            // Edit-Icon
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 15, top: 20, bottom: 20),
              child: GestureDetector(
                onTap: _onEdit,
                child: const Icon(Icons.edit_outlined, color: Colors.orange, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // EDIT MODE
  // =========================
  Widget _buildEditMode(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Passwort ändern',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Textfeld.TextInput(
                    label: "Neues Passwort",
                    obscureText: true,
                    controller: newPasswordController,
                    prefixIcon: const Icon(Icons.password, color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  Textfeld.TextInput(
                    label: "Neues Passwort wiederholen",
                    obscureText: true,
                    controller: repeatPasswordController,
                    prefixIcon: const Icon(Icons.password, color: Colors.white),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      isLoading
                          ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      )
                          : ElevatedButton(
                        onPressed: _onSavePassword,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Speichern',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      ElevatedButton(
                        onPressed: _onCancel,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cancel_outlined, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Abbrechen',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // ACTIONS
  // =========================
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
        context: context,
      );
      return false;
    }

    if (p1.length < 6) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Das Passwort muss mindestens 6 Zeichen lang sein.",
        ),
        context: context,
      );
      return false;
    }

    if (p1 != p2) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Die Passwörter stimmen nicht überein.",
        ),
        context: context,
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
          title: const Text("Altes Passwort bestätigen", style: TextStyle(color: Colors.white)),
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
        meldung: Meldung(meldungsart: Meldungsart.ERROR, text: "Nicht eingeloggt."),
        context: context,
      );
      return;
    }

    // ✅ ReAuth braucht das alte Passwort -> Dialog
    final oldPassword = await _askCurrentPassword();
    if (oldPassword == null) return;

    setState(() => isLoading = true);

    final newPw = newPasswordController.text.trim();

    try {
      debugPrint("[PasswordSection] ReAuth + updatePassword");

      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPw);

      // Optional: Falls du serverseitig/DB noch was spiegeln willst:
      // -> Bitte NICHT in Firestore speichern. Wenn du es wirklich brauchst,
      // mach’s sicher in deinem Backend.
      // await widget.userRepository.updatePasswordInBackend(newPw, user.uid);

      if (!mounted) return;

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Passwort wurde geändert!",
        ),
        context: context,
      );

      setState(() => isEditing = false);
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(meldungsart: Meldungsart.ERROR, text: e.toString()),
        context: context,
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

}
