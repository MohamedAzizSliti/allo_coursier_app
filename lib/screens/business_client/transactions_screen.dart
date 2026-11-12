import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/colis_payout.dart';
import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../services/auth_api_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/payment_api_service.dart';
import '../../services/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import 'order_details_screen.dart';

/// Expéditeur money: net payout sums + list of paid / unpaid parcels.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final CommandeApiService _service = CommandeApiService();
  final PaymentApiService _payments = PaymentApiService();
  final _scroll = ScrollController();

  /// API: Livré = unpaid delivered, Payé = paid.
  String _tab = 'Livré';
  List<CommandeModel> _rows = [];
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  double _unpaidSum = 0;
  double _paidSum = 0;
  int _unpaidCount = 0;
  int _paidCount = 0;
  bool _sumsLoading = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _loading) return;
    if (_rows.length >= _total) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      _fetch();
    }
  }

  Future<void> _reload() async {
    await _loadSums();
    if (!mounted) return;
    // Prefer the tab that actually has colis so the list is never empty by default.
    final preferred = _unpaidCount > 0
        ? 'Livré'
        : (_paidCount > 0 ? 'Payé' : _tab);
    if (preferred != _tab) {
      setState(() {
        _tab = preferred;
        _rows = [];
        _total = 0;
      });
    }
    await _fetch(reset: true);
  }

  Future<void> _loadSums() async {
    setState(() => _sumsLoading = true);
    try {
      final sums = await _payments.getPayoutSums();
      if (!mounted) return;
      setState(() {
        _unpaidSum = sums.montantReste;
        _paidSum = sums.montantPaye;
        _unpaidCount = sums.unpaidCount;
        _paidCount = sums.paidCount;
        _sumsLoading = false;
      });
    } catch (_) {
      // Endpoint may not be deployed yet — fall back to /auth/me + count-only pages.
      await _loadSumsFallback();
    }
  }

  Future<void> _loadSumsFallback() async {
    try {
      final meFuture = AuthApiService().getCurrentUser();
      final unpaidFuture = _service.listCommandesPage(pageSize: 1, shipment: 'Livré');
      final paidFuture = _service.listCommandesPage(pageSize: 1, shipment: 'Payé');
      final me = await meFuture;
      final unpaidPage = await unpaidFuture;
      final paidPage = await paidFuture;
      if (!mounted) return;
      SessionController.instance.rememberUser(me);
      setState(() {
        _unpaidSum = me.montantReste;
        _paidSum = me.montantPaye;
        _unpaidCount = unpaidPage.total;
        _paidCount = paidPage.total;
        _sumsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _sumsLoading = false);
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _error = null;
        _loading = _rows.isEmpty;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await _service.listCommandesPage(
        page: reset ? 0 : _page,
        shipment: _tab,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _rows = page.rows;
          _page = 1;
        } else {
          _rows = [..._rows, ...page.rows];
          _page += 1;
        }
        _total = page.total;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = context.s.cannotLoadTransactions;
      });
    }
  }

  void _setTab(String tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _rows = [];
      _total = 0;
    });
    _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final money = NumberFormat.currency(symbol: 'DT ', decimalDigits: 2);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            s.moneyHint,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _SumCard(
                  label: s.unpaid,
                  amount: _sumsLoading ? '…' : money.format(_unpaidSum),
                  count: _sumsLoading ? '' : s.colisCount(_unpaidCount),
                  color: Colors.orange.shade800,
                  selected: _tab == 'Livré',
                  onTap: () => _setTab('Livré'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SumCard(
                  label: s.paid,
                  amount: _sumsLoading ? '…' : money.format(_paidSum),
                  count: _sumsLoading ? '' : s.colisCount(_paidCount),
                  color: Colors.green.shade800,
                  selected: _tab == 'Payé',
                  onTap: () => _setTab('Payé'),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _body(s, money)),
      ],
    );
  }

  Widget _body(AppStrings s, NumberFormat money) {
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return ErrorBanner(message: _error!, onRetry: _reload);
    }
    if (_rows.isEmpty) {
      final otherTab = _tab == 'Livré' ? 'Payé' : 'Livré';
      final otherCount = _tab == 'Livré' ? _paidCount : _unpaidCount;
      if (otherCount > 0) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.noOrdersForSelection,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _setTab(otherTab),
                  child: Text(
                    otherTab == 'Payé'
                        ? '${s.paid} (${s.colisCount(otherCount)})'
                        : '${s.unpaid} (${s.colisCount(otherCount)})',
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return EmptyState(
        message: s.noOrdersForSelection,
        icon: Icons.payments_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: _rows.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _rows.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final order = _rows[index];
          final paid = order.paid;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: paid
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Icon(
                  paid ? Icons.check_rounded : Icons.schedule_rounded,
                  color: paid ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
              title: Text(
                order.displayId,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  if (order.clientNom.isNotEmpty) order.clientNom,
                  if (order.produitNom.isNotEmpty) order.produitNom,
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money.format(
                      paid ? creditedNet(order) : order.remainingPayout,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.espresso,
                    ),
                  ),
                  Text(
                    paid ? s.paid : s.netRemainingLine,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: paid ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(orderId: order.id),
                  ),
                ).then((_) {
                  if (mounted) _reload();
                });
              },
            ),
          );
        },
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  const _SumCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String amount;
  final String count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.black12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.espresso,
                ),
              ),
              if (count.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
