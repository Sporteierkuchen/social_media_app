import 'package:flutter/material.dart';
import '../services/PushService.dart';
import 'BottomNavigationBar.dart';

class AuthenticatedRoot extends StatefulWidget {
  final int index;

  const AuthenticatedRoot({super.key, this.index = 0});

  @override
  State<AuthenticatedRoot> createState() => _AuthenticatedRootState();
}

class _AuthenticatedRootState extends State<AuthenticatedRoot> {
  bool _pushInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPush();
  }

  Future<void> _initPush() async {
    try {
      await PushService().init();
      debugPrint("[AuthenticatedRoot] PushService init erfolgreich");
    } catch (e) {
      debugPrint("[AuthenticatedRoot] Fehler bei PushService init: $e");
    }

    if (mounted) {
      setState(() {
        _pushInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar(index: widget.index);
  }
}