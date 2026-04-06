import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../../widgets/TextInput.dart' as textfeld;

class EmailSection extends StatefulWidget {
  final UserDto userData;
  final UserRepository userRepository;
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

class _EmailSectionState extends State<EmailSection>
    with WidgetsBindingObserver {
  bool isEditing = false;
  bool isLoading = false;
  bool isRefreshingStatus = false;

  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    emailController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshVerificationStateSilently();
    }
  }

  void _fillControllerFromUser() {
    emailController.text = widget.userData.email ?? '';
  }

  bool get _isVerified =>
      widget.authRepository.currentUser?.emailVerified ?? false;

  String get _authEmail =>
      widget.authRepository.currentUser?.email?.trim() ?? '';

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
      child: isEditing ? _buildEditMode(context) : _buildViewMode(context),
    );
  }

  Widget _buildViewMode(BuildContext context) {
    final email = (widget.userData.email ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'E-Mail-Adresse',
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
              Row(
                children: [
                  Icon(
                    _isVerified ? Icons.check_circle : Icons.error_rounded,
                    color: _isVerified ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isVerified ? 'Verifiziert' : 'Nicht verifiziert',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isVerified ? Colors.green : Colors.red,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: isRefreshingStatus
                        ? null
                        : _refreshVerificationStateWithFeedback,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: isRefreshingStatus
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.refresh,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                email.isNotEmpty ? email : "Keine E-Mail vorhanden",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!_isVerified) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    GestureDetector(
                      onTap: isLoading ? null : _sendVerificationMail,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : const Text(
                          'Verifizieren',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      "Nach Klick auf den Mail-Link einfach zur App zurückkehren.",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ],
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
          'E-Mail-Adresse bearbeiten',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          child: textfeld.TextInput(
            label: "E-Mail",
            obscureText: false,
            controller: emailController,
            prefixIcon: const Icon(Icons.email),
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
                onTap: _onSaveEmail,
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
          text: "Bitte gib eine gültige E-Mail-Adresse ein.",
        ),
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
          title: const Text(
            "Passwort bestätigen",
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

  Future<void> _onSaveEmail() async {
    if (isLoading) return;
    if (!_validateEmail()) return;

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

    final password = await _askPassword();
    if (password == null) return;

    setState(() => isLoading = true);

    final newEmail = emailController.text.trim();

    try {
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

  Future<void> _sendVerificationMail() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
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

      await user.sendEmailVerification();

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.INFO,
          text: "Verifizierungs-E-Mail wurde an ${user.email} gesendet.",
        ),
      );
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

  Future<void> _refreshVerificationStateSilently() async {
    if (isRefreshingStatus) return;

    setState(() => isRefreshingStatus = true);

    try {
      final user = await widget.authRepository.reloadCurrentUser();
      if (user == null) return;

      final authEmail = user.email?.trim() ?? '';
      final docEmail = (widget.userData.email ?? '').trim();

      if (authEmail.isNotEmpty && authEmail != docEmail) {
        await widget.userRepository.updateEmailFieldInUserDoc(
          authEmail,
          widget.userData.userid!,
        );
      }

      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // bewusst still
    } finally {
      if (!mounted) return;
      setState(() => isRefreshingStatus = false);
    }
  }

  Future<void> _refreshVerificationStateWithFeedback() async {
    if (isRefreshingStatus) return;

    setState(() => isRefreshingStatus = true);

    try {
      final user = await widget.authRepository.reloadCurrentUser();
      if (user == null) {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.ERROR,
            text: "Nicht eingeloggt.",
          ),
        );
        return;
      }

      final authEmail = user.email?.trim() ?? '';
      final docEmail = (widget.userData.email ?? '').trim();

      if (authEmail.isNotEmpty && authEmail != docEmail) {
        final ok = await widget.userRepository.updateEmailFieldInUserDoc(
          authEmail,
          widget.userData.userid!,
        );

        if (ok) {
          HelperUtil.getToast(
            meldung: Meldung(
              meldungsart: Meldungsart.SUCCESS,
              text: "E-Mail wurde im Profil aktualisiert.",
            ),
          );
        }
      }

      if (user.emailVerified) {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.SUCCESS,
            text: "E-Mail ist jetzt verifiziert.",
          ),
        );
      } else {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.INFO,
            text: "E-Mail ist noch nicht verifiziert.",
          ),
        );
      }

      if (!mounted) return;
      setState(() {});
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
      setState(() => isRefreshingStatus = false);
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