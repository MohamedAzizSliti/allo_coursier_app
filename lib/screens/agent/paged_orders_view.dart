import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/parcel_status.dart';
import '../../services/commande_api_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/filter_chip_bar.dart';
import '../../widgets/order_list_card.dart';
import '../../services/pdf_preview.dart';
import 'commande_details_screen.dart';

class PagedOrdersView extends StatefulWidget {
  const PagedOrdersView({
    super.key,
    this.initialShipment = 'Tous',
    this.todayOnly = false,
  });

  final String initialShipment;
  final bool todayOnly;

  @override
  State<PagedOrdersView> createState() => _PagedOrdersViewState();
}

class _PagedOrdersViewState extends State<PagedOrdersView> {
  final CommandeApiService _commandeService = CommandeApiService();
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  List<CommandeModel> _rows = [];
  int _total = 0;
  int _page = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _refreshing = false;
  String? _error;
  late String _shipment = widget.initialShipment;

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
    if (_rows.length >= _total) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      _fetch();
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _error = null;
        _loading = _rows.isEmpty;
        _refreshing = _rows.isNotEmpty;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final now = DateTime.now();
      final page = await _commandeService.listCommandesPage(
        page: reset ? 0 : _page,
        shipment: _shipment,
        search: _searchController.text,
        deliveryFrom: widget.todayOnly ? DateFormat('yyyy-MM-dd').format(now) : null,
        deliveryTo: widget.todayOnly
            ? DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)))
            : null,
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
        _refreshing = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _refreshing = false;
        _error = context.s.cannotLoadOrders;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: s.searchByNumber,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _fetch(reset: true),
          ),
        ),
        FilterChipBar(
          values: shipmentFilters,
          selected: _shipment,
          labelOf: (filter) => statusLabel(filter, s),
          onSelected: (value) {
            setState(() {
              _shipment = value;
              _rows = [];
              _total = 0;
            });
            _fetch(reset: true);
          },
        ),
        if (_refreshing) const LinearProgressIndicator(minHeight: 2),
        if (_total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(s.orderCount(_total)),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ErrorBanner(message: _error!, onRetry: () => _fetch(reset: true))
                  : RefreshIndicator(
                      onRefresh: () => _fetch(reset: true),
                      child: _rows.isEmpty
                          ? EmptyState(message: s.noOrders)
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.all(10),
                              itemCount: _rows.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _rows.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final commande = _rows[index];
                                return OrderListCard(
                                  commande: commande,
                                  onView: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CommandeDetailsScreen(
                                          commandeId: commande.id,
                                        ),
                                      ),
                                    );
                                  },
                                  onPrint: () => showPdfPreview(commande),
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}
