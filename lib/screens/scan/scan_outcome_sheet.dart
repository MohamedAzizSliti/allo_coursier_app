import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';

class ScanOutcome {
  const ScanOutcome({required this.action, this.reason = ''});

  final String action;
  final String reason;
}

/// Modern delivery-result sheet after a driver scans an En route colis.
class ScanOutcomeSheet extends StatefulWidget {
  const ScanOutcomeSheet({
    super.key,
    required this.displayId,
    this.status,
  });

  final String displayId;
  final String? status;

  static Future<ScanOutcome?> show(
    BuildContext context, {
    required String displayId,
    String? status,
  }) {
    return showModalBottomSheet<ScanOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanOutcomeSheet(
        displayId: displayId,
        status: status,
      ),
    );
  }

  @override
  State<ScanOutcomeSheet> createState() => _ScanOutcomeSheetState();
}

class _ScanOutcomeSheetState extends State<ScanOutcomeSheet> {
  final _reason = TextEditingController();
  String? _selected;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _needsReason =>
      _selected == 'Relivrer' || _selected == 'Annuler';

  void _confirm() {
    final action = _selected;
    if (action == null) return;
    final reason = _reason.text.trim();
    if (_needsReason && reason.isEmpty) {
      setState(() => _error = context.s.enterReason);
      return;
    }
    Navigator.pop(
      context,
      ScanOutcome(action: action, reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.parcelTitle(widget.displayId),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.status != null) ...[
                  const SizedBox(height: 10),
                  Center(child: StatusChip(status: widget.status!)),
                ],
                const SizedBox(height: 8),
                Text(
                  s.chooseOutcome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _OutcomeTile(
                  label: s.delivered,
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  selected: _selected == 'Livrer',
                  onTap: () => setState(() {
                    _selected = 'Livrer';
                    _error = null;
                  }),
                ),
                const SizedBox(height: 10),
                _OutcomeTile(
                  label: s.redeliver,
                  icon: Icons.replay_outlined,
                  color: AppColors.warning,
                  selected: _selected == 'Relivrer',
                  onTap: () => setState(() {
                    _selected = 'Relivrer';
                    _error = null;
                  }),
                ),
                const SizedBox(height: 10),
                _OutcomeTile(
                  label: s.cancelled,
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                  selected: _selected == 'Annuler',
                  onTap: () => setState(() {
                    _selected = 'Annuler';
                    _error = null;
                  }),
                ),
                if (_needsReason) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reason,
                    maxLines: 2,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      labelText: s.reasonRequired,
                      errorText: _error,
                    ),
                  ),
                ] else if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _selected == null ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.espresso,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.espresso.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(s.confirm),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : AppColors.espresso,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: color)
              else
                Icon(Icons.circle_outlined, color: AppColors.border),
            ],
          ),
        ),
      ),
    );
  }
}
