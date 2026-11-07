import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/user_model.dart';
import '../../services/auth_api_service.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_controller.dart';
import '../../services/session_controller.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/password_update_fields.dart';
import '../business_client/add_order_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _company = TextEditingController();
  final _cin = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  UserModel? _user;
  String? _gouvernorat;
  bool _loading = true;
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _company.dispose();
    _cin.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await OnboardingController.instance.overlay(
        await AuthApiService().getCurrentUser(),
      );
      if (!mounted) return;
      _phone.text = user.phone ?? '';
      _address.text = user.address ?? '';
      _city.text = user.city ?? '';
      _company.text = user.company ?? '';
      _cin.text = user.cin ?? '';
      final allowed = kTunisianGovernorates.map((g) => g.apiValue).toSet();
      setState(() {
        _user = user;
        _gouvernorat =
            allowed.contains(user.gouvernorat) ? user.gouvernorat : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.s.cannotLoadProfile;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    setState(() => _saving = true);
    final filled = _user!.copyWith(
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      gouvernorat: _gouvernorat,
      company: _company.text.trim(),
      cin: _cin.text.trim(),
    );
    try {
      await OnboardingController.instance.saveOverlay(filled);
      SessionController.instance.rememberProfile(filled);
      try {
        await UserApiService().updateProfile(filled);
      } catch (_) {
        // Overlay already saved; phone/address persist when PATCH is reachable.
      }
      final current = _currentPassword.text.trim();
      final next = _newPassword.text.trim();
      if (current.isNotEmpty || next.isNotEmpty) {
        try {
          final signInAgain = await AuthApiService().changePassword(current, next);
          if (signInAgain) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.s.signInAgain)),
            );
            await SessionController.instance.signedOut();
            return;
          }
          await SessionController.instance.clearMustChangePassword();
        } on AlloException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
          return;
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.s.passwordUpdateFailed)),
          );
          return;
        }
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final canPop = Navigator.of(context).canPop();
      messenger.showSnackBar(
        SnackBar(content: Text(context.s.profileSaved)),
      );
      await SessionController.instance.markProfileComplete();
      if (canPop && context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      SessionController.instance.rememberProfile(filled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.profileSavedLocally)),
      );
      await SessionController.instance.markProfileComplete();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.completeProfileTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        s.completeProfileSubtitle,
                        style: const TextStyle(color: AppColors.textMedium),
                      ),
                      const SizedBox(height: 8),
                      if (_user != null) ...[
                        Text(_user!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        Text(_user!.email, style: const TextStyle(color: AppColors.textMedium)),
                      ],
                      const SizedBox(height: 16),
                      _field(_phone, s.phone, Icons.phone_outlined, requiredField: true, phone: true),
                      _field(_address, s.address, Icons.home_outlined, requiredField: true),
                      _field(_city, s.city, Icons.location_city_outlined, requiredField: true),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_gouvernorat),
                        isExpanded: true,
                        initialValue: _gouvernorat,
                        decoration: InputDecoration(
                          labelText: s.governorate,
                          prefixIcon: const Icon(Icons.map_outlined),
                        ),
                        items: kTunisianGovernorates
                            .map(
                              (gov) => DropdownMenuItem(
                                value: gov.apiValue,
                                child: Text(gov.label(s.ar)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _gouvernorat = value),
                        validator: (value) => value == null ? s.requiredField : null,
                      ),
                      const SizedBox(height: 12),
                      _field(_company, s.company, Icons.storefront_outlined),
                      _field(_cin, s.cin, Icons.badge_outlined),
                      const SizedBox(height: 8),
                      Text(
                        s.changePassword,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.changePasswordHint,
                        style: const TextStyle(color: AppColors.textMedium),
                      ),
                      const SizedBox(height: 12),
                      PasswordUpdateFields(
                        currentController: _currentPassword,
                        newController: _newPassword,
                        confirmController: _confirmPassword,
                        obscureCurrent: _obscureCurrent,
                        obscureNew: _obscureNew,
                        obscureConfirm: _obscureConfirm,
                        onToggleCurrent: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                        onToggleNew: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        onToggleConfirm: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        optional: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(s.saveProfile),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool requiredField = false,
    bool phone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (value) {
          if (!requiredField) return null;
          return value == null || value.trim().isEmpty ? context.s.requiredField : null;
        },
      ),
    );
  }
}
