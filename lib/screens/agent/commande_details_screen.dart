import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/parcel_status.dart';
import '../../models/user_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/parcel_transition_service.dart';
import '../../services/pdf_preview.dart';
import '../../services/vehicle_api_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/livreur_picker_sheet.dart';
import '../../widgets/parcel_amounts_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/vehicle_picker_sheet.dart';

class CommandeDetailsScreen extends StatefulWidget {
  final String commandeId;

  const CommandeDetailsScreen({super.key, required this.commandeId});

  @override
  State<CommandeDetailsScreen> createState() => _CommandeDetailsScreenState();
}

class _CommandeDetailsScreenState extends State<CommandeDetailsScreen> {
  final CommandeApiService _commandeService = CommandeApiService();
  final UserApiService _userService = UserApiService();
  final VehicleApiService _vehicleService = VehicleApiService();
  final ParcelTransitionService _transitions = const ParcelTransitionService();

  CommandeModel? _commande;
  OfficeRole _role = OfficeRole.businessClient;
  String? _driverName;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCommandeDetails();
  }

  Future<void> _fetchCommandeDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = parseOfficeRole(await AlloApi.instance.getStoredRole());
      final commande = await _commandeService.getCommande(widget.commandeId);
      if (!mounted) return;
      setState(() {
        _role = role;
        _commande = commande;
        _loading = false;
      });
      unawaited(_loadDriverName(commande.livreurId));
    } on AlloException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.isForbidden
            ? context.s.forbiddenOrder
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.s.cannotLoadOrder;
      });
    }
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  void _launchPhoneCall(String phoneNumber) async {
    final url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(okMessage)));
      await _fetchCommandeDetails();
    } on AlloException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.updateError)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleRelivrerAction() async {
    final selectedDate = await _selectDate(context);
    if (selectedDate == null || !mounted) return;
    await _run(
      () => _commandeService.relivrer(
        widget.commandeId,
        deliveryDate: DateFormat('yyyy-MM-dd').format(selectedDate),
      ),
      context.s.rescheduledDepot,
    );
  }

  Future<void> _loadDriverName(String? livreurId) async {
    if (livreurId == null || livreurId.isEmpty) {
      if (mounted) setState(() => _driverName = null);
      return;
    }
    try {
      final driver = await _userService.getUser(livreurId);
      if (!mounted) return;
      setState(() => _driverName = driver.name);
    } catch (_) {
      if (mounted) setState(() => _driverName = livreurId);
    }
  }

  Future<UserModel?> _pickDriver() async {
    try {
      final drivers = await _userService.listUsers(role: 'delivery_person');
      if (!mounted) return null;
      return LivreurPickerSheet.show(
        context,
        drivers: drivers,
        selectedId: _commande?.livreurId,
      );
    } on AlloException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.cannotLoadDrivers)),
      );
      return null;
    }
  }

  Future<void> _changeDelivery() async {
    final driver = await _pickDriver();
    if (driver == null || !mounted) return;
    await _run(
      () => _commandeService.assignDelivery(
        widget.commandeId,
        livreurId: driver.id,
      ),
      context.s.deliveryChanged,
    );
  }

  Future<VehicleModel?> _pickVehicle() async {
    try {
      final vehicles = await _vehicleService.listVehicles();
      final available = vehicles.where((vehicle) => vehicle.status == 'available').toList();
      if (!mounted) return null;
      return VehiclePickerSheet.show(
        context,
        vehicles: available,
        selectedId: _commande?.vehicleId,
      );
    } on AlloException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.noVehicles)),
      );
      return null;
    }
  }

  Future<void> _assignAndRoute() async {
    final vehicle = await _pickVehicle();
    if (vehicle == null || !mounted) return;
    await _run(
      () => _commandeService.staffClaim(
        widget.commandeId,
        vehicleId: vehicle.id,
      ),
      context.s.parcelInRoute,
    );
  }

  Future<void> _pay() async {
    await _run(
      () => _commandeService.pay(widget.commandeId),
      context.s.markedPaid,
    );
  }

  Future<void> _returnToDepot() async {
    await _run(
      () => _commandeService.patchCommande(widget.commandeId, {
        'status': 'En dépôt',
      }),
      context.s.returnedToDepot,
    );
  }

  Future<void> _delete() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.s.deleteOrder),
        content: Text(context.s.deleteForever),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.s.delete),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _commandeService.deleteCommande(widget.commandeId);
      if (!mounted) return;
      Navigator.pop(context);
    } on AlloException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return context.s.na;
    return DateFormat('dd MMMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final commande = _commande;
    final status = parseParcelStatus(commande?.status);
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.orderDetails),
        actions: [
          if (commande != null)
            IconButton(
              tooltip: s.print,
              icon: const Icon(Icons.print_outlined),
              onPressed: _busy ? null : () => showPdfPreview(commande),
            ),
          if (commande != null && _transitions.canDeleteCommande(_role))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorBanner(message: _error!, onRetry: _fetchCommandeDetails)
          : commande == null
          ? Center(child: Text(s.orderNotFound))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ParcelAmountsCard(
                      colisPrice: commande.produitPrixTotal,
                      deliveryFee: commande.fraisLivraison,
                    ),
                    const SizedBox(height: 10),
                    _buildExpandableSection(s.client, [
                      _buildListTile(Icons.person, s.name, commande.clientNom),
                      _buildListTile(
                        Icons.phone,
                        s.phone,
                        commande.clientTelephone,
                      ),
                      _buildListTile(
                        Icons.location_on,
                        s.address,
                        commande.clientAdresse,
                      ),
                      _buildListTile(
                        Icons.location_city,
                        s.city,
                        '${commande.clientVille}, ${commande.clientGouvernorat}',
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _buildExpandableSection(s.delivery, [
                      _buildListTile(
                        Icons.calendar_today,
                        s.orderDate,
                        _formatDate(commande.dateTime),
                      ),
                      _buildListTile(
                        Icons.delivery_dining,
                        s.type,
                        commande.livraison,
                      ),
                      _buildListTile(
                        Icons.event,
                        s.deliveryDate,
                        _formatDate(commande.deliveryDateTime),
                      ),
                      _buildListTile(
                        Icons.monetization_on,
                        s.deliveryFees,
                        s.amountTnd('${commande.fraisLivraison}'),
                      ),
                      _buildListTile(
                        Icons.local_shipping_outlined,
                        s.selectVehicle,
                        commande.vehicleId ?? s.noVehicleSelected,
                      ),
                      _buildListTile(
                        Icons.delivery_dining,
                        s.selectDriver,
                        _driverName ?? commande.livreurId ?? s.noDriver,
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _buildExpandableSection(s.product, [
                      _buildListTile(
                        Icons.shopping_cart,
                        s.name,
                        commande.produitNom,
                      ),
                      _buildListTile(
                        Icons.attach_money,
                        s.price,
                        s.amountTnd('${commande.produitPrixTotal}'),
                      ),
                      _buildListTile(
                        commande.produitFragile
                            ? Icons.warning
                            : Icons.check_circle,
                        s.fragile,
                        commande.produitFragile ? s.yes : s.no,
                        iconColor: commande.produitFragile
                            ? Colors.red
                            : Colors.green,
                      ),
                      _buildListTile(
                        Icons.visibility,
                        s.openBeforePay,
                        commande.produitOuvrirAvantPaiement ? s.yes : s.no,
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _buildExpandableSection(s.sender, [
                      _buildListTile(
                        Icons.business,
                        s.name,
                        commande.expediteurName,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        StatusChip(status: commande.status),
                        const SizedBox(width: 8),
                        Chip(label: Text(commande.paid ? s.paid : s.unpaid)),
                      ],
                    ),
                    if (commande.reason != null &&
                        commande.reason!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(s.reasonLabel(commande.reason!)),
                      ),
                    ],
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    if (status != null &&
                        _transitions.canReassignDelivery(status, _role)) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _changeDelivery,
                          icon: const Icon(Icons.swap_horiz),
                          label: Text(
                            commande.livreurId == null
                                ? s.assignDriver
                                : s.changeDriver,
                          ),
                        ),
                      ),
                    ],
                    if (status != null &&
                        _transitions.canStaffClaim(status, _role)) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _assignAndRoute,
                          icon: const Icon(Icons.local_shipping),
                          label: Text(s.putInRoute),
                        ),
                      ),
                    ],
                    if (status != null &&
                        _transitions.canAdminRelivrer(status, _role)) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _busy ? null : _handleRelivrerAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          s.reliverNow,
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                    if (status != null &&
                        _transitions.canPay(status, commande.paid, _role)) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : _pay,
                        icon: const Icon(Icons.payments),
                        label: Text(s.markPaid),
                      ),
                    ],
                    if (status != null &&
                        _transitions.canReturnToDepot(status, _role)) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _busy ? null : _returnToDepot,
                        child: Text(s.returnDepot),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExpandableSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        iconColor: Colors.blue,
        collapsedIconColor: Colors.blue,
        children: children,
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle, {
    Color iconColor = Colors.blue,
  }) {
    final isPhoneNumber = RegExp(r'^[0-9 +]+$').hasMatch(subtitle);

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: isPhoneNumber
          ? GestureDetector(
              onTap: () => _launchPhoneCall(subtitle),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          : Text(subtitle),
    );
  }
}
