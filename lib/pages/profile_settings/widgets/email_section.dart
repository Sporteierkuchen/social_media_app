// lib/pages/profile_settings/widgets/email_section.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/user_repository.dart'; // ✅ neu
import '../../../util/HelperUtil.dart';
import '../../../widgets/TextInput.dart' as Textfeld;

class EmailSection extends StatefulWidget {
  final UserDto userData;
  final UserRepository userRepository; // ✅ neu
  final AuthRepository authRepository;

  const EmailSection({
    super.key,
    required this.userData,
    required this.userRepository,
    required this.authRepository,
  });

  @override
  State<EmailSection> createState() => _EmailSectionState();
}

class _EmailSectionState extends State<EmailSection> {
  bool isEditing = false;
  bool isLoading = false;

  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fillControllerFromUser();
  }

  @override
  void didUpdateWidget(covariant EmailSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isEditing && oldWidget.userData != widget.userData) {
      _fillControllerFromUser();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _fillControllerFromUser() {
    emailController.text = widget.userData.email ?? '';
  }

  bool get _isVerified =>
      widget.authRepository.currentUser?.emailVerified ?? false;

  @override
  Widget build(BuildContext context) {
    return isEditing ? _buildEditMode(context) : _buildViewMode(context);
  }

  // =========================
  // VIEW MODE
  // =========================
  Widget _buildViewMode(BuildContext context) {
    final email = widget.userData.email ?? '';

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      child: Padding(
        padding:
        const EdgeInsets.only(left: 25, right: 10, top: 20, bottom: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E-Mail-Adresse',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18),
                ),
                const SizedBox(height: 6),
                _isVerified
                    ? const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green, size: 22),
                    SizedBox(width: 6),
                    Text('Verifiziert',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 12)),
                  ],
                )
                    : const Row(
                  children: [
                    Icon(Icons.error_rounded,
                        color: Colors.red, size: 22),
                    SizedBox(width: 6),
                    Text('Nicht verifiziert',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(email,
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 15)),
                if (!_isVerified) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isLoading ? null : _onVerifyEmail,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : const Text(
                      'Verifizieren',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 15, top: 20, bottom: 20),
              child: GestureDetector(
                onTap: _onEdit,
                child: const Icon(Icons.edit_outlined,
                    color: Colors.orange, size: 30),
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
        padding:
        const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'E-Mail-Adresse',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 15),
                  Textfeld.TextInput(
                    label: "E-Mail",
                    obscureText: false,
                    controller: emailController,
                    prefixIcon: const Icon(Icons.email, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      isLoading
                          ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange),
                      )
                          : ElevatedButton(
                        onPressed: _onSaveEmail,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          side: const BorderSide(
                              color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Speichern',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _onCancel,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cancel_outlined, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Abbrechen',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
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
    _fillControllerFromUser();
    setState(() => isEditing = true);
  }

  void _onCancel() {
    if (isLoading) return;
    _fillControllerFromUser();
    setState(() => isEditing = false);
  }

  bool _validateEmail() {
    final newEmail = emailController.text.trim();
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      HelperUtil.getToast(
        meldung: Meldung(
            meldungsart: Meldungsart.WARNING,
            text: "Bitte gib eine gültige E-Mail-Adresse ein."),
      );
      return false;
    }
    return true;
  }

  Future<String?> _askPassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Passwort bestätigen",
              style: TextStyle(color: Colors.white)),
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

  Future<void> _onSaveEmail() async {
    if (isLoading) return;
    if (!_validateEmail()) return;

    final user = widget.authRepository.currentUser;
    if (user == null) {
      HelperUtil.getToast(
        meldung:
        Meldung(meldungsart: Meldungsart.ERROR, text: "Nicht eingeloggt."),
      );
      return;
    }

    final password = await _askPassword();
    if (password == null) return;

    setState(() => isLoading = true);

    final newEmail = emailController.text.trim();

    try {
      debugPrint("[EmailSection] ReAuth + verifyBeforeUpdateEmail -> $newEmail");

      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail);

      if (!mounted) return;

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.INFO,
          text:
          "E-Mail zur Verifizierung an $newEmail gesendet. Nach Bestätigung wird die Adresse geändert.",
        ),

      );

      _fillControllerFromUser();
      setState(() => isEditing = false);
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(meldungsart: Meldungsart.ERROR, text: e.toString()),

      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _onVerifyEmail() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      await widget.authRepository.currentUser?.reload();
      final user = widget.authRepository.currentUser;

      if (user == null) {
        HelperUtil.getToast(
          meldung:
          Meldung(meldungsart: Meldungsart.ERROR, text: "Nicht eingeloggt."),

        );
        return;
      }

      // ✅ WICHTIG: Nach reload() prüfen wir, ob Auth-Email jetzt anders ist.
      final authEmail = user.email ?? '';
      final docEmail = widget.userData.email ?? '';

      if (authEmail.isNotEmpty && authEmail != docEmail) {
        debugPrint("[EmailSection] Auth email changed -> update user doc: $authEmail");

        final ok = await widget.userRepository.updateEmailFieldInUserDoc(
          authEmail,
          widget.userData.userid!,
        );

        if (ok) {
          HelperUtil.getToast(
            meldung: Meldung(
              meldungsart: Meldungsart.SUCCESS,
              text: "E-Mail wurde übernommen und im Profil aktualisiert!",
            ),

          );
        } else {
          HelperUtil.getToast(
            meldung: Meldung(
              meldungsart: Meldungsart.WARNING,
              text: "E-Mail geändert, aber Profil-Daten konnten nicht aktualisiert werden.",
            ),

          );
        }
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.INFO,
            text: "Verifizierungs-E-Mail wurde an ${user.email} gesendet.",
          ),

        );
      } else {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.SUCCESS,
            text: "E-Mail ist bereits verifiziert!",
          ),

        );
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(meldungsart: Meldungsart.ERROR, text: e.toString()),

      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

}
