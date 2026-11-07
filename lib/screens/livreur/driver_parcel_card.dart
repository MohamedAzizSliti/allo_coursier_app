import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/commande_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parcel_amounts_card.dart';
import '../../widgets/status_chip.dart';

class DriverParcelCard extends StatelessWidget {
  const DriverParcelCard({
    super.key,
    required this.commande,
    required this.onOpen,
  });

  final CommandeModel commande;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final destination = [
      if (commande.clientNom.trim().isNotEmpty) commande.clientNom.trim(),
      if (commande.clientVille.trim().isNotEmpty) commande.clientVille.trim(),
    ].join(' · ');
    final deliveryDate = commande.deliveryDateTime != null
        ? DateFormat('dd/MM/yyyy').format(commande.deliveryDateTime!)
        : s.na;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: WebSurfaces.card(radius: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.brand,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commande.displayId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.espresso,
                          fontSize: 16,
                        ),
                      ),
                      if (destination.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          destination,
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (commande.produitNom.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          commande.produitNom,
                          style: const TextStyle(color: AppColors.textMedium),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ParcelAmountLines(
                        colisPrice: commande.produitPrixTotal,
                        deliveryFee: commande.fraisLivraison,
                        dense: true,
                      ),
                      const SizedBox(height: 8),
                      StatusChip(status: commande.status),
                      const SizedBox(height: 4),
                      Text(
                        s.deliveryDateLine(deliveryDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
