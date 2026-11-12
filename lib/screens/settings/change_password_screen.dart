import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import '../../services/auth_api_service.dart';
import '../../services/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/password_update_fields.dart';
import '../auth/auth_canvas.dart';

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

  Future<void> _saveContact({bool skip = false}) async {
    final phone = skip ? '' : _phoneController.text.trim();
    final email = skip ? '' : _emailController.text.trim();
    if (phone.isNotEmpty && !_validPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.invalidPhone)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (phone.isNotEmpty || email.isNotEmpty) {
        await _authService.updateContact(phone: phone, email: email);
      }
      if (!mounted) return;
      await _leaveAfterContact();
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

  Future<void> _leaveAfterContact() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (widget.requiredChange) {
      return PopScope(canPop: false, child: _firstLogin(s));
    }
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.beige,
        appBar: AppBar(
          backgroundColor: AppColors.beige,
          foregroundColor: AppColors.espresso,
          elevation: 0,
          title: Text(
            s.changePassword,
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
              child: Form(
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
                      onToggleNew: () => setState(() => _obscureNew = !_obscureNew),
                      onToggleConfirm: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 20),
                    _PrimaryButton(
                      busy: _saving,
                      label: s.update,
                      onPressed: _save,
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

  Widget _firstLogin(AppStrings s) {
    final step = _contactStep ? 1 : 0;
    return AuthCanvas(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Image.asset(
            'assets/images/logo.png',
            width: 88,
            height: 88,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.local_shipping,
              size: 64,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 18),
          _StepRail(
            index: step,
            first: s.passwordStep,
            second: s.contactStep,
          ),
          const SizedBox(height: 18),
          AuthCard(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: step == 0
                ? KeyedSubtree(key: const ValueKey('password'), child: _passwordStep(s))
                : _contactStepView(s),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : () => SessionController.instance.signedOut(),
            child: Text(s.logout),
          ),
        ],
      ),
    );
  }

  Widget _passwordStep(AppStrings s) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.choosePasswordTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.choosePasswordBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMedium, height: 1.35),
          ),
          const SizedBox(height: 20),
          PasswordUpdateFields(
            currentController: _currentPasswordController,
            newController: _newPasswordController,
            confirmController: _confirmPasswordController,
            obscureCurrent: _obscureCurrent,
            obscureNew: _obscureNew,
            obscureConfirm: _obscureConfirm,
            onToggleCurrent: () => setState(() => _obscureCurrent = !_obscureCurrent),
            onToggleNew: () => setState(() => _obscureNew = !_obscureNew),
            onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(busy: _saving, label: s.savePassword, onPressed: _save),
        ],
      ),
    );
  }

  Widget _contactStepView(AppStrings s) {
    return Column(
      key: const ValueKey('contact'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.contactStepTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.contactStepBody,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMedium, height: 1.35),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: s.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: s.email,
            prefixIcon: const Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          busy: _saving,
          label: s.update,
          onPressed: () => _saveContact(),
        ),
        TextButton(
          onPressed: _saving ? null : () => _saveContact(skip: true),
          child: Text(s.continueWithoutDetails),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.tan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({
    required this.index,
    required this.first,
    required this.second,
  });

  final int index;
  final String first;
  final String second;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepNode(number: 1, label: first, active: index == 0, done: index > 0),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 17),
            child: Container(
              height: 2,
              color: index > 0 ? AppColors.brand : AppColors.border,
            ),
          ),
        ),
        _StepNode(number: 2, label: second, active: index == 1, done: false),
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });

  final int number;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final filled = active || done;
    return SizedBox(
      width: 108,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? AppColors.brand : AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(color: filled ? AppColors.brand : AppColors.border, width: 2),
            ),
            child: done
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: filled ? Colors.white : AppColors.espresso,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppColors.brand : AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
