import 'dart:core';
import 'package:flutter/material.dart';
import 'package:social_media_app/pages/profile_settings/widgets/about_me_section.dart';
import 'package:social_media_app/pages/profile_settings/widgets/email_section.dart';
import 'package:social_media_app/pages/profile_settings/widgets/logout_button.dart';
import 'package:social_media_app/pages/profile_settings/widgets/password_section.dart';
import 'package:social_media_app/pages/profile_settings/widgets/personal_data_section.dart';
import 'package:social_media_app/pages/profile_settings/widgets/profile_header_section.dart';
import '../../models/UserDto.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/profile_loading.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage> {

  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final uid = _authRepository.currentUserId; // oder FirebaseAuth.instance.currentUser?.uid
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Nicht eingeloggt",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: StreamBuilder<UserDto?>(
            stream: _userRepository.userStream(uid),
            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return const Center(
                  child: Text("Fehler beim Laden", style: TextStyle(color: Colors.red)),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ProfileLoading();
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text("Benutzer nicht gefunden", style: TextStyle(color: Colors.white)),
                );
              }

              final userdata = snapshot.data!;

              return SingleChildScrollView(
                child: Stack(
                  children: [

                    ProfileHeaderSection(
                      userdata: userdata,
                      userRepository: _userRepository,
                    ),

                    // The card widget with top padding,
                    // incase if you wanted bottom padding to work,
                    // set the `alignment` of container to Alignment.bottomCenter
                    Container(
                      //color: Colors.black,
                      alignment: Alignment.topCenter,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * .45,
                        right: 0,
                        left: 0,
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        color: Colors.black,
                        margin: const EdgeInsets.only(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Column(
                            children: [

                              AboutMeSection(
                                userData: userdata,
                                userRepository: _userRepository, // ✅ UserDto
                              ),

                              // 2) Persönliche Daten (Adresse etc.)
                              PersonalDataSection(
                                userData: userdata,
                                userRepository: _userRepository,
                              ),

                              // 3) E-Mail-Bereich
                              EmailSection(
                                userData: userdata,
                                authRepository: _authRepository,
                                userRepository: _userRepository,
                              ),

                              // 4) Passwort-Bereich
                              PasswordSection(
                                userData: userdata,
                                userRepository:_userRepository,
                                authRepository: _authRepository,
                              ),

                              // 5) Logout-Button
                              LogoutButton(
                                authRepository: _authRepository,
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

            },
          ),
        ),
      );
  }

}
