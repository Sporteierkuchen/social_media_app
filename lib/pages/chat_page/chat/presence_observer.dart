import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../../../repositories/user_repository.dart';


class PresenceObserver extends StatefulWidget {
  final Widget child;
  const PresenceObserver({super.key, required this.child});

  @override
  State<PresenceObserver> createState() => _PresenceObserverState();
}

class _PresenceObserverState extends State<PresenceObserver>
    with WidgetsBindingObserver {
  final _repo = UserRepository();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final uid = _uid;
    if (uid != null) {
      _repo.setOnline(uid);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    final uid = _uid;
    if (uid != null) {
      _repo.setOffline(uid);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = _uid;
    if (uid == null) return;

    if (state == AppLifecycleState.resumed) {
      _repo.setOnline(uid);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _repo.setOffline(uid);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
