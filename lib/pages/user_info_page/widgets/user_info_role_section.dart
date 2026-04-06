import 'package:flutter/material.dart';

import '../../../models/Meldung.dart';
import '../../../models/UserDto.dart';
import '../../../repositories/user_repository.dart';
import '../../../util/HelperUtil.dart';

class UserInfoRoleSection extends StatefulWidget {
  final UserDto userData;
  final UserDto viewerData;
  final UserRepository userRepository;

  const UserInfoRoleSection({
    super.key,
    required this.userData,
    required this.viewerData,
    required this.userRepository,
  });

  @override
  State<UserInfoRoleSection> createState() => _UserInfoRoleSectionState();
}

class _UserInfoRoleSectionState extends State<UserInfoRoleSection> {
  final List<String> roles = ['ADMIN', 'USER', 'RESTRICTED-USER', 'MELKER'];

  bool roleLoaded = true;

  @override
  Widget build(BuildContext context) {
    if (!_showRoleWidget(
      widget.viewerData.role ?? "",
      widget.userData.role ?? "",
    )) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
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
            "Benutzerrolle",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Lege fest, welche Rolle ${_targetDisplayName()} in der App haben soll.",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text(
                "Aktuelle Rolle:",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 20,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: HelperUtil.getUserIcon(widget.userData.role ?? "USER"),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.userData.role ?? "USER",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          roleLoaded
              ? DropdownButtonFormField<String>(
            initialValue: roles.contains(widget.userData.role)
                ? widget.userData.role
                : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF222222),
              labelText: 'Rolle auswählen',
              labelStyle: const TextStyle(color: Colors.white70),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
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
            dropdownColor: const Color(0xFF222222),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (String? newRole) async {
              if (newRole != null && widget.userData.role != newRole) {
                await _updateUserRole(newRole);
              }
            },
            items: roles.map((role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(
                  role,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          )
              : const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserRole(String role) async {
    if (!roleLoaded) return;

    setState(() {
      roleLoaded = false;
    });

    try {
      await widget.userRepository.updateUserRoleEverywhere(
        userId: widget.userData.userid!,
        role: role,
      );

      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.SUCCESS,
          text: "Benutzerrolle erfolgreich geändert!",
        ),
      );
    } catch (e) {
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Fehler beim Ändern der Benutzerrolle:\n$e",
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        roleLoaded = true;
      });
    }
  }

  bool _showRoleWidget(String viewerRole, String userRole) {
    if (viewerRole == "ADMIN" &&
        (userRole == "USER" ||
            userRole == "RESTRICTED-USER" ||
            userRole == "MELKER")) {
      return true;
    }

    if (viewerRole == "OWNER") {
      return true;
    }

    return false;
  }

  String _targetDisplayName() {
    final fullName =
    "${widget.userData.vorname ?? ''} ${widget.userData.nachname ?? ''}".trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final username = (widget.userData.benutzername ?? "").trim();
    if (username.isNotEmpty) {
      return username;
    }

    return "dieser Nutzer";
  }
}