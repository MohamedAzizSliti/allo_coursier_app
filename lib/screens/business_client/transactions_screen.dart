import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../services/transaction_api_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TransactionApiService _service = TransactionApiService();
  List<TransactionItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.listTransactions();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.s.cannotLoadTransactions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorBanner(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return EmptyState(
        message: context.s.noTransactions,
        icon: Icons.payments_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final tx = _items[index];
          final isWithdraw = tx.type == 'retrait';
          return Card(
            child: ListTile(
              leading: Icon(
                isWithdraw ? Icons.arrow_upward : Icons.arrow_downward,
                color: isWithdraw ? Colors.red : Colors.green,
              ),
              title: Text(
                '${tx.montant.toStringAsFixed(2)} DT',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${tx.type}\n${DateFormat('dd/MM/yyyy HH:mm').format(tx.date)}',
              ),
            ),
          );
        },
      ),
    );
  }
}
