import 'package:flutter/material.dart';

import '../../domain/account_access.dart';
import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/commande_api_service.dart';
import '../../services/api_client.dart';
import '../../services/payment_api_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import 'commande_details_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  const UserDetailsScreen({super.key, required this.userId});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final UserApiService _userService = UserApiService();
  final CommandeApiService _commandeService = CommandeApiService();
  final PaymentApiService _paymentService = PaymentApiService();
  final _colisSearch = TextEditingController();

  UserModel? userData;
  List<CommandeModel> commandesList = [];
  double montantDisponible = 0.0;
  double montantNonDisponible = 0.0;
  String? _actorRole;
  String? _actorId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _colisSearch.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final results = await Future.wait([
        _userService.getUser(widget.userId),
        AlloApi.instance.getStoredRole(),
        AlloApi.instance.getStoredUserId(),
      ]);
      if (!mounted) return;
      final user = results[0] as UserModel;
      setState(() {
        userData = user;
        _actorRole = results[1] as String?;
        _actorId = results[2] as String?;
        _error = null;
      });
      await _fetchUserColis(user);
    } catch (e) {
      if (mounted) setState(() => _error = context.s.cannotLoadUser);
    }
  }

  Future<void> _fetchUserColis(UserModel user) async {
    try {
      List<CommandeModel> rows;
      if (user.role == 'delivery_person') {
        final vehicleId = user.vehicleId;
        if (vehicleId == null || vehicleId.isEmpty) {
          rows = [];
        } else {
          final page = await _commandeService.listCommandesPage(
            vehicleId: vehicleId,
            pageSize: CommandeApiService.maxPageSize,
            search: _colisSearch.text,
          );
          rows = page.rows;
        }
      } else {
        final page = await _commandeService.listCommandesForUserPage(
          user.id,
          pageSize: CommandeApiService.maxPageSize,
          search: _colisSearch.text,
        );
        rows = page.rows;
      }
      final held = user.role == 'business_client'
          ? await _commandeService.unpaidDeliveredTotalForUser(user.id)
          : 0.0;
      if (!mounted) return;

      setState(() {
        commandesList = rows;
        montantDisponible = userData?.montantDisponible ?? 0.0;
        montantNonDisponible = held;
      });
    } catch (e) {
      debugPrint('Error fetching colis: $e');
    }
  }

  List<CommandeModel> get _filteredColis {
    final q = _colisSearch.text.trim().toLowerCase();
    if (q.isEmpty) return commandesList;
    return commandesList.where((c) {
      final hay = [
        c.id,
        c.displayId,
        c.clientNom,
        c.clientTelephone,
        c.clientVille,
        c.clientGouvernorat,
        c.produitNom,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  bool get _canManage =>
      userData != null &&
      canBanOrDeleteAccount(
        actorRole: _actorRole,
        targetRole: userData!.role,
        actorId: _actorId ?? '',
        targetId: userData!.id,
      );

  Future<void> _retirerMontant() async {
    if (montantDisponible == 0 || userData == null) return;

    try {
      await _paymentService.requestWithdrawal(
        expediteurId: userData!.id,
      );
      if (!mounted) return;

      final withdrawn = montantDisponible;
      setState(() => montantDisponible = 0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.withdrawn(withdrawn.toStringAsFixed(2)))),
      );
    } on AlloException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.withdrawError)),
      );
    }
  }

  Future<void> _confirmBanOrUnban() async {
    final user = userData;
    if (user == null || _busy) return;
    final ban = user.active;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          ban ? context.s.confirmBanAccount : context.s.unbanAccount,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ban ? context.s.banAccount : context.s.unbanAccount),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated =
          ban ? await _userService.banUser(user.id) : await _userService.unbanUser(user.id);
      if (!mounted) return;
      setState(() {
        userData = updated.mergedWith(user);
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ban ? context.s.accountBanned : context.s.accountUnbanned),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.errorLine(context.s.cannotLoadUser))),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final user = userData;
    if (user == null || _busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(context.s.confirmDeleteAccount),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.s.deleteAccount),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _userService.deleteUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.accountDeleted)),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.errorLine(context.s.cannotLoadUser))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colis = _filteredColis;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.userDetails),
        actions: [
          if (_canManage) ...[
            IconButton(
              tooltip: userData!.banned ? context.s.unbanAccount : context.s.banAccount,
              onPressed: _busy ? null : _confirmBanOrUnban,
              icon: Icon(
                userData!.banned ? Icons.lock_open_rounded : Icons.block_rounded,
              ),
            ),
            IconButton(
              tooltip: context.s.deleteAccount,
              onPressed: _busy ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
      body: _error != null
          ? ErrorBanner(message: _error!, onRetry: _fetchUserDetails)
          : userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person, color: Colors.blue),
                              title: Text(
                                userData!.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(context.s.emailLine(userData!.email)),
                              trailing: userData!.banned
                                  ? Chip(
                                      label: Text(context.s.banned),
                                      backgroundColor: Colors.red.shade50,
                                      labelStyle: TextStyle(color: Colors.red.shade800),
                                    )
                                  : null,
                            ),
                            ListTile(
                              leading: const Icon(Icons.verified_user, color: Colors.green),
                              title: Text(context.s.roleLine(context.s.roleSingular(userData!.role))),
                            ),
                            if (userData!.phone != null)
                              ListTile(
                                leading: const Icon(Icons.phone),
                                title: Text(userData!.phone!),
                              ),
                            if (userData!.address != null)
                              ListTile(
                                leading: const Icon(Icons.home_outlined),
                                title: Text(userData!.address!),
                              ),
                            if (userData!.city != null)
                              ListTile(
                                leading: const Icon(Icons.location_city_outlined),
                                title: Text(userData!.city!),
                              ),
                            if (userData!.gouvernorat != null)
                              ListTile(
                                leading: const Icon(Icons.map_outlined),
                                title: Text(userData!.gouvernorat!),
                              ),
                            if (userData!.company != null)
                              ListTile(
                                leading: const Icon(Icons.storefront_outlined),
                                title: Text(userData!.company!),
                              ),
                            if (userData!.cin != null)
                              ListTile(
                                leading: const Icon(Icons.badge_outlined),
                                title: Text(userData!.cin!),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (userData!.role == 'business_client')
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.s.financeStats,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              ListTile(
                                leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                                title: Text(context.s.paidAmountLabel),
                                subtitle: Text(
                                  context.s.amountTnd(
                                    (userData!.montantPaye > 0
                                            ? userData!.montantPaye
                                            : montantDisponible)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.lock, color: Colors.red),
                                title: Text(context.s.remainingAmountLabel),
                                subtitle: Text(
                                  context.s.amountTnd(
                                    (userData!.montantReste > 0
                                            ? userData!.montantReste
                                            : montantNonDisponible)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                              ),
                              if (montantDisponible > 0) ...[
                                const SizedBox(height: 10),
                                Center(
                                  child: TextButton(
                                    onPressed: _retirerMontant,
                                    child: Text(context.s.withdrawAll),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      userData!.role == 'delivery_person'
                          ? context.s.assignedOrdersDriver
                          : context.s.assignedOrdersClient,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _colisSearch,
                      decoration: InputDecoration(
                        labelText: context.s.searchOrdersHint,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (userData != null) _fetchUserColis(userData!);
                      },
                    ),
                    const SizedBox(height: 8),
                    colis.isEmpty
                        ? EmptyState(message: context.s.noOrders)
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: colis.length,
                            itemBuilder: (context, index) {
                              final commande = colis[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CommandeDetailsScreen(commandeId: commande.id),
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
                  ],
                ),
              ),
            ),
    );
  }
}
