import 'package:flutter/material.dart';
import '../../../models/UserDto.dart';
import '../../profile_settings/ProfileSettingsPage.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserDto userData;

  const ProfileAppBar({
    super.key,
    required this.userData,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _onProfileTap(BuildContext context) async {

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );

  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.grey[700],
      centerTitle: true,
      title: Text(
        "Mein Profil",
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 25,
          fontStyle: FontStyle.normal,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
         Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () => _onProfileTap(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(120),
              child: Image.network(
                userData.profilePictureUrl!,
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    "assets/images/page/empty.png",
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                  );
                },
              ),
            ),
          ),
        )
      ],
    );
  }
}
