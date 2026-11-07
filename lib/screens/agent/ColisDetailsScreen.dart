import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/commande_api_service.dart';
import '../../services/pdf_preview.dart';
import '../../services/vehicle_api_service.dart';
import '../../widgets/parcel_amounts_card.dart';
import '../../widgets/vehicle_dropdown.dart';

class ColisDetailsScreen extends StatefulWidget {
  final String colisId;

  const ColisDetailsScreen({required this.colisId, super.key});

  @override
  State<ColisDetailsScreen> createState() => _ColisDetailsScreenState();
}

class _ColisDetailsScreenState extends State<ColisDetailsScreen> {
  final CommandeApiService _commandeService = CommandeApiService();
  final VehicleApiService _vehicleService = VehicleApiService();

  DateTime? selectedDate;
  String? selectedVehicle;
  CommandeModel? colisData;
  List<VehicleModel> vehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _commandeService.getCommande(widget.colisId),
        _vehicleService.listVehicles(),
      ]);
      if (!mounted) return;

      setState(() {
        colisData = results[0] as CommandeModel;
        vehicles = results[1] as List<VehicleModel>;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading colis: $e');
      if (mounted) {
        _showMessage(context.s.cannotLoadParcel);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => isLoading = false);
  }

  Future<void> _confirmDelivery() async {
    if (selectedDate == null || selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.fillAllFields)),
      );
      return;
    }

    try {
      await _commandeService.confirmColis(
        widget.colisId,
        vehicleId: selectedVehicle!,
        deliveryDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.parcelConfirmed)),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error confirming: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Exception ? e.toString() : context.s.confirmError,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.parcelDetails),
        backgroundColor: const Color(0xFF6D4C41),
        actions: [
          if (colisData != null)
            IconButton(
              tooltip: context.s.print,
              icon: const Icon(Icons.print_outlined),
              onPressed: () => showPdfPreview(colisData!),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : colisData == null
              ? Center(child: Text(context.s.noDetailsFound))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.s.parcelTitle(colisData!.displayId),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        Text(
                          context.s.clientName(colisData!.clientNom),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(context.s.phoneLine(colisData!.clientTelephone)),
                        Text('${context.s.address}: ${colisData!.clientAdresse}'),
                        const Divider(),
                        Text(
                          '${context.s.product}: ${colisData!.produitNom}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${context.s.price}: ${context.s.amountTnd('${colisData!.produitPrixTotal}')}'),
                        const SizedBox(height: 10),
                        ParcelAmountsCard(
                          colisPrice: colisData!.produitPrixTotal,
                          deliveryFee: colisData!.fraisLivraison,
                        ),
                        const Divider(),
                        Text(
                          '${context.s.sender}: ${colisData!.expediteurName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        Text(context.s.selectDeliveryDate),
                        ElevatedButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() => selectedDate = pickedDate);
                            }
                          },
                          child: Text(
                            selectedDate == null
                                ? context.s.chooseDate
                                : DateFormat('dd/MM/yyyy').format(selectedDate!),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(context.s.selectVehicle),
                        VehicleDropdown(
                          vehicles: vehicles,
                          value: selectedVehicle,
                          hint: context.s.chooseVehicle,
                          onChanged: (value) =>
                              setState(() => selectedVehicle = value),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _confirmDelivery,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: Text(
                              context.s.confirm,
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
