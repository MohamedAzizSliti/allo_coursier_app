import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class PasswordUpdateFields extends StatelessWidget {
  const PasswordUpdateFields({
    super.key,
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleConfirm,
    this.optional = false,
  });

  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureConfirm;
  final VoidCallback onToggleCurrent;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final bool optional;

  bool get _anyFilled {
    return currentController.text.trim().isNotEmpty ||
        newController.text.trim().isNotEmpty ||
        confirmController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        _field(
          controller: currentController,
          label: s.currentPassword,
          obscure: obscureCurrent,
          onToggle: onToggleCurrent,
          validator: (value) {
            if (optional && !_anyFilled) return null;
            if (value == null || value.isEmpty) return s.enterCurrentPassword;
            return null;
          },
        ),
        const SizedBox(height: 12),
        _field(
          controller: newController,
          label: s.newPassword,
          obscure: obscureNew,
          onToggle: onToggleNew,
          validator: (value) {
            if (optional && !_anyFilled) return null;
            if (value == null || value.length < 6) return s.passwordTooShort;
            if (value == currentController.text) return s.passwordSameAsCurrent;
            return null;
          },
        ),
        const SizedBox(height: 12),
        _field(
          controller: confirmController,
          label: s.confirmNewPassword,
          obscure: obscureConfirm,
          onToggle: onToggleConfirm,
          validator: (value) {
            if (optional && !_anyFilled) return null;
            if (value != newController.text) return s.passwordsDoNotMatch;
            return null;
          },
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
          ),
        ),
      ),
      validator: validator,
    );
  }
}
