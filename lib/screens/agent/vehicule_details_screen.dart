import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

import '../../models/commande_model.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/parcel_transition_service.dart';
import '../../services/vehicle_api_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/livreur_picker_sheet.dart';
import 'commande_details_screen.dart';

class VehiculeDetailsScreen extends StatefulWidget {
  final String vehiculeId;

  const VehiculeDetailsScreen({super.key, required this.vehiculeId});

  @override
  State<VehiculeDetailsScreen> createState() => _VehiculeDetailsScreenState();
}

class _VehiculeDetailsScreenState extends State<VehiculeDetailsScreen> {
  final VehicleApiService _vehicleService = VehicleApiService();
  final UserApiService _userService = UserApiService();
  final CommandeApiService _commandeService = CommandeApiService();

  VehicleModel? vehiculeData;
  UserModel? livreurData;
  List<CommandeModel> commandesList = [];
  String? _error;
  String? _role;

  @override
  void initState() {
    super.initState();
    _fetchVehiculeDetails();
    _fetchCommandes();
  }

  Future<void> _fetchVehiculeDetails() async {
    try {
      final vehicle = await _vehicleService.getVehicle(widget.vehiculeId);
      final role = await AlloApi.instance.getStoredRole();
      if (!mounted) return;
      setState(() {
        vehiculeData = vehicle;
        _role = role;
        _error = null;
      });
      if (vehicle.livreur != null && vehicle.livreur!.isNotEmpty) {
        _fetchLivreurDetails(vehicle.livreur!);
      }
    } catch (e) {
      if (mounted) setState(() => _error = context.s.cannotLoadVehicle);
    }
  }

  Future<void> _fetchLivreurDetails(String livreurId) async {
    try {
      final livreur = await _userService.getUser(livreurId);
      if (!mounted) return;
      setState(() => livreurData = livreur);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.cannotLoadDriver)),
        );
      }
    }
  }

  Future<void> _assignLivreur() async {
    try {
      final users = await _userService.listUsers(role: 'delivery_person');
      if (!mounted) return;
      final picked = await LivreurPickerSheet.show(
        context,
        drivers: users,
        selectedId: vehiculeData?.livreur,
      );
      if (picked == null || !mounted) return;
      await _vehicleService.assignLivreur(widget.vehiculeId, picked.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.deliveryChanged)),
      );
      await _fetchVehiculeDetails();
    } on AlloException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.cannotAssignDriver)),
        );
      }
    }
  }

  Future<void> _fetchCommandes() async {
    try {
      final page = await _commandeService.listColisDuJour(pageSize: 50);
      if (!mounted) return;

      final filtered = page.rows
          .where((c) => c.vehicleId == widget.vehiculeId)
          .toList();

      setState(() => commandesList = filtered);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.cannotLoadOrders)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.s.vehicleDetails)),
      body: _error != null
          ? ErrorBanner(message: _error!, onRetry: _fetchVehiculeDetails)
          : vehiculeData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListTile(
                        leading: const Icon(Icons.car_rental, color: Colors.blue),
                        title: Text(
                          vehiculeData!.displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${context.s.status}: ${statusLabel(vehiculeData!.status, context.s)}'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person, color: Colors.green),
                            title: Text(
                              livreurData != null
                                  ? context.s.driverLine(livreurData!.name)
                                  : context.s.noDriver,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (livreurData != null)
                            ListTile(
                              leading: const Icon(Icons.phone, color: Colors.green),
                              title: Text(context.s.phoneLine(livreurData!.phone ?? context.s.na)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (const ParcelTransitionService()
                      .canAssignVehicleDriver(parseOfficeRole(_role)))
                    FilledButton.icon(
                      onPressed: _assignLivreur,
                      icon: const Icon(Icons.person_add_alt),
                      label: Text(livreurData != null ? context.s.changeDriver : context.s.assignDriver),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    context.s.assignedOrders,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  commandesList.isEmpty
                      ? EmptyState(message: context.s.noOrders)
                      : Expanded(
                          child: ListView.builder(
                            itemCount: commandesList.length,
                            itemBuilder: (context, index) {
                              final commande = commandesList[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CommandeDetailsScreen(commandeId: commande.id),
                                    ),
                                  );
                                },
                                child: Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.local_shipping, color: Colors.blue),
                                    title: Text(context.s.orderTitle(commande.displayId)),
                                    subtitle: Text(context.s.clientName(commande.clientNom)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
