import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';
import '../../../widgets/TextInput.dart' as textfeld;

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
  void didUpdateWidget(covariant PersonalDataSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isEditing && oldWidget.userData != widget.userData) {
      _fillControllersFromUser();
    }
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
    final vorname = widget.userData.vorname ?? '';
    final nachname = widget.userData.nachname ?? '';
    final strasse = widget.userData.strase ?? '';
    final hausnummer = widget.userData.hausnummer ?? '';
    final plz = widget.userData.plz ?? '';
    final stadt = widget.userData.stadt ?? '';

    final fullName = '$vorname $nachname'.trim();
    final addressLine = '$strasse $hausnummer'.trim();
    final cityLine = '$plz $stadt'.trim();

    return Column(
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
        const SizedBox(height: 14),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel("Name"),
              const SizedBox(height: 6),
              Text(
                fullName.isNotEmpty ? fullName : "Keine Angaben",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              const _SectionLabel("Adresse"),
              const SizedBox(height: 6),
              Text(
                addressLine.isNotEmpty ? addressLine : "Keine Straße hinterlegt",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cityLine.isNotEmpty ? cityLine : "Kein Ort hinterlegt",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.35,
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
          'Persönliche Daten bearbeiten',
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
                label: "Vorname",
                obscureText: false,
                controller: vornameController,
                prefixIcon: const Icon(Icons.person),
              ),
              const SizedBox(height: 14),
              textfeld.TextInput(
                label: "Nachname",
                obscureText: false,
                controller: nachnameController,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 14),
              textfeld.TextInput(
                label: "Straße",
                obscureText: false,
                controller: strasseController,
                prefixIcon: const Icon(Icons.streetview),
              ),
              const SizedBox(height: 14),
              textfeld.TextInput(
                label: "Hausnummer",
                obscureText: false,
                controller: hausnummerController,
                prefixIcon: const Icon(Icons.numbers),
              ),
              const SizedBox(height: 14),
              textfeld.TextInput(
                label: "Postleitzahl",
                obscureText: false,
                controller: plzController,
                prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
              ),
              const SizedBox(height: 14),
              textfeld.TextInput(
                label: "Stadt",
                obscureText: false,
                controller: stadtController,
                prefixIcon: const Icon(Icons.location_city),
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
                onTap: _onSave,
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}