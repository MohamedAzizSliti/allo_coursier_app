import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/onboarding_controller.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_canvas.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  List<_Slide> _slides(AppStrings s) => [
        _Slide(Icons.inventory_2_outlined, s.onboardingTitle1, s.onboardingBody1),
        _Slide(Icons.local_shipping_outlined, s.onboardingTitle2, s.onboardingBody2),
        _Slide(Icons.account_balance_wallet_outlined, s.onboardingTitle3, s.onboardingBody3),
      ];

  Future<void> _finish() => OnboardingController.instance.completeOnboarding();

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final slides = _slides(s);
    final last = _index == slides.length - 1;

    return AuthCanvas(
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _finish,
              child: Text(s.onboardingSkip),
            ),
          ),
          SizedBox(
            height: 420,
            child: PageView.builder(
              controller: _page,
              itemCount: slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, i) {
                final slide = slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                        child: Icon(slide.icon, size: 44, color: AppColors.brand),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                Container(
                  width: i == _index ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.brand : AppColors.tan,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                if (last) {
                  _finish();
                  return;
                }
                _page.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                );
              },
              child: Text(last ? s.onboardingStart : s.onboardingNext),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}
