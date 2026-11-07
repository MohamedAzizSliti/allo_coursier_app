import 'package:flutter/material.dart';

import '../services/notification_api_service.dart';
import '../services/notification_inbox.dart';
import '../services/push_notification_service.dart';
import '../services/session_controller.dart';

/// Starts the inbox poll while a staff member or expéditeur is signed in,
/// and posts each new notification to the phone's status bar.
class LiveNotificationHost extends StatefulWidget {
  const LiveNotificationHost({super.key, required this.child});

  final Widget child;

  @override
  State<LiveNotificationHost> createState() => _LiveNotificationHostState();
}

class _LiveNotificationHostState extends State<LiveNotificationHost>
    with WidgetsBindingObserver {
  final PushNotificationService _push = PushNotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationInbox.instance.onArrived = _show;
    SessionController.instance.addListener(_sync);
    _push.initialize();
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SessionController.instance.removeListener(_sync);
    if (identical(NotificationInbox.instance.onArrived, _show)) {
      NotificationInbox.instance.onArrived = null;
    }
    NotificationInbox.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && SessionController.instance.isSignedIn) {
      NotificationInbox.instance.refresh();
    }
  }

  void _sync() {
    final session = SessionController.instance;
    final live = session.isSignedIn &&
        !session.mustChangePassword &&
        !session.profileIncomplete;
    if (live) {
      NotificationInbox.instance.start();
    } else {
      NotificationInbox.instance.stop();
    }
  }

  Future<void> _show(NotificationItem item) async {
    try {
      await _push.showLocalNotification(
        title: item.title,
        body: item.body,
        id: item.id.hashCode,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.unread, this.outlined = false});

  final int unread;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(outlined ? Icons.notifications_outlined : Icons.notifications);
    if (unread <= 0) return icon;
    final label = unread > 9 ? '9+' : '$unread';
    return Badge(label: Text(label), child: icon);
  }
}
