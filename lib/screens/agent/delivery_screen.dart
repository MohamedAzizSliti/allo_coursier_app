import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/circuit_api_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/vehicle_api_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/parcel_amounts_card.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/vehicle_dropdown.dart';
import 'GenerateDeliveryPDF.dart';
import 'commande_details_screen.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final CommandeApiService _commandeService = CommandeApiService();
  final VehicleApiService _vehicleService = VehicleApiService();
  final CircuitApiService _circuitService = CircuitApiService();
  final UserApiService _userService = UserApiService();

  String? selectedCarId;
  List<CommandeModel> activeDeliveries = [];
  /// Calendar day only — same as web delivery-circuit (date required).
  DateTime? selectedDate;
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  bool _generating = false;
  String? _error;

  List<VehicleModel> _vehicles = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    _fetchVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles() async {
    try {
      final vehicles = await _vehicleService.listVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = context.s.cannotLoadVehicles);
    }
  }

  Future<void> _fetchActiveDeliveries() async {
    if (selectedCarId == null) {
      setState(() {
        activeDeliveries = [];
        isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      activeDeliveries = [];
      _error = null;
    });

    try {
      // Same query as web delivery-circuit: vehicle + delivery day range.
      final day = selectedDate ?? DateTime.now();
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final page = await _commandeService.listCommandesPage(
        pageSize: CommandeApiService.maxPageSize,
        vehicleId: selectedCarId,
        deliveryFrom: start.toUtc().toIso8601String(),
        deliveryTo: end.toUtc().toIso8601String(),
      );
      if (!mounted) return;

      setState(() {
        activeDeliveries = page.rows;
        isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          activeDeliveries = [];
          isLoading = false;
          _error = context.s.cannotLoadDeliveries;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      _fetchActiveDeliveries();
    }
  }

  Map<String, Map<String, List<CommandeModel>>> _categorizeDeliveries() {
    final Map<String, Map<String, List<CommandeModel>>> categorizedData = {};
    for (final order in activeDeliveries) {
      final governorate = order.clientGouvernorat.isEmpty ? context.s.unknown : order.clientGouvernorat;
      final status = order.status;
      categorizedData.putIfAbsent(governorate, () => {});
      categorizedData[governorate]!.putIfAbsent(status, () => []);
      categorizedData[governorate]![status]!.add(order);
    }
    return categorizedData;
  }

  Future<void> _generateCircuit() async {
    if (_generating) return;
    if (selectedCarId == null) {
      Fluttertoast.showToast(
        msg: context.s.noVehicleSelected,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    if (selectedDate == null) {
      Fluttertoast.showToast(
        msg: context.s.chooseDate,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final matched = _vehicles.where((v) => v.id == selectedCarId);
    final vehicle = matched.isEmpty ? null : matched.first;
    if (vehicle == null) {
      Fluttertoast.showToast(
        msg: context.s.noVehicleSelected,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final livreurId = vehicle.livreur?.trim();
    if (livreurId == null || livreurId.isEmpty) {
      Fluttertoast.showToast(
        msg: context.s.noDriverAssigned,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final day = selectedDate!;
      final dayKey = DateFormat('yyyy-MM-dd').format(day);
      final bonFuture = _circuitService.bonLivraison(
        vehicleId: vehicle.id,
        day: dayKey,
      );

      String livreurName = context.s.unknown;
      try {
        final UserModel livreur = await _userService.getUser(livreurId);
        final name = livreur.name.trim();
        if (name.isNotEmpty) livreurName = name;
      } catch (_) {
        // Sheet still useful without the driver profile.
      }

      final bon = await bonFuture;
      if (!mounted) return;

      await printAndShowPDF(
        orders: activeDeliveries,
        livreurName: livreurName,
        vehicleLabel: vehicle.displayName,
        date: day,
        bonLivraison: bon,
      );
    } catch (e) {
      if (!mounted) return;
      final detail = e is AlloException ? e.message : context.s.cannotGenerateCircuit;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detail)),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesByGovernorate = _categorizeDeliveries();
    final totalCommandes = activeDeliveries.length;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ErrorBanner(message: _error!, onRetry: _fetchVehicles),
            Text(
              context.s.selectCar,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            VehicleDropdown(
              vehicles: _vehicles,
              value: selectedCarId,
              hint: context.s.selectVehicle,
              onChanged: (value) {
                setState(() => selectedCarId = value);
                _fetchActiveDeliveries();
              },
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _generating ? null : () => _selectDate(context),
              child: Text(
                selectedDate == null
                    ? context.s.chooseDate
                    : DateFormat('yyyy-MM-dd').format(selectedDate!),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.s.totalOrders(totalCommandes),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: deliveriesByGovernorate.isEmpty
                        ? EmptyState(message: context.s.noDeliveries)
                        : ListView(
                      children: deliveriesByGovernorate.entries.map((entry) {
                        final governorate = entry.key;
                        final statuses = entry.value;
                        final governorateTotal = statuses.values.fold(0, (sum, list) => sum + list.length);

                        return ExpansionTile(
                          title: Text(
                            '$governorate ($governorateTotal)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          children: statuses.entries.map((statusEntry) {
                            final status = statusEntry.key;
                            final orders = statusEntry.value;
                            return ExpansionTile(
                              title: Row(
                                children: [
                                  StatusChip(status: status),
                                  const SizedBox(width: 8),
                                  Text('(${orders.length})'),
                                ],
                              ),
                              children: orders.map((order) {
                                return ListTile(
                                  title: Text(context.s.orderTitle(order.displayId)),
                                  isThreeLine: true,
                                  subtitle: ParcelAmountLines(
                                    colisPrice: order.produitPrixTotal,
                                    deliveryFee: order.fraisLivraison,
                                    dense: true,
                                  ),
                                  trailing: const Icon(Icons.arrow_forward, size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CommandeDetailsScreen(commandeId: order.id),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton(
          onPressed: !isLoading &&
                  _error == null &&
                  selectedCarId != null &&
                  activeDeliveries.isNotEmpty &&
                  !_generating
              ? _generateCircuit
              : null,
          child: _generating
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(context.s.generateCircuit),
        ),
      ),
    );
  }
}
