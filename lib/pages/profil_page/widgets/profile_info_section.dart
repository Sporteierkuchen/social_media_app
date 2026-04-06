import 'package:flutter/material.dart';

import '../../../models/UserDto.dart';
import '../../../util/FormatUtil.dart';

class ProfileInfoSection extends StatelessWidget {
  final UserDto userData;

  const ProfileInfoSection({
    super.key,
    required this.userData,
  });

  String get _fullName {
    return "${userData.vorname ?? ''} ${userData.nachname ?? ''}".trim();
  }

  String get _username {
    return (userData.benutzername ?? '').trim();
  }

  String get _description {
    return (userData.beschreibung ?? '').trim();
  }

  String get _streetLine {
    final street = (userData.strase ?? '').trim();
    final houseNumber = (userData.hausnummer ?? '').trim();
    return "$street $houseNumber".trim();
  }

  String get _cityLine {
    final zip = (userData.plz ?? '').trim();
    final city = (userData.stadt ?? '').trim();
    return "$zip $city".trim();
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = userData.timestamp;
    final mitgliedSeit = timestamp?.toDate();

    final bool hasStreet = _streetLine.isNotEmpty;
    final bool hasCity = _cityLine.isNotEmpty;
    final bool hasLocation = hasStreet || hasCity;
    final bool hasDescription = _description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        const Text(
          "Profilinformationen",
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
                _username.isEmpty ? "Kein Benutzername" : _username,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (mitgliedSeit != null) ...[
                const SizedBox(height: 8),
                Text(
                  "Mitglied seit ${FormatUtil.formatDate(mitgliedSeit)}",
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

        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fullName.isEmpty ? "Über mich" : "Über $_fullName",
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasDescription
                    ? _description
                    : "Noch keine Beschreibung hinterlegt.",
                style: TextStyle(
                  fontSize: 15,
                  color: hasDescription ? Colors.white : Colors.white60,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        if (hasLocation) ...[
          const SizedBox(height: 12),
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Standort",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (hasStreet)
                  _InfoRow(
                    icon: Icons.home_outlined,
                    label: "Straße",
                    value: _streetLine,
                  ),
                if (hasStreet && hasCity) const SizedBox(height: 10),
                if (hasCity)
                  _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: "Ort",
                    value: _cityLine,
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),
      ],
    );
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}