import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import '../../services/auth_api_service.dart';
import '../../services/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/password_update_fields.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.requiredChange = false});

  final bool requiredChange;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _authService = AuthApiService();

  bool _saving = false;
  bool _contactStep = false;
  bool _signInAgain = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _validPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final national = digits.replaceFirst(RegExp(r'^(00216|216)(?=\d{8}$)'), '');
    return RegExp(r'^[2-9][0-9]{7}$').hasMatch(national);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final signInAgain = await _authService.changePassword(
        _currentPasswordController.text.trim(),
        _newPasswordController.text.trim(),
      );
      if (!mounted) return;
      if (widget.requiredChange) {
        setState(() {
          _signInAgain = signInAgain;
          _contactStep = true;
        });
        return;
      }
      if (signInAgain) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.signInAgain)),
        );
        await SessionController.instance.signedOut();
        return;
      }
      await SessionController.instance.clearMustChangePassword();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.passwordUpdated)),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AlloException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.passwordUpdateFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveContact() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    if (phone.isNotEmpty && !_validPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.invalidPhone)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _authService.updateContact(phone: phone, email: email);
      if (!mounted) return;
      if (_signInAgain) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.signInAgain)),
        );
        await SessionController.instance.signedOut();
        return;
      }
      await SessionController.instance.clearMustChangePassword();
      if (!mounted) return;
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    } on AlloException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.passwordUpdateFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PopScope(
      canPop: !widget.requiredChange,
      child: Scaffold(
        backgroundColor: AppColors.beige,
        appBar: AppBar(
          backgroundColor: AppColors.beige,
          foregroundColor: AppColors.espresso,
          elevation: 0,
          automaticallyImplyLeading: !widget.requiredChange,
          title: Text(
            _contactStep
                ? s.phone
                : (widget.requiredChange ? s.mustChangePasswordTitle : s.changePassword),
            style: const TextStyle(
              color: AppColors.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.espresso),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: WebSurfaces.card(radius: 24),
              child: _contactStep
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(s.contactAfterPassword),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: s.phone),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(labelText: s.email),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _saving ? null : _saveContact,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brand,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(s.update),
                          ),
                        ),
                      ],
                    )
                  : Form(
                key: _formKey,
                child: Column(
                  children: [
                    PasswordUpdateFields(
                      currentController: _currentPasswordController,
                      newController: _newPasswordController,
                      confirmController: _confirmPasswordController,
                      obscureCurrent: _obscureCurrent,
                      obscureNew: _obscureNew,
                      obscureConfirm: _obscureConfirm,
                      onToggleCurrent: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      onToggleNew: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      onToggleConfirm: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(s.update),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
