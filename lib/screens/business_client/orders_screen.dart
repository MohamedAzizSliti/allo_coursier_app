import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/parcel_status.dart';
import '../../services/api_client.dart';
import '../../services/commande_api_service.dart';
import '../../services/session_controller.dart';
import '../../services/pdf_preview.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/filter_chip_bar.dart';
import '../../widgets/order_list_card.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final CommandeApiService _commandeService = CommandeApiService();
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  List<CommandeModel> _commandes = [];
  int _total = 0;
  double? _sum;
  int _page = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _selectedStatus = 'Tous';

  final List<String> _statusList = [
    'Tous',
    'En cours',
    'En dépôt',
    'En route',
    'Livrer',
    'Relivrer',
    'Annuler',
    'Payé',
    'Non payé',
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _loading) return;
    if (_commandes.length >= _total) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      _fetch();
    }
  }

  List<CommandeModel> get _filtered {
    return _commandes.where((c) {
      if (_selectedStatus == 'Payé') return c.paid;
      if (_selectedStatus == 'Non payé') return !c.paid;
      if (_selectedStatus == 'Tous') return true;
      return parseParcelStatus(c.status) == parseParcelStatus(_selectedStatus);
    }).toList();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _error = null;
        _loading = _commandes.isEmpty;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      var userId = SessionController.instance.user?.id;
      userId ??= await AlloApi.instance.getStoredUserId();
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _loadingMore = false;
            _error = context.s.cannotLoadOrders;
          });
        }
        return;
      }
      final page = await _commandeService.listCommandesForUserPage(
        userId,
        page: reset ? 0 : _page,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _commandes = page.rows;
          _page = 1;
        } else {
          _commandes = [..._commandes, ...page.rows];
          _page += 1;
        }
        _total = page.total;
        _sum = page.sum;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } on AlloException catch (e) {
      if (e.isUnauthorized) {
        await SessionController.instance.signedOut();
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = context.s.cannotLoadOrders;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = context.s.cannotLoadOrders;
      });
    }
  }

  void _printOrder(CommandeModel commande) {
    showPdfPreview(commande);
  }

  void _viewOrderDetails(CommandeModel commande) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: commande.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final rows = _filtered;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: s.searchByNumber,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _fetch(reset: true),
            ),
          ),
          FilterChipBar(
            values: _statusList,
            selected: _selectedStatus,
            labelOf: (status) => statusLabel(status, s),
            onSelected: (value) => setState(() => _selectedStatus = value),
          ),
          if (_loading && _commandes.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _sum == null
                      ? s.orderCount(_total)
                      : s.orderCountWithSum(_total, _sum!.toStringAsFixed(2)),
                ),
              ),
            ),
          Expanded(
            child: _loading && _commandes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _commandes.isEmpty
                ? ErrorBanner(
                    message: _error!,
                    onRetry: () => _fetch(reset: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetch(reset: true),
                    child: rows.isEmpty
                        ? EmptyState(message: s.noOrders)
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(10),
                            itemCount: rows.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= rows.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final commande = rows[index];
                              return OrderListCard(
                                commande: commande,
                                onView: () => _viewOrderDetails(commande),
                                onPrint: () => _printOrder(commande),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
