import 'package:flutter/foundation.dart';

class AppShellService {
  static final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

  static void setTab(int index) {
    if (selectedTab.value != index) {
      selectedTab.value = index;
    }
  }

  static int get currentTab => selectedTab.value;

  static void reset() {
    selectedTab.value = 0;
  }
}