import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class LivreurPickerSheet extends StatelessWidget {
  const LivreurPickerSheet({
    super.key,
    required this.drivers,
    this.selectedId,
  });

  final List<UserModel> drivers;
  final String? selectedId;

  static Future<UserModel?> show(
    BuildContext context, {
    required List<UserModel> drivers,
    String? selectedId,
  }) {
    return showModalBottomSheet<UserModel>(
      context: context,
      showDragHandle: true,
      builder: (_) => LivreurPickerSheet(
        drivers: drivers,
        selectedId: selectedId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (drivers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(s.noDriversFound),
      );
    }
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              s.selectDriver,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.espresso,
              ),
            ),
          ),
          for (final driver in drivers)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.avatarFill,
                child: const Icon(Icons.delivery_dining, color: AppColors.espresso),
              ),
              title: Text(driver.name),
              subtitle: Text(
                driver.phone?.trim().isNotEmpty == true
                    ? driver.phone!
                    : (driver.email.isNotEmpty ? driver.email : s.noDriver),
              ),
              trailing: driver.id == selectedId
                  ? const Icon(Icons.check, color: AppColors.success)
                  : null,
              onTap: () => Navigator.pop(context, driver),
            ),
        ],
      ),
    );
  }
}
