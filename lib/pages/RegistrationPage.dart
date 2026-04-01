import 'package:flutter/material.dart';
import '../models/Meldung.dart';
import '../repositories/auth_repository.dart';
import '../util/HelperUtil.dart';
import '../widgets/TextInput.dart';
import '../widgets/Captcha/Captcha_tile.dart';
import 'LoginPage.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => RegistrationpageState();
}

class RegistrationpageState extends State<RegistrationPage> {
  final AuthRepository _authRepository = AuthRepository();

  bool isLoading = false;
  String errorMessage = "";
  bool canPop = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordController2 = TextEditingController();

  /// Wurde die Captcha korrekt gelöst?
  bool captchaSolved = false;

  // Anzahl der bisherigen Fehler (Captcha oder Eingaben)
  int warningCounter = 0;

  // Max. Anzahl Warnungen bevor Bestrafung
  static const int maxWarnings = 3;

  // ------------------------------------------------------------
  // 🎨 Dark-Theme Konstanten (passend zu background.png)
  // ------------------------------------------------------------
  static const Color _titleColor = Colors.white;
  static const Color _textSecondary = Colors.white70;
  static const Color _accent = Colors.orange;

  static const Color _inputFill = Color(0x660B1220); // navy, transparent
  static const Color _border = Color(0x33FFFFFF);    // white, transparent

  // Optional: “Card” Look um Inputs (wenn du willst)
  static const Color _card = Color(0x22000000);

  @override
  void initState() {
    super.initState();
    // print("Init State RegisterPage");
  }

  @override
  void dispose() {
    usernameController.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/page/background.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Titel
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                          alignment: Alignment.center,
                          child: const Text(
                            "Konto erstellen",
                            style: TextStyle(
                              fontSize: 35,
                              height: 1.0,
                              color: _titleColor,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // -------------------------
                        // Inputs (Dark style)
                        // -------------------------
                        _inputCard(
                          child: TextInput(
                            label: "Benutzername",
                            obscureText: false,
                            controller: usernameController,
                            prefixIcon: const Icon(Icons.person_pin),
                            textColor: Colors.white,
                            labelColor: _textSecondary,
                            iconColor: _textSecondary,
                            cursorColor: _accent,
                            fillColor: _inputFill,
                            enabledBorderColor: _border,
                            focusedBorderColor: _accent,
                          ),
                        ),

                        _inputCard(
                          child: TextInput(
                            label: "Vorname",
                            obscureText: false,
                            controller: firstnameController,
                            prefixIcon: const Icon(Icons.person),
                            textColor: Colors.white,
                            labelColor: _textSecondary,
                            iconColor: _textSecondary,
                            cursorColor: _accent,
                            fillColor: _inputFill,
                            enabledBorderColor: _border,
                            focusedBorderColor: _accent,
                          ),
                        ),

                        _inputCard(
                          child: TextInput(
                            label: "Nachname",
                            obscureText: false,
                            controller: lastnameController,
                            prefixIcon: const Icon(Icons.person),
                            textColor: Colors.white,
                            labelColor: _textSecondary,
                            iconColor: _textSecondary,
                            cursorColor: _accent,
                            fillColor: _inputFill,
                            enabledBorderColor: _border,
                            focusedBorderColor: _accent,
                          ),
                        ),

                        _inputCard(
                          child: TextInput(
                            label: "Email",
                            obscureText: false,
                            controller: emailController,
                            prefixIcon: const Icon(Icons.email),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            textColor: Colors.white,
                            labelColor: _textSecondary,
                            iconColor: _textSecondary,
                            cursorColor: _accent,
                            fillColor: _inputFill,
                            enabledBorderColor: _border,
                            focusedBorderColor: _accent,
                          ),
                        ),

                        _inputCard(
                          child: TextInput(
                            label: "Passwort",
                            obscureText: true,
                            controller: passwordController,
                            prefixIcon: const Icon(Icons.key),
                            textInputAction: TextInputAction.next,
                            textColor: Colors.white,
                            labelColor: _textSecondary,
                            iconColor: _textSecondary,
                            cursorColor: _accent,
                            fillColor: _inputFill,
                            enabledBorderColor: _border,
                            focusedBorderColor: _accent,
                          ),
                        ),

                        _inputCard(
                          child: TextInput(
                            label: "Passwort wiederholen",
                            obscureText: true,
                            controller: passwordController2,
                            prefixIcon: const Icon(Icons.key),
                            textInputAction: TextInputAction.done,
                            textColor: Colors.white,
                            labelColor: _textSecondary,
                            iconColor: _textSecondary,
                            cursorColor: _accent,
                            fillColor: _inputFill,
                            enabledBorderColor: _border,
                            focusedBorderColor: _accent,
                          ),
                        ),

                        // Captcha
                        CaptchaTile(
                          solved: captchaSolved,
                          onSolvedChanged: (bool value) {
                            if (!value) _handleWarning();
                            setState(() => captchaSolved = value);
                          },
                          okBilderList: const [
                            "assets/images/captcha/ok1.png",
                            "assets/images/captcha/ok2.png",
                            "assets/images/captcha/ok3.png",
                            "assets/images/captcha/ok4.png",
                            "assets/images/captcha/ok5.png",
                          ],
                          filterBilderList: const [
                            "assets/images/captcha/baum1.png",
                            "assets/images/captcha/baum2.png",
                            "assets/images/captcha/baum3.png",
                            "assets/images/captcha/baum4.png",
                            "assets/images/captcha/baum5.png",
                            "assets/images/captcha/baum6.png",
                            "assets/images/captcha/baum7.png",
                            "assets/images/captcha/baum8.png",
                            "assets/images/captcha/baum9.png",
                            "assets/images/captcha/baum10.png",
                          ],
                          suchwort: "Bäumen",
                        ),

                        // Button
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          child: isLoading
                              ? const CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(_accent),
                          )
                              : ElevatedButton(
                            onPressed: _onRegisterPressed,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.fromLTRB(
                                30,
                                12,
                                30,
                                12,
                              ),
                              textStyle: const TextStyle(fontSize: 20),
                              backgroundColor: _accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Konto erstellen",
                              style: TextStyle(
                                fontSize: 20,
                                height: 1.0,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Login-Hinweis
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: const Text(
                            "Haben Sie ein Konto?",
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.0,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          child: InkWell(
                            child: const Text(
                              "Anmelden",
                              style: TextStyle(
                                color: _accent,
                                fontSize: 16,
                                height: 1.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              if (!isLoading) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optional: Wrapper für Input-Look (macht’s “sauberer” auf dunklem BG)
  Widget _inputCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Gemeinsame Warnungs-/Bestrafungslogik
  // ---------------------------------------------------------------------------
  void _handleWarning() {
    if (warningCounter < maxWarnings) {
      warningCounter++;
    } else {
      warningCounter = 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Button-Handler
  // ---------------------------------------------------------------------------
  Future<void> _onRegisterPressed() async {
    setState(() {
      isLoading = true;
      canPop = false;
    });

    if (await checkUserInput()) {
      await _register();
    } else {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: errorMessage,
        ),
        context: context,
      );
      _handleWarning();
    }

    if (mounted) {
      setState(() {
        isLoading = false;
        canPop = true;
      });
    }
  }

  Future<void> _register() async {
    final Meldung meldung = await _authRepository.registerUser(
      benutzername: usernameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      vorname: firstnameController.text.trim(),
      nachname: lastnameController.text.trim(),
    );

    if (!mounted) return;

    HelperUtil.getToast(meldung: meldung, context: context);

    if (meldung.meldungsart == Meldungsart.SUCCESS) {
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Eingabeprüfung inkl. Nickname-Check + Captcha
  // ---------------------------------------------------------------------------
  Future<bool> checkUserInput() async {
    final buffer = StringBuffer();

    final nickname = usernameController.text.trim();
    final firstname = firstnameController.text.trim();
    final lastname = lastnameController.text.trim();
    final email = emailController.text.trim();
    final pass1 = passwordController.text.trim();
    final pass2 = passwordController2.text.trim();

    if (nickname.isEmpty) {
      buffer.writeln("Gebe deinen Benutzernamen ein!");
    } else {
      try {
        final available = await _authRepository.isNicknameAvailable(nickname);
        if (!available) {
          buffer.writeln("Dieser Benutzername ist bereits vergeben!");
        }
      } catch (e) {
        buffer.writeln("Benutzername konnte gerade nicht geprüft werden.");
      }
    }

    if (firstname.isEmpty) buffer.writeln("Gebe deinen Vornamen ein!");
    if (lastname.isEmpty) buffer.writeln("Gebe deinen Nachnamen ein!");
    if (email.isEmpty) buffer.writeln("Gebe deine E-Mail Adresse ein!");

    if (pass1.isEmpty) {
      buffer.writeln("Du musst ein Passwort festlegen!");
    } else if (pass2 != pass1) {
      buffer.writeln("Die Passwörter stimmen nicht überein!");
    }

    if (!captchaSolved) {
      buffer.writeln("Bestätige, dass du kein Roboter bist!");
    }

    errorMessage = buffer.toString();
    return errorMessage.isEmpty;
  }
}
