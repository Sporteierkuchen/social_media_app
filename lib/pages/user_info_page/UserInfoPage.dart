import 'dart:core';
import 'package:flutter/material.dart';
import 'package:social_media_app/pages/user_info_page/widgets/user_info_details_section.dart';
import 'package:social_media_app/pages/user_info_page/widgets/user_info_header.dart';
import 'package:social_media_app/pages/user_info_page/widgets/user_info_posts_section.dart';
import 'package:social_media_app/pages/user_info_page/widgets/user_info_role_section.dart';
import 'package:social_media_app/pages/user_info_page/widgets/user_info_subscribers_section.dart';
import '../../models/Meldung.dart';
import '../../models/UserDto.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/post_repository.dart';
import '../../util/HelperUtil.dart';
import '../../widgets/profile_loading.dart';


class UserInfoPage extends StatefulWidget {
  final String userID;
  final String viewerID;

  const UserInfoPage(
      {super.key,
      required this.userID,
      required this.viewerID,
      });
  @override
  State<StatefulWidget> createState() {
    return UserInfoPageState();
  }
}

class UserInfoPageState extends State<UserInfoPage> {

  final UserRepository _userRepository = UserRepository();
  final PostRepository _postRepository = PostRepository();

  bool loadedData = false;

  UserDto? _viewerData;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    print("Build Profil");

    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: true,
        child:
        SafeArea(
          child: loadedData ?
          SingleChildScrollView(
            child:

            StreamBuilder<UserDto?>(
              stream: _userRepository.userStream(widget.userID),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Fehler beim Laden des Benutzers",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text(
                      "Benutzer nicht gefunden",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final userData = snapshot.data!;

                return
                  Column(
                    children: [

                      UserInfoHeader(
                        userData: userData,
                        viewerData: _viewerData!,

                        videoCountStream: _postRepository.userVideoCountStream(widget.userID),
                        imageCountStream: _postRepository.userImageCountStream(widget.userID),

                        videoViewsStream: _postRepository.userVideoViewsStream(widget.userID),
                        imageViewsStream: _postRepository.userImageViewsStream(widget.userID),

                        subscribersCountStream: _userRepository.subscribersCountStream(widget.userID),
                        isSubscribedStream: _userRepository.isSubscribedStream(
                          viewerId: widget.viewerID,
                          targetId: widget.userID,
                        ),
                        userRepository: _userRepository,
                      ),

                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        color: Colors.black,
                        margin: const EdgeInsets.only(
                            left: 0, right: 0, top: 0, bottom: 0),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 10, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              UserInfoDetailsSection(
                                userData: userData,
                              ),

                              UserInfoPostsSection(
                                userData: userData,
                                viewerData: _viewerData!,
                                postRepository: _postRepository,
                                pageSize: 10,
                              ),

                              UserInfoSubscribersSection(
                                userData: userData,
                                viewerData: _viewerData!,
                                subscribersQuery: _userRepository.subscribersQuery(widget.userID),
                                subscribersCountStream: _userRepository.subscribersCountStream(widget.userID),
                                userRepository: _userRepository,
                              ),

                              UserInfoRoleSection(
                                userData: userData,
                                viewerData: _viewerData!,
                                userRepository: _userRepository,
                              ),

                            ],
                          ),
                        ),
                      )
                    ],
                  );
              },
            ),

          )
              : ProfileLoading(),
        ),
      ),
    );
  }

  Future<void> initialize() async {
    await _getViewer();
    if (!mounted) return;
    setState(() => loadedData = _viewerData != null);
  }


  Future<void> _getViewer() async {
    try {
      _viewerData = await _userRepository.getUserDetailsDto(widget.viewerID);
    } catch (e) {
      print("Fehler beim Abrufen des aktuellen Benutzers: $e");
      HelperUtil.getToast(
        meldung: Meldung(
          meldungsart: Meldungsart.ERROR,
          text:
          "Fehler beim Abrufen des aktuellen Benutzers:\n$e",
        ), context: context,
      );
    }
  }

}
