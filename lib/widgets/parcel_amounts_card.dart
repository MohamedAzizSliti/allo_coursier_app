import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

class ParcelAmountsCard extends StatelessWidget {
  const ParcelAmountsCard({
    super.key,
    required this.colisPrice,
    required this.deliveryFee,
  });

  final double colisPrice;
  final double deliveryFee;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: WebSurfaces.card(radius: 16),
      child: ParcelAmountLines(
        colisPrice: colisPrice,
        deliveryFee: deliveryFee,
      ),
    );
  }
}

class ParcelAmountLines extends StatelessWidget {
  const ParcelAmountLines({
    super.key,
    required this.colisPrice,
    required this.deliveryFee,
    this.dense = false,
  });

  final double colisPrice;
  final double deliveryFee;
  final bool dense;

  double get total => colisPrice + deliveryFee;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final gap = dense ? 2.0 : 8.0;
    return Column(
      children: [
        _AmountRow(
          label: s.colisPrice,
          amount: s.amountTnd(colisPrice.toStringAsFixed(2)),
          dense: dense,
        ),
        SizedBox(height: gap),
        _AmountRow(
          label: s.deliveryFees,
          amount: s.amountTnd(deliveryFee.toStringAsFixed(2)),
          dense: dense,
        ),
        if (!dense)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          )
        else
          SizedBox(height: gap),
        _AmountRow(
          label: s.total,
          amount: s.amountTnd(total.toStringAsFixed(2)),
          emphasize: true,
          dense: dense,
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
    this.dense = false,
  });

  final String label;
  final String amount;
  final bool emphasize;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final size = dense ? (emphasize ? 13.0 : 12.0) : (emphasize ? 16.0 : 14.0);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              color: AppColors.espresso,
              fontSize: size,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: emphasize ? AppColors.brand : AppColors.espresso,
            fontSize: size,
          ),
        ),
      ],
    );
  }
}
