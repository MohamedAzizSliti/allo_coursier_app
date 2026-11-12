import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../services/commande_api_service.dart';
import '../../services/pdf_preview.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parcel_amounts_card.dart';
import '../../widgets/status_chip.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({required this.orderId, super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final CommandeApiService _commandeService = CommandeApiService();

  CommandeModel? _commande;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final commande = await _commandeService.getCommande(widget.orderId);
      if (!mounted) return;
      setState(() {
        _commande = commande;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching order details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: Text(s.orderDetails),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        actions: [
          if (_commande != null)
            IconButton(
              tooltip: s.print,
              icon: const Icon(Icons.print_outlined),
              onPressed: () => showPdfPreview(_commande!),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _commande == null
              ? Center(child: Text(s.orderNotFound))
              : RefreshIndicator(
                  onRefresh: _fetchDetails,
                  color: AppColors.brand,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _HeaderCard(order: _commande!),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: s.client,
                        icon: Icons.person_outline,
                        child: Column(
                          children: [
                            _InfoRow(label: s.name, value: _text(_commande!.clientNom, s)),
                            _InfoRow(label: s.phone, value: _text(_commande!.clientTelephone, s)),
                            _InfoRow(label: s.address, value: _text(_commande!.clientAdresse, s)),
                            _InfoRow(label: s.city, value: _text(_commande!.clientVille, s)),
                            _InfoRow(
                              label: s.governorate,
                              value: _text(_commande!.clientGouvernorat, s),
                              last: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: s.product,
                        icon: Icons.inventory_2_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_commande!.produitList.isEmpty)
                              _InfoRow(
                                label: s.name,
                                value: _text(_commande!.produitNom, s),
                                last: true,
                              )
                            else
                              ..._commande!.produitList.map((p) {
                                final name = (p['name'] ?? '').toString();
                                final qty = p['quantity'] ?? 0;
                                final price = p['pricePerKilo'] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.cream,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.isEmpty ? s.na : name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.espresso,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${s.quantityKg}: $qty  ·  ${s.pricePerKg}: ${s.amountTnd('$price')}',
                                          style: const TextStyle(
                                            color: AppColors.textMedium,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FlagChip(
                                  label: s.fragile,
                                  on: _commande!.produitFragile,
                                ),
                                _FlagChip(
                                  label: s.openBeforePay,
                                  on: _commande!.produitOuvrirAvantPaiement,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ParcelAmountsCard(
                        colisPrice: _commande!.produitPrixTotal,
                        deliveryFee: _commande!.fraisLivraison,
                        showDeliveryFee: false,
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: s.deliveryDate,
                        icon: Icons.event_outlined,
                        child: Column(
                          children: [
                            _InfoRow(
                              label: s.orderDate,
                              value: _commande!.dateTime != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(_commande!.dateTime!)
                                  : s.na,
                            ),
                            _InfoRow(
                              label: s.deliveryDate,
                              value: _commande!.deliveryDateTime != null
                                  ? DateFormat('dd/MM/yyyy').format(_commande!.deliveryDateTime!)
                                  : s.na,
                              last: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _text(String value, AppStrings s) => value.trim().isEmpty ? s.na : value.trim();
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final CommandeModel order;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: WebSurfaces.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.orderTitle(order.displayId),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(status: order.status),
              Chip(
                label: Text(order.paid ? s.paid : s.unpaid),
                backgroundColor: order.paid
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFFF7ED),
                side: BorderSide(
                  color: order.paid ? AppColors.success : AppColors.warning,
                ),
                labelStyle: TextStyle(
                  color: order.paid ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: WebSurfaces.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.brand),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.espresso,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFFFF7ED) : AppColors.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Text(
        '$label: ${on ? context.s.yes : context.s.no}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: on ? AppColors.warning : AppColors.textMedium,
        ),
      ),
    );
  }
}
