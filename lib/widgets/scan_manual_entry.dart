import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

class ScanManualEntry extends StatefulWidget {
  const ScanManualEntry({
    super.key,
    required this.enabled,
    required this.onSubmit,
  });

  final bool enabled;
  final ValueChanged<String> onSubmit;

  @override
  State<ScanManualEntry> createState() => _ScanManualEntryState();
}

class _ScanManualEntryState extends State<ScanManualEntry> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (!widget.enabled || code.isEmpty) return;
    widget.onSubmit(code);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.enterOrderNumber,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9HTht]')),
                ],
                decoration: InputDecoration(
                  hintText: s.orderNumberHint,
                  prefixIcon: const Icon(Icons.keyboard_alt_outlined),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: widget.enabled ? _submit : null,
              child: Text(s.validate),
            ),
          ],
        ),
      ],
    );
  }
}
