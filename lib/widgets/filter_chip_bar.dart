import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final String Function(String value) labelOf;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = values[index];
          final active = value == selected;
          return FilterChip(
            label: Text(labelOf(value)),
            selected: active,
            showCheckmark: false,
            selectedColor: AppColors.brand,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.cream,
            side: const BorderSide(color: AppColors.border),
            onSelected: (_) => onSelected(value),
          );
        },
      ),
    );
  }
}
