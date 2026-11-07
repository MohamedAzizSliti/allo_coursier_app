import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/driver_day_stats.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_api_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/language_toggle.dart';
import '../notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/notification_inbox.dart';
import 'CommandeListScreen.dart';
import 'QRScannerScreen.dart';
import 'driver_home_view.dart';

class LivreurDashboard extends StatefulWidget {
  const LivreurDashboard({super.key});

  @override
  State<LivreurDashboard> createState() => _LivreurDashboardState();
}

class _LivreurDashboardState extends State<LivreurDashboard> {
  final CommandeApiService _commandeService = CommandeApiService();

  int totalColis = 0;
  int deliveredColis = 0;
  int enLivrer = 0;
  int annuler = 0;
  int relivrer = 0;
  double earnings = 0.0;
  String _name = '';
  bool _loading = true;
  bool _noVehicle = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    NotificationInbox.instance.addListener(_onInbox);
    fetchCommandeStats();
  }

  @override
  void dispose() {
    NotificationInbox.instance.removeListener(_onInbox);
    super.dispose();
  }

  void _onInbox() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshData() async {
    await fetchCommandeStats();
  }

  Future<UserModel?> _resolveDriver() async {
    var driver = SessionController.instance.user;
    if (driver == null || driver.id.isEmpty) {
      final stored = await AlloApi.instance.getStoredUserId();
      if (stored == null || stored.isEmpty) return null;
      driver = UserModel(
        id: stored,
        email: '',
        name: '',
        role: 'delivery_person',
      );
    }
    try {
      final live = await AuthApiService().getCurrentUser();
      SessionController.instance.rememberUser(live);
      return live;
    } catch (_) {
      return driver;
    }
  }

  Future<void> fetchCommandeStats() async {
    setState(() => _loading = true);
    try {
      final driver = await _resolveDriver();
      if (driver == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = context.s.cannotLoadStats;
          });
        }
        return;
      }

      final vehicle = driver.vehicleId?.trim();
      if (vehicle == null || vehicle.isEmpty) {
        if (!mounted) return;
        setState(() {
          _name = driver.name.trim();
          totalColis = 0;
          deliveredColis = 0;
          enLivrer = 0;
          annuler = 0;
          relivrer = 0;
          earnings = 0;
          _noVehicle = true;
          _error = null;
          _loading = false;
        });
        return;
      }

      final rows = await _commandeService.listAssignedParcels(driver);
      if (!mounted) return;
      final stats = DriverDayStats.fromRows(rows);
      final name = driver.name.trim().isNotEmpty
          ? driver.name.trim()
          : context.s.roleDriver;

      setState(() {
        _name = name;
        totalColis = stats.total;
        deliveredColis = stats.delivered;
        enLivrer = stats.inRoute;
        annuler = stats.cancelled;
        relivrer = stats.redeliver;
        earnings = stats.earnings;
        _noVehicle = false;
        _error = null;
        _loading = false;
      });
    } on AlloException catch (e) {
      if (e.isUnauthorized) {
        await SessionController.instance.signedOut();
        return;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _error = context.s.cannotLoadStats;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = context.s.cannotLoadStats;
        });
      }
    }
  }

  void _navigateTo(String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandeListScreen(statusFilter: status),
      ),
    );
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime.now());
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
                      s.driverDashboard,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const LanguageToggle(
                    compact: true,
                    color: AppColors.espresso,
                  ),
                  IconButton(
                    tooltip: s.notifications,
                    icon: Badge(
                      isLabelVisible: NotificationInbox.instance.unread > 0,
                      label: Text('${NotificationInbox.instance.unread}'),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 26,
                        color: AppColors.espresso,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(title: Text(s.notifications)),
                            body: const NotificationsScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: s.settings,
                    icon: const Icon(
                      Icons.settings_outlined,
                      size: 26,
                      color: AppColors.espresso,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.brand,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null)
                    ErrorBanner(message: _error!, onRetry: fetchCommandeStats),
                  if (_noVehicle)
                    EmptyState(message: s.noVehicleAssigned)
                  else
                    DriverHomeView(
                    name: _name.isEmpty ? s.roleDriver : _name,
                    dateLabel: dateLabel,
                    total: totalColis,
                    inRoute: enLivrer,
                    delivered: deliveredColis,
                    cancelled: annuler,
                    redeliver: relivrer,
                    earnings: earnings,
                    onOpenStatus: _navigateTo,
                    onScan: _openScanner,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
