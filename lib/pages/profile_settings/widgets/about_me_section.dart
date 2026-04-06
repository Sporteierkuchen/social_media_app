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
  final TextEditingController beschreibungTextController =
  TextEditingController();

  bool beschreibungAendern = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    beschreibungTextController.text = widget.userData.beschreibung ?? '';
  }

  @override
  void didUpdateWidget(covariant AboutMeSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!beschreibungAendern &&
        oldWidget.userData.beschreibung != widget.userData.beschreibung) {
      beschreibungTextController.text = widget.userData.beschreibung ?? '';
    }
  }

  @override
  void dispose() {
    beschreibungTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nickname = (widget.userData.benutzername ?? "").trim();
    final memberSince = widget.userData.timestamp;
    final beschreibung = (widget.userData.beschreibung ?? "").trim();

    final textToShow = beschreibungTextController.text.trim().isNotEmpty
        ? beschreibungTextController.text.trim()
        : beschreibung;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Profiltext",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel("Benutzername"),
                const SizedBox(height: 6),
                Text(
                  nickname.isNotEmpty ? nickname : "Kein Benutzername",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (memberSince != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Mitglied seit ${FormatUtil.formatDate(memberSince.toDate())}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          beschreibungAendern
              ? _buildEditMode(context)
              : _buildViewMode(textToShow),
        ],
      ),
    );
  }

  Widget _buildViewMode(String textToShow) {
    final content = textToShow.trim().isNotEmpty
        ? textToShow.trim()
        : "Noch keine Beschreibung hinterlegt.";

    final hasContent = textToShow.trim().isNotEmpty;

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Über mich",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: isLoading
                    ? null
                    : () {
                  setState(() => beschreibungAendern = true);
                },
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
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: hasContent ? Colors.white : Colors.white60,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Über mich bearbeiten",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: beschreibungTextController,
            maxLines: 5,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF222222),
              hintText: 'Schreibe etwas über dich...',
              hintStyle: const TextStyle(color: Colors.white54),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.white12,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.orange,
                  width: 1.6,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.35,
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
                  onTap: _cancelAboutMeEdit,
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
                        Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Abbrechen",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _saveAboutMe,
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
                        Icon(
                          Icons.save_outlined,
                          color: Colors.black,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Speichern",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 14,
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
      ),
    );
  }

  void _cancelAboutMeEdit() {
    setState(() {
      beschreibungTextController.text = widget.userData.beschreibung ?? '';
      beschreibungAendern = false;
    });
  }

  Future<void> _saveAboutMe() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    final newText = beschreibungTextController.text.trim();

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