import 'package:cached_network_image/cached_network_image.dart';
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
  Size get preferredSize => const Size.fromHeight(64);

  String get _profileImageUrl {
    return (userData.profilePictureUrl ?? '').trim();
  }

  Future<void> _onProfileTap(BuildContext context) async {
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
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFF111111),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        "Mein Profil",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _onProfileTap(context),
              child: Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white12,
                    width: 1.2,
                  ),
                  color: const Color(0xFF1A1A1A),
                ),
                child: ClipOval(
                  child: _profileImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: _profileImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Image.asset(
                      "assets/images/page/empty.png",
                      fit: BoxFit.cover,
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      "assets/images/page/empty.png",
                      fit: BoxFit.cover,
                    ),
                  )
                      : Image.asset(
                    "assets/images/page/empty.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}