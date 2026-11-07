import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';

class VehicleDropdown extends StatelessWidget {
  const VehicleDropdown({
    super.key,
    required this.vehicles,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final List<VehicleModel> vehicles;
  final String? value;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      hint: Text(hint, overflow: TextOverflow.ellipsis),
      onChanged: onChanged,
      items: vehicles
          .map(
            (v) => DropdownMenuItem(
              value: v.id,
              child: Text(
                v.displayName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
    );
  }
}
