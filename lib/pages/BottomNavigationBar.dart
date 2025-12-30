
import 'package:flutter/material.dart';
import 'package:social_media_app/pages/post_page/PostPage.dart';
import 'chat_page/chat/chat_list_page.dart';
import 'home_page/HomePage.dart';
import 'profil_page/Profil_Page.dart';

class BottomNavBar extends StatefulWidget {
  final int index;
  const BottomNavBar({super.key, required this.index});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    debugPrint(
      "[BottomNavBar] initState -> Startindex: $_currentIndex",
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final barHeight = mediaQuery.size.height * 0.09;

    // 👉 sichtbare Höhe zwischen Statusleiste (SafeArea.top) und BottomNavBar
    final double contentHeight =
        mediaQuery.size.height - mediaQuery.padding.top - barHeight;

    debugPrint(
      "[BottomNavBar] build() -> index: $_currentIndex, "
          "contentHeight: ${contentHeight.toStringAsFixed(1)}, "
          "barHeight: ${barHeight.toStringAsFixed(1)}",
    );

    return PopScope(
      canPop: false, // 🔒 verhindert, dass Back die App schließt
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          // 👉 hier wird die Seite mit contentHeight gebaut
          child: _buildScreen(contentHeight),
        ),
        bottomNavigationBar: SizedBox(
          height: barHeight,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            items: getItems(context),
            unselectedFontSize: 14,
            selectedFontSize: 15,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.grey[800],
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.white,
            onTap: (value) {
              if (value == _currentIndex) {
                // Kein unnötiges Rebuild loggen
                return;
              }
              debugPrint(
                "[BottomNavBar] Tab gewechselt: "
                    "$_currentIndex -> $value",
              );
              setState(() {
                _currentIndex = value;
              });
            },
          ),
        ),
      ),
    );
  }

  /// Baut je nach aktuellem Index den richtigen Screen.
  /// Für die HomePage wird contentHeight übergeben.
  Widget _buildScreen(double contentHeight) {
    switch (_currentIndex) {
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
          "[BottomNavBar] _buildScreen -> Default -> HomePage (index=$_currentIndex)",
        );
        return HomePage(contentHeight: contentHeight);
    }
  }

  List<BottomNavigationBarItem> getItems(BuildContext context) {
    return [
      _getHomeIcon(context, _currentIndex == 0),
      _getPostIcon(context, _currentIndex == 1),
      _getChatIcon(context, _currentIndex == 2),
      _getProfileIcon(context, _currentIndex == 3),
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

  BottomNavigationBarItem _getPostIcon(
      BuildContext context, bool selected) {
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

  BottomNavigationBarItem _getChatIcon(
      BuildContext context, bool selected) {
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

  BottomNavigationBarItem _getProfileIcon(
      BuildContext context, bool selected) {
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
