import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../services/api_client.dart';
import '../../services/commande_api_service.dart';
import '../../services/dashboard_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import 'commande_details_screen.dart';
import 'commandes_list_screen.dart';
import 'payments_screen.dart';
import 'users_list_screen.dart';
import 'vehicles_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApiService _dashboardService = DashboardApiService();
  final CommandeApiService _commandeService = CommandeApiService();

  DashboardData? _data;
  int _today = 0;
  List<CommandeModel> _recent = const [];
  bool _loading = true;
  String? _error;
  String? _recentError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final from = DateFormat('yyyy-MM-dd').format(now);
    final to = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    try {
      final data = await _dashboardService.getDashboardData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AlloException ? e.message : context.s.cannotLoadDashboard;
      });
      return;
    }

    try {
      final today = await _commandeService.listCommandesPage(
        pageSize: 1,
        deliveryFrom: from,
        deliveryTo: to,
      );
      if (mounted) setState(() => _today = today.total);
    } catch (_) {
      // Today's count stays at the last known value.
    }
    try {
      final recent = await _commandeService.listCommandesPage(pageSize: 6);
      if (!mounted) return;
      setState(() {
        _recent = recent.rows;
        _recentError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recentError = context.s.parcelsUnavailable);
    }
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.brand,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null) ErrorBanner(message: _error!, onRetry: _fetchData),
            if (data != null)
              AdminDashboardView(
                isAdmin: widget.isAdmin,
                counts: {
                  'Tous': data.tous,
                  'En cours': data.enCours,
                  'En dépôt': data.enDepot,
                  'En route': data.enRoute,
                  'Relivrer': data.relivrer,
                  'Livré': data.livre,
                  'Payé': data.paye,
                  'Annuler': data.annuler,
                },
                expediteurs: data.businessClients,
                livreurs: data.deliveryPersons,
                vehicles: data.vehicles,
                today: _today,
                weekDeliveries: data.weekDeliveries,
                enRouteAmount: data.enRouteAmount,
                topPlaces: [
                  for (final place in data.topPlaces)
                    PlaceCount(
                      place['name']?.toString() ?? '',
                      place['count'] is int ? place['count'] as int : 0,
                    ),
                ],
                recent: _recent,
                recentError: _recentError,
                onOpenUsers: (role) => _open(UsersListScreen(role: role)),
                onOpenVehicles: () => _open(const VehiclesListScreen()),
                onOpenToday: () => _open(const OrdersScreen(todayOnly: true)),
                onOpenOrders: (shipment) => _open(OrdersScreen(shipment: shipment)),
                onOpenPayments: () => _open(const PaymentsScreen()),
                onOpenOrder: (id) => _open(CommandeDetailsScreen(commandeId: id)),
              ),
          ],
        ),
      ),
    );
  }
}

class PlaceCount {
  const PlaceCount(this.name, this.count);

  final String name;
  final int count;
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({
    super.key,
    required this.isAdmin,
    required this.counts,
    required this.expediteurs,
    required this.livreurs,
    required this.vehicles,
    required this.today,
    required this.weekDeliveries,
    required this.enRouteAmount,
    required this.topPlaces,
    required this.recent,
    required this.onOpenUsers,
    required this.onOpenVehicles,
    required this.onOpenToday,
    required this.onOpenOrders,
    required this.onOpenPayments,
    required this.onOpenOrder,
    this.recentError,
  });

  final bool isAdmin;
  final Map<String, int> counts;
  final int expediteurs;
  final int livreurs;
  final int vehicles;
  final int today;
  final int weekDeliveries;
  final double enRouteAmount;
  final List<PlaceCount> topPlaces;
  final List<CommandeModel> recent;
  final String? recentError;
  final ValueChanged<String> onOpenUsers;
  final VoidCallback onOpenVehicles;
  final VoidCallback onOpenToday;
  final ValueChanged<String> onOpenOrders;
  final VoidCallback onOpenPayments;
  final ValueChanged<String> onOpenOrder;

  static const filters = [
    'En cours',
    'En dépôt',
    'En route',
    'Relivrer',
    'Livré',
    'Payé',
    'Annuler',
  ];

  static const colors = {
    'En cours': AppColors.warning,
    'En dépôt': AppColors.depot,
    'En route': AppColors.info,
    'Relivrer': AppColors.relivrer,
    'Livré': AppColors.success,
    'Payé': AppColors.mocha,
    'Annuler': AppColors.error,
  };

  int get _total => counts['Tous'] ?? 0;

  int get _circulation =>
      (counts['En cours'] ?? 0) + (counts['En dépôt'] ?? 0) + (counts['En route'] ?? 0);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          dateLabel: dateLabel,
          total: _total,
          circulation: _circulation,
          deliveredPct: s.percentOf(_pct((counts['Livré'] ?? 0) + (counts['Payé'] ?? 0), _total)),
          paidPct: s.percentOf(_pct(counts['Payé'] ?? 0, _total)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Tile(
              icon: Icons.storefront_outlined,
              title: s.senders,
              value: '$expediteurs',
              onTap: () => onOpenUsers('business_client'),
            ),
            const SizedBox(width: 12),
            _Tile(
              icon: Icons.pedal_bike_outlined,
              title: s.drivers,
              value: '$livreurs',
              onTap: () => onOpenUsers('delivery_person'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Tile(
              icon: Icons.local_shipping_outlined,
              title: s.vehicles,
              value: '$vehicles',
              onTap: onOpenVehicles,
            ),
            const SizedBox(width: 12),
            _Tile(
              icon: Icons.inventory_2_outlined,
              title: s.parcelsToday,
              value: '$today',
              onTap: onOpenToday,
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          _TransactionsCard(
            summary: s.transactionsSummary(counts['Livré'] ?? 0, counts['Payé'] ?? 0),
            onTap: onOpenPayments,
          ),
        ],
        const SizedBox(height: 12),
        _StatusMix(
          counts: counts,
          total: _total,
          onOpen: onOpenOrders,
        ),
        const SizedBox(height: 12),
        _PlacesCard(
          weekDeliveries: weekDeliveries,
          enRouteAmount: enRouteAmount,
          places: topPlaces,
          total: _total,
        ),
        const SizedBox(height: 12),
        _RecentCard(
          orders: recent,
          error: recentError,
          onSeeAll: () => onOpenOrders('Tous'),
          onOpen: onOpenOrder,
        ),
      ],
    );
  }

  static double _pct(int part, int total) {
    if (total <= 0) return 0;
    return (part / total) * 100;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.dateLabel,
    required this.total,
    required this.circulation,
    required this.deliveredPct,
    required this.paidPct,
  });

  final String dateLabel;
  final int total;
  final int circulation;
  final String deliveredPct;
  final String paidPct;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            s.parcelsTotal,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric(s.inCirculation, '$circulation'),
              _metric(s.deliveredShare, deliveredPct),
              _metric(s.paidShare, paidPct),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: WebSurfaces.card(radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.brand, size: 20),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.espresso,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: WebSurfaces.card(radius: 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.transactions,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(summary, style: const TextStyle(color: AppColors.textMedium)),
                  ],
                ),
              ),
              Text(
                s.view,
                style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusMix extends StatelessWidget {
  const _StatusMix({
    required this.counts,
    required this.total,
    required this.onOpen,
  });

  final Map<String, int> counts;
  final int total;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebSurfaces.card(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.distribution,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 12,
              child: total <= 0
                  ? const ColoredBox(color: AppColors.cream)
                  : Row(
                      children: [
                        for (final filter in AdminDashboardView.filters)
                          if ((counts[filter] ?? 0) > 0)
                            Expanded(
                              flex: counts[filter]!,
                              child: ColoredBox(
                                color: AdminDashboardView.colors[filter]!,
                              ),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          for (final filter in AdminDashboardView.filters)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.cream.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => onOpen(filter),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AdminDashboardView.colors[filter],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            statusLabel(filter, s),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.espresso,
                            ),
                          ),
                        ),
                        Text(
                          s.percentOf(AdminDashboardView._pct(counts[filter] ?? 0, total)),
                          style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${counts[filter] ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.espresso,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlacesCard extends StatelessWidget {
  const _PlacesCard({
    required this.weekDeliveries,
    required this.enRouteAmount,
    required this.places,
    required this.total,
  });

  final int weekDeliveries;
  final double enRouteAmount;
  final List<PlaceCount> places;
  final int total;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final max = places.isEmpty ? 1 : places.first.count.clamp(1, 1 << 30);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebSurfaces.card(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s.destinations,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(s.thisWeek, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                  Text(
                    '$weekDeliveries',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.espresso,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.enRouteAmount(s.amountTnd(enRouteAmount.toStringAsFixed(2))),
            style: const TextStyle(color: AppColors.textMedium),
          ),
          const SizedBox(height: 12),
          for (final place in places)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                          ),
                        ),
                      ),
                      Text(
                        '${place.count} · ${s.percentOf(AdminDashboardView._pct(place.count, total))}',
                        style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: (place.count / max).clamp(0.04, 1),
                      backgroundColor: AppColors.cream,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.orders,
    required this.onSeeAll,
    required this.onOpen,
    this.error,
  });

  final List<CommandeModel> orders;
  final String? error;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: WebSurfaces.card(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.recentParcels,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              TextButton(onPressed: onSeeAll, child: Text(s.seeAll)),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(error!, style: const TextStyle(color: AppColors.textMedium)),
              ),
            ),
          for (final order in orders) _RecentRow(order: order, onTap: () => onOpen(order.id)),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.order, required this.onTap});

  final CommandeModel order;
  final VoidCallback onTap;

  String get _board {
    if (order.status == 'Livrer' && order.paid) return 'Payé';
    if (order.status == 'Livrer') return 'Livré';
    return order.status;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final place = order.clientGouvernorat.trim().isNotEmpty
        ? order.clientGouvernorat
        : (order.clientVille.trim().isNotEmpty ? order.clientVille : '—');
    final when = order.dateTime == null ? '—' : DateFormat('dd/MM/yyyy').format(order.dateTime!);
    final product = order.produitNom.trim().isEmpty ? s.parcels : order.produitNom;
    final sender = order.expediteurName.trim().isEmpty ? s.senders : order.expediteurName;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.displayId} · $product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.espresso),
                  ),
                  Text(
                    '$sender · $place · $when',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  s.amountTnd(order.produitPrixTotal.toStringAsFixed(2)),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.espresso),
                ),
                Text(
                  statusLabel(_board, s),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _board == 'Payé' ? AppColors.success : AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
