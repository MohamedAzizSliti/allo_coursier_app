import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/vehicle_model.dart';
import '../theme/app_theme.dart';

class VehiclePickerSheet extends StatelessWidget {
  const VehiclePickerSheet({
    super.key,
    required this.vehicles,
    this.selectedId,
  });

  final List<VehicleModel> vehicles;
  final String? selectedId;

  static Future<VehicleModel?> show(
    BuildContext context, {
    required List<VehicleModel> vehicles,
    String? selectedId,
  }) {
    return showModalBottomSheet<VehicleModel>(
      context: context,
      showDragHandle: true,
      builder: (_) => VehiclePickerSheet(
        vehicles: vehicles,
        selectedId: selectedId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (vehicles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(s.noVehicles),
      );
    }
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              s.selectVehicle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.espresso,
              ),
            ),
          ),
          for (final vehicle in vehicles)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.avatarFill,
                child: Icon(Icons.local_shipping, color: AppColors.espresso),
              ),
              title: Text(vehicle.displayName),
              trailing: vehicle.id == selectedId
                  ? const Icon(Icons.check, color: AppColors.success)
                  : null,
              onTap: () => Navigator.pop(context, vehicle),
            ),
        ],
      ),
    );
  }
}
