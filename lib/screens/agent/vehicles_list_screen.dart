import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/vehicle_model.dart';
import '../../services/api_client.dart';
import '../../services/parcel_transition_service.dart';
import '../../services/vehicle_api_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import 'vehicule_details_screen.dart';

class VehiclesListScreen extends StatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  final VehicleApiService _vehicleService = VehicleApiService();

  List<VehicleModel> _vehicles = [];
  bool _isLoading = true;
  String? _error;
  String? _role;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleService.listVehicles();
      final role = await AlloApi.instance.getStoredRole();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _role = role;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = context.s.cannotLoadVehicles;
        });
      }
    }
  }

  void _showAddVehicleDialog() {
    final matriculeController = TextEditingController();
    final modelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.s.addVehicle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: matriculeController, decoration: InputDecoration(labelText: context.s.plate)),
              TextField(controller: modelController, decoration: InputDecoration(labelText: context.s.model)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.s.cancel)),
            FilledButton(
              onPressed: () async {
                if (matriculeController.text.isNotEmpty && modelController.text.isNotEmpty) {
                  try {
                    await _vehicleService.createVehicle(
                      matricule: matriculeController.text,
                      model: modelController.text,
                    );
                    if (context.mounted) Navigator.pop(context);
                    _fetchVehicles();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.s.cannotAddVehicle)),
                      );
                    }
                  }
                }
              },
              child: Text(context.s.add),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.vehicleList),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorBanner(message: _error!, onRetry: _fetchVehicles)
            : RefreshIndicator(
                onRefresh: _fetchVehicles,
                child: _vehicles.isEmpty
                    ? EmptyState(message: context.s.noVehicles)
                    : ListView.builder(
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _vehicles[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.directions_car),
                              title: Text(vehicle.displayName),
                              subtitle: Text('${context.s.status}: ${statusLabel(vehicle.status, context.s)}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VehiculeDetailsScreen(vehiculeId: vehicle.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
      ),
      floatingActionButton: const ParcelTransitionService().canWriteVehicles(parseOfficeRole(_role))
          ? FloatingActionButton(
              onPressed: _showAddVehicleDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
