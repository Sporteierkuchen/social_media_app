// lib/repositories/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../models/Meldung.dart';


class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // AUTH STATE / HELPER
  // ------------------------------------------------------------

  /// Stream, um auf Login/Logout zu reagieren (z. B. in einer Wrapper-Page)
  // 👇 WICHTIG: als Getter, nicht als Methode
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// aktuell eingeloggter User (kann null sein)
  User? get currentUser => _auth.currentUser;

  /// nur die UID des aktuellen Users
  String? get currentUserId => _auth.currentUser?.uid;

  // ------------------------------------------------------------
  // Registrierung
  // ------------------------------------------------------------

  Future<Meldung> registerUser({
    required String benutzername,
    required String vorname,
    required String nachname,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // ⚠️ Passwort NICHT im Klartext in Firestore speichern!
      await _firestore.collection("users").doc(uid).set({
        'benutzername': benutzername,
        'vorname': vorname,
        'nachname': nachname,
        'strase': "",
        'hausnummer': "",
        'plz': "",
        'stadt': "",
        'profilePictureUrl': "",
        'beschreibung': "",
        'role': "USER",
        'uid': uid,
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return Meldung(
        meldungsart: Meldungsart.SUCCESS,
        text: "Erfolgreich registriert",
      );
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (err) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: err.toString(),
      );
    }
  }

  // ------------------------------------------------------------
  // Login
  // ------------------------------------------------------------

  Future<Meldung> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return Meldung(
        meldungsart: Meldungsart.SUCCESS,
        text: "Login erfolgreich",
      );
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (err) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: err.toString(),
      );
    }
  }

  // ------------------------------------------------------------
  // Logout
  // ------------------------------------------------------------

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ------------------------------------------------------------
  // Profilbild (nur Auth-Seite)
  // ------------------------------------------------------------

  Future<String?> getCurrentUserProfilePicture() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return user.photoURL;
  }

  // ------------------------------------------------------------
  // Passwort / E-Mail in FirebaseAuth ändern
  // ------------------------------------------------------------

  /// Passwort in FirebaseAuth ändern
  /// (ggf. vorher reauth nötig, sonst wirft Firebase einen Fehler)
  Future<Meldung> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: "Kein Benutzer eingeloggt.",
      );
    }

    try {
      await user.updatePassword(newPassword);
      return Meldung(
        meldungsart: Meldungsart.SUCCESS,
        text: "Passwort erfolgreich geändert.",
      );
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: e.toString(),
      );
    }
  }

  /// E-Mail in FirebaseAuth ändern
  /// (Firebase verlangt meistens eine Reauth für diesen Schritt)
  /// E-Mail in FirebaseAuth ändern
  /// (Firebase schickt Bestätigungslink an die neue Adresse)
  Future<Meldung> changeEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: "Kein Benutzer eingeloggt.",
      );
    }

    try {
      // Schickt einen Bestätigungslink an die neue Adresse
      await user.verifyBeforeUpdateEmail(newEmail);

      // Firestore-Feld 'email' aktualisieren
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
      });

      return Meldung(
        meldungsart: Meldungsart.SUCCESS,
        text:
        "E-Mail-Änderung eingeleitet. Bitte bestätige die neue Adresse über den Link in der E-Mail.",
      );
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: e.toString(),
      );
    }
  }


  // ------------------------------------------------------------
  // Passwort-Zurücksetzen
  // ------------------------------------------------------------

  Future<Meldung> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return Meldung(
        meldungsart: Meldungsart.SUCCESS,
        text: "E-Mail zum Zurücksetzen des Passworts wurde gesendet.",
      );
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: e.toString(),
      );
    }
  }

  // ------------------------------------------------------------
  // Optional: Re-Authenticate (z. B. vor Delete/Email-Change)
  // ------------------------------------------------------------

  Future<Meldung> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: "Kein Benutzer eingeloggt.",
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      return Meldung(
        meldungsart: Meldungsart.SUCCESS,
        text: "Re-Authentifizierung erfolgreich.",
      );
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return Meldung(
        meldungsart: Meldungsart.ERROR,
        text: e.toString(),
      );
    }
  }

  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final result = await FirebaseFirestore.instance
          .collection("users")
          .where("benutzername", isEqualTo: nickname)
          .limit(1)
          .get();

      return result.docs.isEmpty;
    } on FirebaseException catch (e) {
      debugPrint("Fehler bei Nickname-Prüfung: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Unerwarteter Fehler bei Nickname-Prüfung: $e");
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // Error-Mapping
  // ------------------------------------------------------------

  Meldung _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Ungültige E-Mail Adresse!",
        );
      case 'weak-password':
        return Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Das Passwort muss mindestens aus 6 Zeichen bestehen!",
        );
      case 'email-already-in-use':
        return Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Diese E-Mail Adresse wird bereits verwendet!",
        );
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "E-Mail Adresse oder Passwort ist falsch!",
        );
      default:
        return Meldung(
          meldungsart: Meldungsart.ERROR,
          text: e.message ?? e.code,
        );
    }
  }

}
