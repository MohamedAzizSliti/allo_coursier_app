import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/handover.dart';
import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/commande_api_service.dart';
import '../../services/payment_api_service.dart';
import '../../services/vehicle_api_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/vehicle_dropdown.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final CommandeApiService _commandeService = CommandeApiService();
  final VehicleApiService _vehicleService = VehicleApiService();
  final PaymentApiService _paymentService = PaymentApiService();

  String? selectedVehicleId;
  num totalCollected = 0;
  num totalDeliveryFees = 0;
  num cancellationFees = 0;
  List<CommandeModel> filteredOrders = [];
  DateTime selectedDate = DateTime.now();

  List<VehicleModel> _vehicles = [];
  String? _error;
  bool _loadingVehicles = true;
  bool _loadingOrders = false;
  bool _confirming = false;
  int _ordersRequest = 0;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    if (!_loadingVehicles && mounted) {
      setState(() => _loadingVehicles = true);
    }
    try {
      final vehicles = await _vehicleService.listVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _error = null;
        _loadingVehicles = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = context.s.cannotLoadVehicles;
          _loadingVehicles = false;
        });
      }
    }
  }

  Future<void> _fetchOrders() async {
    if (selectedVehicleId == null) return;
    final request = ++_ordersRequest;
    setState(() {
      _loadingOrders = true;
      _error = null;
    });

    try {
      // deliveryTo is exclusive: the same calendar day for both bounds matches nothing.
      final day = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final page = await _commandeService.listCommandesPage(
        pageSize: CommandeApiService.maxPageSize,
        vehicleId: selectedVehicleId,
        deliveryFrom: DateFormat('yyyy-MM-dd').format(day),
        deliveryTo: DateFormat('yyyy-MM-dd').format(day.add(const Duration(days: 1))),
      );
      if (!mounted || request != _ordersRequest) return;

      final matching = page.rows.where((order) {
        final id = order.vehicleId?.trim();
        return id == null || id.isEmpty || id == selectedVehicleId;
      }).toList();
      final totals = paymentTotals(matching);

      setState(() {
        filteredOrders = matching;
        totalCollected = totals.totalCollected;
        totalDeliveryFees = totals.totalDeliveryFees;
        cancellationFees = totals.cancellationFees;
        _error = null;
        _loadingOrders = false;
      });
    } catch (e) {
      if (mounted && request == _ordersRequest) {
        setState(() {
          _error = context.s.cannotLoadOrders;
          _loadingOrders = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _fetchOrders();
    }
  }

  Future<void> _confirmPayment() async {
    if (filteredOrders.isEmpty) return;

    // Collect IDs of unpaid delivered orders for batch payment
    final orderIds = paymentOrderIds(filteredOrders);

    if (orderIds.isEmpty) return;

    setState(() => _confirming = true);
    try {
      final result = await _paymentService.confirmPayments(orderIds);
      if (!mounted) return;

      _fetchOrders();

      final credits = result['credits'] is List ? (result['credits'] as List).length : 0;
      final penalties = result['penalties'] is List ? (result['penalties'] as List).length : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.paymentConfirmed(credits, penalties))),
      );

      setState(() {
        totalCollected = 0;
        totalDeliveryFees = 0;
        cancellationFees = 0;
      });
    } catch (e) {
      debugPrint('Error confirming payment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Exception ? e.toString() : context.s.paymentError,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.payments),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              ErrorBanner(
                message: _error!,
                onRetry: selectedVehicleId == null ? _fetchVehicles : _fetchOrders,
              ),
            if (_loadingVehicles)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              VehicleDropdown(
                vehicles: _vehicles,
                value: selectedVehicleId,
                hint: s.selectVehicle,
                onChanged: (value) {
                  setState(() => selectedVehicleId = value);
                  _fetchOrders();
                },
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date : ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              s.collectedTotal(totalCollected.toStringAsFixed(2)),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              s.deliveryFeesLine(totalDeliveryFees.toStringAsFixed(2)),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            Text(
              s.cancellationFeesLine(cancellationFees.toStringAsFixed(2)),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loadingOrders
                  ? const Center(child: CircularProgressIndicator())
                  : filteredOrders.isEmpty
                  ? EmptyState(message: s.noOrdersForSelection)
                  : ListView.builder(
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Card(
                          child: ListTile(
                            title: Text(s.orderTitle(order.displayId)),
                            subtitle: Text(s.amountLine('${order.produitPrixTotal}')),
                            trailing: Text(order.paid ? s.paid : s.unpaid),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: !_loadingOrders && !_confirming && filteredOrders.isNotEmpty
                  ? _confirmPayment
                  : null,
              child: _confirming
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(s.confirmPayment),
            ),
          ],
        ),
      ),
    );
  }
}
