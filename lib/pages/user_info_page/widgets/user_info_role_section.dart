
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

  final List<String> roles = ['ADMIN', 'USER', 'RESTRICTED-USER', "MELKER"]; // Verfügbare Rollen
  bool roleLoaded= true;

  @override
  Widget build(BuildContext context) {
    if (!showRoleWidget(widget.viewerData.role!, widget.userData.role!)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 40, bottom: 20),
          child: Text(
            "Benutzerrolle",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 22,
              height: 0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        roleLoaded
            ? DropdownButtonFormField<String>(
          initialValue: widget.userData.role,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            labelText: 'Rolle ändern',
            labelStyle: const TextStyle(color: Colors.white),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.lightBlue,
                width: 2,
              ),
            ),
          ),
          dropdownColor: Colors.grey[800],
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          onChanged: (String? newRole) async {
            if (newRole != null && widget.userData.role != newRole) {
              await _updateUserRole(newRole);
            }
          },
          items: roles.map((role) {
            return DropdownMenuItem<String>(
              value: role,
              child: Row(
                children: [
                  Text(role),
                  const SizedBox(width: 8),
                  HelperUtil.getUserIcon(role),
                ],
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
        ), context: context,
      );
    } catch (e) {
      print("Fehler beim Ändern der Benutzerrolle: $e");
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.WARNING,
          text: "Fehler beim Ändern der Benutzerrolle:\n$e",
        ), context: context,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        roleLoaded = true;
      });
    }
  }

  bool showRoleWidget(String viewerRole, String userRole) {

    if (viewerRole == "ADMIN" &&
        (userRole == "USER" || userRole == "RESTRICTED-USER" || userRole == "MELKER")) {
      return true;
    }
    if (viewerRole == "OWNER") {
      return true;
    }

    return false;
  }

}
