import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../services/commande_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import 'commande_details_screen.dart';

/// Admin ledger: delivered unpaid vs paid parcels (web `/admin-portal/transactions`).
class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final CommandeApiService _service = CommandeApiService();
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  /// API shipment: Livré = unpaid delivered, Payé = paid.
  String _tab = 'Livré';
  List<CommandeModel> _rows = [];
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  double _amount = 0;
  double _fees = 0;
  bool _sumsLoading = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    await Future.wait([_fetch(reset: true), _loadSums()]);
  }

  Future<void> _loadSums() async {
    setState(() => _sumsLoading = true);
    try {
      final sums = await _service.paymentSums(
        shipment: _tab,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _amount = sums.amount;
        _fees = sums.deliveryFees;
        _sumsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sumsLoading = false);
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
        search: _searchController.text,
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
    setState(() => _tab = tab);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final money = NumberFormat.currency(symbol: 'DT ', decimalDigits: 2);
    return Scaffold(
      appBar: AppBar(title: Text(s.transactions)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              s.adminTransactionsHint,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _TabChip(
                    label: s.unpaid,
                    selected: _tab == 'Livré',
                    onTap: () => _setTab('Livré'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabChip(
                    label: s.paid,
                    selected: _tab == 'Payé',
                    onTap: () => _setTab('Payé'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _SumCard(
                    label: s.parcelAmount,
                    value: _sumsLoading ? '…' : money.format(_amount),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SumCard(
                    label: s.deliveryFees,
                    value: _sumsLoading ? '…' : money.format(_fees),
                    valueColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s.searchOrdersHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reload(),
            ),
          ),
          Expanded(child: _body(s, money)),
        ],
      ),
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
      return EmptyState(
        message: s.noOrdersForSelection,
        icon: Icons.receipt_long_outlined,
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
          return Card(
            child: ListTile(
              title: Text(
                'HT${order.id}  ${order.produitNom.isEmpty ? s.parcels : order.produitNom}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  if (order.expediteurName.isNotEmpty) order.expediteurName,
                  if (order.clientNom.isNotEmpty) order.clientNom,
                  if ((order.date ?? '').isNotEmpty) order.date!,
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money.format(order.produitPrixTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${s.feesShort} ${money.format(order.fraisLivraison)}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    order.paid ? s.paid : s.unpaid,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: order.paid ? Colors.green.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CommandeDetailsScreen(commandeId: order.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.espresso : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.espresso,
            ),
          ),
        ),
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  const _SumCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.espresso,
            ),
          ),
        ],
      ),
    );
  }
}
