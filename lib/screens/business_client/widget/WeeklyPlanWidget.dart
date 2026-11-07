import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';

class WeeklyPlanWidget extends StatefulWidget {
  @override
  _WeeklyPlanWidgetState createState() => _WeeklyPlanWidgetState();
}

class _WeeklyPlanWidgetState extends State<WeeklyPlanWidget> {
  bool isExpanded = false;

  final List<Map<String, String>> weeklyPlan = [
    {
      'day': 'الاثنين',
      'locations': 'القصرين، سيدي بوزيد، تونس، صفاقس، قيروان، قفصة',
    },
    {'day': 'الثلاثاء', 'locations': 'تونس، الوطن القبلي'},
    {'day': 'الأربعاء', 'locations': 'قفصة، توزر، قبلي، تونس، باجة، سليانة'},
    {'day': 'الخميس', 'locations': 'تونس، سوسة، منستير'},
    {'day': 'الجمعة', 'locations': 'تونس، مهدية، قيروان، قابس، تطاوين، مدنين'},
    {'day': 'السبت', 'locations': 'تونس، بنزرت'},
  ];

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
                children: weeklyPlan
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
                                    dayPlan['day']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.espresso,
                                    ),
                                  ),
                                  Text(
                                    dayPlan['locations']!,
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
