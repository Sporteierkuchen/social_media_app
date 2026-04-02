import 'package:flutter/material.dart';
import 'package:social_media_app/pages/post_page/PostPage.dart';
import 'package:social_media_app/services/app_shell_service.dart';

import 'chat_page/chat/chat_list_page.dart';
import 'home_page/HomePage.dart';
import 'profil_page/Profil_Page.dart';

class BottomNavBar extends StatefulWidget {
  final int index;

  const BottomNavBar({super.key, this.index = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  void initState() {
    super.initState();

    AppShellService.setTab(widget.index);

    debugPrint(
      "[BottomNavBar] initState -> Startindex: ${AppShellService.currentTab}",
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final barHeight = mediaQuery.size.height * 0.09;

    final double contentHeight =
        mediaQuery.size.height - mediaQuery.padding.top - barHeight;

    return ValueListenableBuilder<int>(
      valueListenable: AppShellService.selectedTab,
      builder: (context, currentIndex, _) {
        debugPrint(
          "[BottomNavBar] build() -> index: $currentIndex, "
              "contentHeight: ${contentHeight.toStringAsFixed(1)}, "
              "barHeight: ${barHeight.toStringAsFixed(1)}",
        );

        return PopScope(
          canPop: false,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: _buildScreen(currentIndex, contentHeight),
            ),
            bottomNavigationBar: SizedBox(
              height: barHeight,
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                items: getItems(context, currentIndex),
                unselectedFontSize: 14,
                selectedFontSize: 15,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.grey[800],
                selectedItemColor: Colors.orange,
                unselectedItemColor: Colors.white,
                onTap: (value) {
                  if (value == currentIndex) return;

                  debugPrint(
                    "[BottomNavBar] Tab gewechselt: $currentIndex -> $value",
                  );

                  AppShellService.setTab(value);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScreen(int currentIndex, double contentHeight) {
    switch (currentIndex) {
      case 0:
        debugPrint("[BottomNavBar] _buildScreen -> HomePage");
        return HomePage(contentHeight: contentHeight);
      case 1:
        debugPrint("[BottomNavBar] _buildScreen -> PostPage");
        return const PostPage();
      case 2:
        debugPrint("[BottomNavBar] _buildScreen -> ChatsScreen");
        return ChatListPage();
      case 3:
        debugPrint("[BottomNavBar] _buildScreen -> PersonalInfoPage");
        return const PersonalInfoPage();
      default:
        debugPrint(
          "[BottomNavBar] _buildScreen -> Default -> HomePage (index=$currentIndex)",
        );
        return HomePage(contentHeight: contentHeight);
    }
  }

  List<BottomNavigationBarItem> getItems(
      BuildContext context,
      int currentIndex,
      ) {
    return [
      _getHomeIcon(context, currentIndex == 0),
      _getPostIcon(context, currentIndex == 1),
      _getChatIcon(context, currentIndex == 2),
      _getProfileIcon(context, currentIndex == 3),
    ];
  }

  BottomNavigationBarItem _getHomeIcon(BuildContext context, bool selected) {
    final size = MediaQuery.of(context).size.height * 0.04;

    return BottomNavigationBarItem(
      icon: SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.home,
          color: selected ? Colors.orange : Colors.black,
        ),
      ),
      label: "Home",
    );
  }

  BottomNavigationBarItem _getPostIcon(BuildContext context, bool selected) {
    final size = MediaQuery.of(context).size.height * 0.04;

    return BottomNavigationBarItem(
      icon: SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.camera_alt,
          color: selected ? Colors.orange : Colors.black,
        ),
      ),
      label: "Beiträge",
    );
  }

  BottomNavigationBarItem _getChatIcon(BuildContext context, bool selected) {
    final size = MediaQuery.of(context).size.height * 0.04;

    return BottomNavigationBarItem(
      icon: SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.chat,
          color: selected ? Colors.orange : Colors.black,
        ),
      ),
      label: "Chats",
    );
  }

  BottomNavigationBarItem _getProfileIcon(BuildContext context, bool selected) {
    final size = MediaQuery.of(context).size.height * 0.04;

    return BottomNavigationBarItem(
      icon: SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.person,
          color: selected ? Colors.orange : Colors.black,
        ),
      ),
      label: "Profil",
    );
  }
}