import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../services/commande_api_service.dart';
import '../../services/pdf_preview.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.orderDetails),
        backgroundColor: const Color(0xFF6D4C41),
        actions: [
          if (_commande != null)
            IconButton(
              tooltip: context.s.print,
              icon: const Icon(Icons.print_outlined),
              onPressed: () => showPdfPreview(_commande!),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _commande == null
              ? Center(child: Text(context.s.orderNotFound))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context.s.orderTitle(_commande!.displayId)),
                      const Divider(),
                      _buildSectionTitle('${context.s.client} :'),
                      Text("${context.s.name}: ${_commande!.clientNom.isEmpty ? context.s.na : _commande!.clientNom}"),
                      Text("${context.s.address}: ${_commande!.clientAdresse.isEmpty ? context.s.na : _commande!.clientAdresse}"),
                      Text("${context.s.city}: ${_commande!.clientVille.isEmpty ? context.s.na : _commande!.clientVille}"),
                      Text("${context.s.governorate}: ${_commande!.clientGouvernorat.isEmpty ? context.s.na : _commande!.clientGouvernorat}"),
                      Text("${context.s.phone}: ${_commande!.clientTelephone.isEmpty ? context.s.na : _commande!.clientTelephone}"),
                      const SizedBox(height: 10),
                      _buildSectionTitle('${context.s.product} :'),
                      _buildProduitCard(),
                      const SizedBox(height: 10),
                      ParcelAmountsCard(
                        colisPrice: _commande!.produitPrixTotal,
                        deliveryFee: _commande!.fraisLivraison,
                      ),
                      const SizedBox(height: 10),
                      if (_commande!.produitList.isNotEmpty) ...[
                        _buildSectionTitle(context.s.productList),
                        ..._commande!.produitList.map((p) => _buildProduitListCard(p)),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        context.s.dateLabel(_commande!.dateTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(_commande!.dateTime!) : context.s.na),
                      ),
                      Row(
                        children: [
                          StatusChip(status: _commande!.status),
                          const SizedBox(width: 8),
                          Chip(label: Text(_commande!.paid ? context.s.paid : context.s.unpaid)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: QrImageView(
                          data: _commande!.id,
                          size: 180,
                        ),
                      ),
                      Center(child: Text(_commande!.displayId)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildProduitCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${context.s.name}: ${_commande!.produitNom}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(context.s.totalPrice('${_commande!.produitPrixTotal}')),
            Text("${context.s.fragile}: ${_commande!.produitFragile ? context.s.yes : context.s.no}"),
            Text("${context.s.openBeforePay}: ${_commande!.produitOuvrirAvantPaiement ? context.s.yes : context.s.no}"),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitListCard(Map<String, dynamic> produit) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${context.s.name}: ${produit['name'] ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("${context.s.pricePerKg}: ${context.s.amountTnd('${produit['pricePerKilo'] ?? 0}')}"),
            Text("${context.s.quantityKg}: ${produit['quantity'] ?? 0}"),
          ],
        ),
      ),
    );
  }
}
