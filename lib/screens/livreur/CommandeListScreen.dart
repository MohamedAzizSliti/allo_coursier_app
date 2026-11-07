import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/parcel_status.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_api_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../agent/commande_details_screen.dart';
import 'driver_parcel_card.dart';

class CommandeListScreen extends StatefulWidget {
  final String statusFilter;

  const CommandeListScreen({super.key, required this.statusFilter});

  @override
  State<CommandeListScreen> createState() => _CommandeListScreenState();
}

class _CommandeListScreenState extends State<CommandeListScreen> {
  final CommandeApiService _commandeService = CommandeApiService();

  List<CommandeModel> _commandes = [];
  bool _isLoading = true;
  bool _noVehicle = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCommandes();
  }

  Future<UserModel?> _resolveDriver() async {
    var driver = SessionController.instance.user;
    try {
      final live = await AuthApiService().getCurrentUser();
      SessionController.instance.rememberUser(live);
      return live;
    } catch (_) {
      if (driver != null && driver.id.isNotEmpty) return driver;
      final stored = await AlloApi.instance.getStoredUserId();
      if (stored == null || stored.isEmpty) return null;
      return UserModel(
        id: stored,
        email: '',
        name: '',
        role: 'delivery_person',
      );
    }
  }

  Future<void> _fetchCommandes() async {
    setState(() => _isLoading = true);
    try {
      final driver = await _resolveDriver();
      if (driver == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = context.s.cannotLoadOrders;
          });
        }
        return;
      }

      final vehicle = driver.vehicleId?.trim();
      if (vehicle == null || vehicle.isEmpty) {
        if (!mounted) return;
        setState(() {
          _commandes = const [];
          _noVehicle = true;
          _isLoading = false;
          _error = null;
        });
        return;
      }

      final rows = await _commandeService.listAssignedParcels(
        driver,
        shipment: widget.statusFilter,
      );
      final wanted = parseParcelStatus(widget.statusFilter);
      final myOrders = wanted == null
          ? rows
          : rows.where((c) => parseParcelStatus(c.status) == wanted).toList();
      if (!mounted) return;

      setState(() {
        _commandes = myOrders;
        _noVehicle = false;
        _isLoading = false;
        _error = null;
      });
    } on AlloException catch (e) {
      if (e.isUnauthorized) {
        await SessionController.instance.signedOut();
        return;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.isForbidden ? context.s.forbiddenOrders : e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = context.s.cannotLoadOrders;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = statusLabel(widget.statusFilter, context.s);
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: AppColors.beige,
        foregroundColor: AppColors.espresso,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.espresso,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.espresso),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorBanner(message: _error!, onRetry: _fetchCommandes)
          : RefreshIndicator(
              onRefresh: _fetchCommandes,
              color: AppColors.brand,
              child: _commandes.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.5,
                          child: EmptyState(
                            message: _noVehicle
                                ? context.s.noVehicleAssigned
                                : context.s.noOrders,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _commandes.length,
                      itemBuilder: (context, index) {
                        final commande = _commandes[index];
                        return DriverParcelCard(
                          commande: commande,
                          onOpen: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommandeDetailsScreen(
                                  commandeId: commande.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
