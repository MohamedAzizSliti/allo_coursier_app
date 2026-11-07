import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.compact = false, this.color});

  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final locale = LocaleController.instance;
        if (compact) {
          return IconButton(
            tooltip: locale.s.language,
            onPressed: () => locale.setArabic(!locale.isArabic),
            icon: Text(
              locale.isArabic ? 'FR' : 'ع',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color ?? Colors.white,
              ),
            ),
          );
        }
        return SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(locale.s.arabic)),
            ButtonSegment(value: false, label: Text(locale.s.french)),
          ],
          selected: {locale.isArabic},
          onSelectionChanged: (value) => locale.setArabic(value.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return AppColors.brand;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.brand;
              }
              return AppColors.cream;
            }),
          ),
        );
      },
    );
  }
}
