import 'package:flutter/material.dart';
import '../models/Meldung.dart';
import '../repositories/auth_repository.dart';
import '../util/HelperUtil.dart';
import '../widgets/TextInput.dart';
import '../widgets/Captcha/Captcha_tile.dart';
import 'BottomNavigationBar.dart';
import 'RegistrationPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final AuthRepository _authRepository = AuthRepository();

  bool isLoading = false;
  String errorMessage = "";
  bool canPop = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool captchaSolved = false;

  int warningCounter = 0;
  static const int maxWarnings = 3;

  // 🎨 Theme-Farben für Dark-Blue Background
  static const Color _cardColor = Color(0xAA0B1220); // halbtransparentes Navy
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Colors.white70;
  static const Color _accent = Colors.orange;
  static const Color _link = Color(0xFF7DD3FC); // helles cyan/blue
  static const Color _border = Color(0x33FFFFFF);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        backgroundColor: Colors.black,
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
                        // Titel-Card (damit der Text auf Dark-Blue sauber lesbar ist)
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: const Text(
                            "Sie haben bereits ein Konto? Melden Sie sich jetzt an",
                            style: TextStyle(
                              fontSize: 28,
                              height: 1.15,
                              color: _textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Email-Card
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              iconTheme: const IconThemeData(color: _textSecondary),
                            ),
                            child: TextInput(
                              label: "Email",
                              obscureText: false,
                              controller: emailController,
                              prefixIcon: const Icon(Icons.email),
                              textColor: Colors.white,
                              labelColor: Colors.white70,
                              iconColor: Colors.white70,
                              cursorColor: Colors.orange,
                              fillColor: const Color(0x660B1220),          // Navy transparent
                              enabledBorderColor: const Color(0x33FFFFFF), // weiße Border, transparent
                              focusedBorderColor: Colors.orange,
                            ),
                          ),
                        ),

                        // Passwort-Card
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              iconTheme: const IconThemeData(color: _textSecondary),
                            ),
                            child: TextInput(
                              label: "Passwort",
                              obscureText: true,
                              controller: passwordController,
                              prefixIcon: const Icon(Icons.key),
                              textColor: Colors.white,
                              labelColor: Colors.white70,
                              iconColor: Colors.white70,
                              cursorColor: Colors.orange,
                              fillColor: const Color(0x660B1220),
                              enabledBorderColor: const Color(0x33FFFFFF),
                              focusedBorderColor: Colors.orange,
                            ),
                          ),
                        ),

                        // Captcha-Card
                        CaptchaTile(
                          solved: captchaSolved,
                          onSolvedChanged: (bool value) {
                            if (!value) _handleWarning();
                            setState(() => captchaSolved = value);
                          },
                          okBilderList: const [
                            "assets/images/captcha/ok1.jpg",
                            "assets/images/captcha/ok2.jpg",
                            "assets/images/captcha/ok3.jpg",
                            "assets/images/captcha/ok4.jpg",
                            "assets/images/captcha/ok5.jpg",
                          ],
                          filterBilderList: const [
                            "assets/images/captcha/egon1.png",
                            "assets/images/captcha/egon2.jpg",
                            "assets/images/captcha/egon3.jpg",
                            "assets/images/captcha/egon4.jpg",
                            "assets/images/captcha/egon5.jpg",
                            "assets/images/captcha/egon6.jpg",
                            "assets/images/captcha/egon7.jpeg",
                            "assets/images/captcha/egon8.jpg",
                            "assets/images/captcha/egon9.jpg",
                            "assets/images/captcha/egon10.jpg",
                          ],
                          suchwort: "Egon Kowalski",
                        ),

                        // Login-Button
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: isLoading
                              ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                              : ElevatedButton(
                            onPressed: _onLoginPressed,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.fromLTRB(30, 18, 30, 18),
                              backgroundColor: _accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "Anmelden",
                              style: TextStyle(
                                fontSize: 20,
                                height: 0,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Registrieren-Hinweis
                        Container(
                          margin: const EdgeInsets.only(top: 22),
                          child: const Text(
                            "Haben Sie doch kein Konto?",
                            style: TextStyle(
                              fontSize: 16,
                              height: 0,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          child: InkWell(
                            onTap: () {
                              if (!isLoading) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegistrationPage(),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Registrieren",
                              style: TextStyle(
                                color: _link,
                                fontSize: 16,
                                height: 0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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

  void _handleWarning() {
    if (warningCounter < maxWarnings) {
      warningCounter++;
    } else {
      warningCounter = 0;
    }
  }

  Future<void> _onLoginPressed() async {
    setState(() {
      isLoading = true;
      canPop = false;
    });

    if (checkUserInput()) {
      await _login();
    } else {
      HelperUtil.getToast(
        meldung: Meldung(meldungsart: Meldungsart.WARNING, text: errorMessage),
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

  Future<void> _login() async {
    final meldung = await _authRepository.loginUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (meldung.meldungsart == Meldungsart.SUCCESS) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar(index: 0)),
        );
      }
    }

    HelperUtil.getToast(meldung: meldung, context: context);
  }

  bool checkUserInput() {
    final buffer = StringBuffer();

    if (emailController.text.trim().isEmpty) {
      buffer.writeln("Gebe deine E-Mail-Adresse ein!");
    }
    if (passwordController.text.trim().isEmpty) {
      buffer.writeln("Gebe dein Passwort ein!");
    }
    if (!captchaSolved) {
      buffer.writeln("Bestätige, dass du kein Roboter bist!");
    }

    errorMessage = buffer.toString();
    return errorMessage.isEmpty;
  }
}
