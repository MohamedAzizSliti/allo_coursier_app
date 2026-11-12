import 'package:flutter/material.dart';

import '../../../domain/delivery_schedule.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';

class WeeklyPlanWidget extends StatefulWidget {
  const WeeklyPlanWidget({super.key});

  @override
  State<WeeklyPlanWidget> createState() => _WeeklyPlanWidgetState();
}

class _WeeklyPlanWidgetState extends State<WeeklyPlanWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: WebSurfaces.card(radius: 24),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.s.weeklyPlan,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textMedium,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: kWeeklyDeliveryPlan
                    .map(
                      (dayPlan) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: AppColors.brand,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weekdayLabelAr(dayPlan.weekday),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.espresso,
                                    ),
                                  ),
                                  Text(
                                    gouvernoratsLabelAr(dayPlan.gouvernorats),
                                    style: const TextStyle(
                                      color: AppColors.textMedium,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
          ],
        ),
      ),
    );
  }
}
