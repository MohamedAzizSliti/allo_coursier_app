import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/notification_inbox.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/live_notifications.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationInbox.instance,
      builder: (context, _) => _bar(context),
    );
  }

  Widget _bar(BuildContext context) {
    final s = context.s;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: s.dashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.route),
          label: s.circuit,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.list_alt),
          label: s.parcels,
        ),
        BottomNavigationBarItem(
          icon: NotificationBell(unread: NotificationInbox.instance.unread),
          label: s.notifications,
        ),
      ],
    );
  }
}
