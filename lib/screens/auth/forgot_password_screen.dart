import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/office_contact.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_toggle.dart';
import 'auth_canvas.dart';
import 'forgot_password_messages.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
    this.sender,
  });

  final String? initialEmail;
  final PasswordReclamationSender? sender;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final reclamation = PasswordReclamation(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        note: _noteController.text.trim(),
      );
      final send = widget.sender ?? sendPasswordReclamationToOffice;
      await send(reclamation);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.s.cannotSendReclamation} ${OfficeContact.phoneDisplay}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AuthCanvas(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.brand),
                ),
                const Spacer(),
                const LanguageToggle(),
              ],
            ),
            AuthCard(
              child: Column(
                children: [
            const Icon(Icons.lock_reset, size: 56, color: AppColors.brand),
            const SizedBox(height: 16),
            Text(
              s.forgotTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.forgotHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 32),
            if (_sent) ...[
              const Icon(Icons.check_circle, color: AppColors.success, size: 48),
              const SizedBox(height: 12),
              Text(
                s.reclamationSent,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.bureauWillContact,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMedium),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(s.backToLogin),
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: s.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: validateForgotEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: s.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: validateForgotPhone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: s.optionalMessage,
                  prefixIcon: const Icon(Icons.chat_bubble_outline),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          s.sendReclamation,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.bureauLine(OfficeContact.phoneDisplay),
                style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
              ),
            ],
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Future<void> sendPasswordReclamationToOffice(
  PasswordReclamation reclamation,
) async {
  final uri = buildPasswordReclamationMailto(
    email: reclamation.email,
    phone: reclamation.phone,
    note: reclamation.note,
  );
  final launched = await launchUrl(uri);
  if (!launched) {
    throw Exception('mailto_failed');
  }
}
