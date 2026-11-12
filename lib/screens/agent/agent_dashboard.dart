import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/session_controller.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/lazy_indexed_stack.dart';
import 'admin_transactions_screen.dart';
import 'commande_screen.dart';
import 'dashboard_screen.dart';
import 'delivery_screen.dart';
import 'payments_screen.dart';
import 'reference_screen.dart';
import 'users_list_screen.dart';
import 'vehicles_list_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/floating_qr_button.dart';
import '../business_client/add_order_screen.dart';

class AgentDashboard extends StatefulWidget {
  final String role;
  const AgentDashboard({super.key, required this.role});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  int _selectedIndex = 0;

  bool get _isAdmin => widget.role == 'admin';

  List<Widget> _screens() => [
        DashboardScreen(isAdmin: _isAdmin),
        const DeliveryScreen(),
        const CommandessScreen(),
        NotificationsScreen(active: _selectedIndex == 3),
      ];

  List<String> _titles(AppStrings s) => [
        s.dashboard,
        s.deliveryCircuit,
        s.orderTracking,
        s.notifications,
      ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles(s)[_selectedIndex]),
        elevation: 0,
        actions: [
          const LanguageToggle(compact: true),
          Container(
            margin: const EdgeInsetsDirectional.only(end: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: s.settings,
              icon: const Icon(Icons.settings_outlined, size: 26),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: LazyIndexedStack(
        index: _selectedIndex,
        children: _screens(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: const FloatingQRButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final s = context.s;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isAdmin ? s.adminPanel : s.roleAgent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.managePlatform,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.dashboard_rounded,
              title: s.dashboard,
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0);
              },
            ),
            _DrawerItem(
              icon: Icons.inventory_2_rounded,
              title: s.manageParcels,
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(2);
              },
            ),
            if (_isAdmin)
              _DrawerItem(
                icon: Icons.supervised_user_circle_rounded,
                title: s.manageAgents,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UsersListScreen(role: 'agent'),
                    ),
                  );
                },
              ),
            _DrawerItem(
              icon: Icons.storefront_rounded,
              title: s.roleSenders,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const UsersListScreen(role: 'business_client'),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.person_rounded,
              title: s.manageDrivers,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const UsersListScreen(role: 'delivery_person'),
                  ),
                );
              },
            ),
            if (_isAdmin) ...[
              _DrawerItem(
                icon: Icons.directions_car_rounded,
                title: s.vehicleFleet,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VehiclesListScreen(),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.payment_rounded,
                title: s.paymentManagement,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.receipt_long_rounded,
                title: s.transactions,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminTransactionsScreen(),
                    ),
                  );
                },
              ),
            ],
            _DrawerItem(
              icon: Icons.map_rounded,
              title: s.referenceData,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferenceScreen()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.add_box_rounded,
              title: s.staffNewOrder,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddOrderScreen(staffMode: true),
                  ),
                );
              },
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.logout_rounded,
              title: s.logout,
              textColor: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                await SessionController.instance.signedOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      onTap: onTap,
    );
  }
}
