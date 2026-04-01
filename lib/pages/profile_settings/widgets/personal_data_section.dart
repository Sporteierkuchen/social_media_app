// lib/pages/profile_settings/widgets/personal_data_section.dart
import 'package:flutter/material.dart';
import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../../widgets/TextInput.dart' as Textfeld;

class PersonalDataSection extends StatefulWidget {
  final UserDto userData;
  final UserRepository userRepository;

  const PersonalDataSection({
    super.key,
    required this.userData,
    required this.userRepository,
  });

  @override
  State<PersonalDataSection> createState() => _PersonalDataSectionState();
}

class _PersonalDataSectionState extends State<PersonalDataSection> {
  bool isEditing = false;
  bool isLoading = false;

  final vornameController = TextEditingController();
  final nachnameController = TextEditingController();
  final strasseController = TextEditingController();
  final hausnummerController = TextEditingController();
  final plzController = TextEditingController();
  final stadtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fillControllersFromUser();
  }

  @override
  void dispose() {
    vornameController.dispose();
    nachnameController.dispose();
    strasseController.dispose();
    hausnummerController.dispose();
    plzController.dispose();
    stadtController.dispose();
    super.dispose();
  }

  void _fillControllersFromUser() {
    vornameController.text = widget.userData.vorname ?? '';
    nachnameController.text = widget.userData.nachname ?? '';
    strasseController.text = widget.userData.strase ?? '';
    hausnummerController.text = widget.userData.hausnummer ?? '';
    plzController.text = widget.userData.plz ?? '';
    stadtController.text = widget.userData.stadt ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return isEditing ? _buildEditMode(context) : _buildViewMode();
  }

  // =========================
  // VIEW MODE
  // =========================
  Widget _buildViewMode() {
    final vorname = widget.userData.vorname ?? '';
    final nachname = widget.userData.nachname ?? '';
    final strasse = widget.userData.strase ?? '';
    final hausnummer = widget.userData.hausnummer ?? '';
    final plz = widget.userData.plz ?? '';
    final stadt = widget.userData.stadt ?? '';

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 25, right: 10, top: 20, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Persönliche Daten',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$vorname $nachname'.trim(),
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 5),
                Text(
                  '$strasse $hausnummer'.trim(),
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 5),
                Text(
                  '$plz $stadt'.trim(),
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
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
                    'Persönliche Daten',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Textfeld.TextInput(
                    label: "Vorname",
                    obscureText: false,
                    controller: vornameController,
                    prefixIcon: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  Textfeld.TextInput(
                    label: "Nachname",
                    obscureText: false,
                    controller: nachnameController,
                    prefixIcon: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  Textfeld.TextInput(
                    label: "Straße",
                    obscureText: false,
                    controller: strasseController,
                    prefixIcon: const Icon(Icons.streetview, color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  Textfeld.TextInput(
                    label: "Hausnummer",
                    obscureText: false,
                    controller: hausnummerController,
                    prefixIcon: const Icon(Icons.numbers, color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  Textfeld.TextInput(
                    label: "Postleitzahl",
                    obscureText: false,
                    controller: plzController,
                    prefixIcon: const Icon(Icons.post_add, color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  Textfeld.TextInput(
                    label: "Stadt",
                    obscureText: false,
                    controller: stadtController,
                    prefixIcon: const Icon(Icons.home, color: Colors.white),
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
                        onPressed: _onSave,
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
  // ACTIONS (intern wie AboutMe)
  // =========================
  void _onEdit() {
    _fillControllersFromUser();
    setState(() => isEditing = true);
  }

  void _onCancel() {
    if (isLoading) return;
    _fillControllersFromUser();
    setState(() => isEditing = false);
  }

  bool _validate() {
    final v = vornameController.text.trim();
    final n = nachnameController.text.trim();

    if (v.isEmpty || n.isEmpty) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Vorname und Nachname dürfen nicht leer sein.",
        ),

      );
      return false;
    }
    return true;
  }

  Future<void> _onSave() async {
    if (isLoading) return;
    if (!_validate()) return;

    final uid = widget.userData.userid;
    if (uid == null || uid.isEmpty) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text: "Fehler: Benutzer-ID fehlt.",
        ),

      );
      return;
    }

    setState(() => isLoading = true);

    try {
      debugPrint("[PersonalDataSection] updateUserProfile -> uid=$uid");

      final updated = await widget.userRepository.updateUserProfile(
        UserDto(
          userid: uid,
          vorname: vornameController.text.trim(),
          nachname: nachnameController.text.trim(),
          strase: strasseController.text.trim(),
          hausnummer: hausnummerController.text.trim(),
          plz: plzController.text.trim(),
          stadt: stadtController.text.trim(),
        ),
      );

      if (!mounted) return;

      if (updated) {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.SUCCESS,
            text: "Die Daten wurden erfolgreich aktualisiert!",
          ),

        );
        setState(() => isEditing = false);
      } else {
        HelperUtil.getToast(
          meldung: Meldung(
            meldungsart: Meldungsart.ERROR,
            text: "Die Daten konnten nicht gespeichert werden.",
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
