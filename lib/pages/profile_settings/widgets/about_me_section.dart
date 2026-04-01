// lib/pages/profile_settings/widgets/about_me_section.dart
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/FormatUtil.dart';
import '../../../util/HelperUtil.dart';

class AboutMeSection extends StatefulWidget {

  final UserDto userData;
  final UserRepository userRepository;

  const AboutMeSection({
    super.key,
    required this.userData,
    required this.userRepository,
  });

  @override
  State<AboutMeSection> createState() => _AboutMeSectionState();
}

class _AboutMeSectionState extends State<AboutMeSection> {

  final TextEditingController beschreibungTextController = TextEditingController();

  bool beschreibungAendern = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // initial aus Firestore-Daten setzen
    beschreibungTextController.text = widget.userData.beschreibung ?? '';
  }

  @override
  void dispose() {
    beschreibungTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nickname = widget.userData.benutzername ?? "";
    final memberSince = widget.userData.timestamp;
    final beschreibung = widget.userData.beschreibung ?? "";

    final textToShow = beschreibungTextController.text.trim().isNotEmpty
        ? beschreibungTextController.text
        : beschreibung;

    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nickname
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Text(
              nickname,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                height: 0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Mitglied seit
          if (memberSince != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: Text(
                "Mitglied seit ${FormatUtil.formatDate(memberSince.toDate())}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 0,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
            ),

          const SizedBox(height: 10),

          beschreibungAendern ? _buildEditMode(context) : _buildViewMode(textToShow),
        ],
      ),
    );
  }

  Widget _buildViewMode(String textToShow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel + Edit-Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Über mich",
              style: TextStyle(
                fontSize: 20,
                height: 0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                setState(() => beschreibungAendern = true);
              },
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.orange,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          textToShow,
          style: const TextStyle(
            fontSize: 16,
            height: 0,
            fontWeight: FontWeight.normal,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Über mich",
                style: TextStyle(
                  fontSize: 20,
                  height: 0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        TextFormField(
          controller: beschreibungTextController,
          maxLines: 5,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            hintText: 'Schreibe etwas über dich...',
            hintStyle: const TextStyle(color: Colors.white54),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              isLoading
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              )
                  : ElevatedButton(
                onPressed: _saveAboutMe,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.save, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Speichern',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              ElevatedButton(
                onPressed: isLoading ? null : _cancelAboutMeEdit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Abbrechen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // ✅ DEINE Methoden jetzt IN der Section
  // =========================

  void _cancelAboutMeEdit() {
    debugPrint("[AboutMeSection] Cancel edit");
    setState(() {
      beschreibungTextController.text = widget.userData.beschreibung ?? '';
      beschreibungAendern = false;
    });
  }

  Future<void> _saveAboutMe() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    final newText = beschreibungTextController.text.trim();
    debugPrint("[AboutMeSection] Save about me (len=${newText.length}) user=${widget.userData.userid}");

    try {
      final success = await widget.userRepository.updateUserBeschreibung(
        newText,
        widget.userData.userid!,
      );

      if (!mounted) return;

      if (success) {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.SUCCESS,
            text: "Die Beschreibung wurde erfolgreich aktualisiert!",
          ),

        );

        setState(() => beschreibungAendern = false);
      } else {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.ERROR,
            text: "Beschreibung konnte nicht gespeichert werden.",
          ),

        );
      }
    } catch (e) {
      if (!mounted) return;
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler beim Speichern:\n$e",
        ),

      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);

    }
  }

}
