import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_canvas.dart';

class LanguageWelcomeScreen extends StatelessWidget {
  const LanguageWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthCanvas(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 120,
            height: 120,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.local_shipping,
              size: 72,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Allo Coursier',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اختر لغتك  ·  Choisissez votre langue',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMedium),
          ),
          const SizedBox(height: 28),
          _LangButton(
            label: 'العربية',
            onTap: () => LocaleController.instance.setArabic(true),
          ),
          const SizedBox(height: 12),
          _LangButton(
            label: 'Français',
            onTap: () => LocaleController.instance.setArabic(false),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
