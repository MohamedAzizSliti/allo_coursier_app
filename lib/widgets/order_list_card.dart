import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/commande_model.dart';
import '../theme/app_theme.dart';
import 'parcel_amounts_card.dart';
import 'status_chip.dart';

class OrderListCard extends StatelessWidget {
  const OrderListCard({
    super.key,
    required this.commande,
    required this.onView,
    this.onPrint,
    this.showDeliveryFee = true,
  });

  final CommandeModel commande;
  final VoidCallback onView;
  final VoidCallback? onPrint;

  /// Expéditeur money view: prix colis only (no frais de livraison).
  final bool showDeliveryFee;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateStr = commande.dateTime != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(commande.dateTime!)
        : s.na;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: WebSurfaces.card(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.orderTitle(commande.displayId),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.clientName(commande.clientNom)),
                Text(
                  s.dateLabel(dateStr),
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ParcelAmountLines(
                  colisPrice: commande.produitPrixTotal,
                  deliveryFee: commande.fraisLivraison,
                  dense: true,
                  showDeliveryFee: showDeliveryFee,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusChip(status: commande.status),
                    Chip(
                      label: Text(commande.paid ? s.paid : s.unpaid),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: commande.paid
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                      ),
                      backgroundColor: commande.paid
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.view,
            onPressed: onView,
            icon: const Icon(Icons.visibility_outlined, color: AppColors.updateBlue),
          ),
          if (onPrint != null)
            IconButton(
              tooltip: s.print,
              onPressed: onPrint,
              icon: const Icon(Icons.print_outlined, color: AppColors.brand),
            ),
        ],
      ),
    );
  }
}
