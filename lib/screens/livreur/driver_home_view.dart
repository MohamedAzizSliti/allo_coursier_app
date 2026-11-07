import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({
    super.key,
    required this.name,
    required this.dateLabel,
    required this.total,
    required this.inRoute,
    required this.delivered,
    required this.cancelled,
    required this.redeliver,
    required this.earnings,
    required this.onOpenStatus,
    required this.onScan,
  });

  final String name;
  final String dateLabel;
  final int total;
  final int inRoute;
  final int delivered;
  final int cancelled;
  final int redeliver;
  final double earnings;
  final ValueChanged<String> onOpenStatus;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DriverHero(
          dateLabel: dateLabel,
          greeting: s.helloName(name),
          role: s.roleDriver,
          total: total,
          inRoute: inRoute,
          delivered: delivered,
          onOpenInRoute: () => onOpenStatus('En route'),
          onOpenDelivered: () => onOpenStatus('Livrer'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            label: Text(s.scanQr),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.scanToUpdate,
          style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Text(
          s.assignedParcels,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusCard(
                label: s.inRoute,
                count: inRoute,
                color: AppColors.info,
                icon: Icons.local_shipping_outlined,
                onTap: () => onOpenStatus('En route'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusCard(
                label: s.delivered,
                count: delivered,
                color: AppColors.success,
                icon: Icons.check_circle_outline,
                onTap: () => onOpenStatus('Livrer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusCard(
                label: s.redeliver,
                count: redeliver,
                color: AppColors.warning,
                icon: Icons.replay_outlined,
                onTap: () => onOpenStatus('Relivrer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusCard(
                label: s.cancelled,
                count: cancelled,
                color: AppColors.error,
                icon: Icons.cancel_outlined,
                onTap: () => onOpenStatus('Annuler'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: WebSurfaces.card(radius: 24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.totalRevenue,
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.amountTnd(earnings.toStringAsFixed(2)),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.espresso,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverHero extends StatelessWidget {
  const _DriverHero({
    required this.dateLabel,
    required this.greeting,
    required this.role,
    required this.total,
    required this.inRoute,
    required this.delivered,
    required this.onOpenInRoute,
    required this.onOpenDelivered,
  });

  final String dateLabel;
  final String greeting;
  final String role;
  final int total;
  final int inRoute;
  final int delivered;
  final VoidCallback onOpenInRoute;
  final VoidCallback onOpenDelivered;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Material(
      color: AppColors.espresso,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              greeting,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            Text(
              s.parcelsTotal,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.12)),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric(s.inRoute, '$inRoute', onTap: onOpenInRoute),
                _metric(s.delivered, '$delivered', onTap: onOpenDelivered),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, {required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: WebSurfaces.card(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 14),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
