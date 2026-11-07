import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

/// Confirm sheet shown after a successful scanner lookup, before any mutation.
class ScanConfirmDialog extends StatelessWidget {
  const ScanConfirmDialog({
    super.key,
    required this.displayId,
    required this.status,
    required this.message,
    this.confirmLabel,
  });

  final String displayId;
  final String status;
  final String message;
  final String? confirmLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.parcelTitle(displayId),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 12),
            Center(child: StatusChip(status: status)),
            const SizedBox(height: 8),
            Text(
              '${s.currentStatusColon} ${statusLabel(status, s)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMedium),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(confirmLabel ?? s.confirm),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
