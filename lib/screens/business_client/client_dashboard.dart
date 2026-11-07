import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/notification_inbox.dart';
import '../../theme/app_theme.dart';
import '../../widgets/live_notifications.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/lazy_indexed_stack.dart';
import '../notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'add_order_screen.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'transactions_screen.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  int _selectedIndex = 0;

  List<Widget> _screens() => [
        DashboardScreen(onSeeAll: () => _onItemTapped(1)),
        const OrdersScreen(),
        const AddOrderScreen(),
        const TransactionsPage(),
        NotificationsScreen(active: _selectedIndex == 4),
      ];

  List<String> _titles(AppStrings s) => [
        s.home,
        s.orders,
        s.add,
        s.transactions,
        s.notifications,
      ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _titles(s)[_selectedIndex],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const LanguageToggle(
                    compact: true,
                    color: AppColors.espresso,
                  ),
                  IconButton(
                    tooltip: s.settings,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.settings_outlined,
                      size: 26,
                      color: AppColors.espresso,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: LazyIndexedStack(
              index: _selectedIndex,
              children: _screens(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: NotificationInbox.instance,
        builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.brand,
          unselectedItemColor: AppColors.espresso.withValues(alpha: 0.55),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: s.home),
            BottomNavigationBarItem(icon: const Icon(Icons.list_alt_outlined), label: s.orders),
            BottomNavigationBarItem(icon: const Icon(Icons.add_circle_outline), label: s.add),
            BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), label: s.transactions),
            BottomNavigationBarItem(
              icon: NotificationBell(
                unread: NotificationInbox.instance.unread,
                outlined: true,
              ),
              label: s.notifications,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
