import 'dart:core';
import 'package:flutter/material.dart';
import 'package:social_media_app/pages/profil_page/widgets/add_category_section.dart';
import 'package:social_media_app/pages/profil_page/widgets/category_overview_section.dart';
import 'package:social_media_app/pages/profil_page/widgets/my_posts_section.dart';
import 'package:social_media_app/pages/profil_page/widgets/my_subscribers_section.dart';
import 'package:social_media_app/pages/profil_page/widgets/profile_app_bar.dart';
import 'package:social_media_app/pages/profil_page/widgets/profile_header.dart';
import 'package:social_media_app/pages/profil_page/widgets/profile_info_section.dart';
import 'package:social_media_app/pages/profil_page/widgets/subscribed_section.dart';
import 'package:social_media_app/pages/profil_page/widgets/user_overview_section.dart';

import '../../models/UserDto.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/post_repository.dart';
import '../../widgets/profile_loading.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return PersonalInfoPageState();
  }
}

class PersonalInfoPageState extends State<PersonalInfoPage>
    with AutomaticKeepAliveClientMixin {
  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _authRepository = AuthRepository();

  UserDto? _lastUser;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);

    final userID = _authRepository.currentUserId;

    if (userID == null) {
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

    return StreamBuilder<UserDto?>(
      stream: _userRepository.userStream(userID),
      initialData: _lastUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const ProfileLoading();
        }

        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                "Fehler beim Laden des Benutzers",
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                "Benutzer nicht gefunden",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final userData = snapshot.data!;
        _lastUser = userData;

        final String userrole = userData.role ?? "MELKER";

        return Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: true,
          appBar: ProfileAppBar(
            userData: userData,
          ),
          body: SingleChildScrollView(
            key: const PageStorageKey<String>('profile_page_scroll'),
            child: Column(
              children: [
                ProfileHeader(
                  userData: userData,
                  videoCountStream:
                  _postRepository.userVideoCountStream(userData.userid!),
                  imageCountStream:
                  _postRepository.userImageCountStream(userData.userid!),
                  videoViewsStream:
                  _postRepository.userVideoViewsStream(userData.userid!),
                  imageViewsStream:
                  _postRepository.userImageViewsStream(userData.userid!),
                  subscribersCountStream:
                  _userRepository.subscribersCountStream(userData.userid!),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  color: Colors.black,
                  margin: EdgeInsets.zero,
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileInfoSection(
                          userData: userData,
                        ),
                        MyPostsSection(
                          userData: userData,
                          postRepository: _postRepository,
                          pageSize: 10,
                        ),
                        MySubscribersSection(
                          userData: userData,
                          subscribersQuery:
                          _userRepository.subscribersQuery(userData.userid!),
                          subscribersCountStream: _userRepository
                              .subscribersCountStream(userData.userid!),
                          userRepository: _userRepository,
                        ),
                        SubscribedSection(
                          userData: userData,
                          subscribedQuery:
                          _userRepository.subscribedQuery(userData.userid!),
                          subscribersCountStream: _userRepository
                              .subscribedCountStream(userData.userid!),
                          userRepository: _userRepository,
                        ),
                        UserOverviewSection(
                          userRepository: _userRepository,
                          viewerData: userData,
                        ),
                        userrole == "ADMIN" || userrole == "OWNER"
                            ? CategoryOverviewSection(
                          postRepository: _postRepository,
                        )
                            : const SizedBox.shrink(),
                        userrole == "ADMIN" || userrole == "OWNER"
                            ? AddCategorySection(
                          postRepository: _postRepository,
                        )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}