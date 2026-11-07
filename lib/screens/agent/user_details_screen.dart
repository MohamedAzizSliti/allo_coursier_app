import 'package:flutter/material.dart';

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

  UserModel? userData;
  List<CommandeModel> commandesList = [];
  double montantDisponible = 0.0;
  double montantNonDisponible = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  String? _error;

  Future<void> _fetchUserDetails() async {
    try {
      final user = await _userService.getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        userData = user;
        _error = null;
      });
      if (user.role == 'business_client') {
        _fetchUserColis(user.id);
      }
    } catch (e) {
      if (mounted) setState(() => _error = context.s.cannotLoadUser);
    }
  }

  Future<void> _fetchUserColis(String userId) async {
    try {
      final page = await _commandeService.listCommandesForUserPage(userId);
      final held = await _commandeService.unpaidDeliveredTotalForUser(userId);
      if (!mounted) return;

      setState(() {
        commandesList = page.rows;
        montantDisponible = userData?.montantDisponible ?? 0.0;
        montantNonDisponible = held;
      });
    } catch (e) {
      debugPrint('Error fetching colis: $e');
    }
  }

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
        SnackBar(
          content: Text(
            e.message,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.withdrawError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.s.userDetails)),
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
                                title: Text(context.s.availableAmount),
                                subtitle: Text(context.s.amountTnd(montantDisponible.toStringAsFixed(2))),
                              ),
                              ListTile(
                                leading: const Icon(Icons.lock, color: Colors.red),
                                title: Text(context.s.unavailableAmount),
                                subtitle: Text(context.s.amountTnd(montantNonDisponible.toStringAsFixed(2))),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _retirerMontant,
                                  child: Text(context.s.withdrawAll),
                                ),
                              ),
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
                    commandesList.isEmpty
                        ? EmptyState(message: context.s.noOrders)
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                  ],
                ),
              ),
            ),
    );
  }
}
