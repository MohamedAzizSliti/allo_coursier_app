import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../services/session_controller.dart';
import '../theme/app_theme.dart';
import 'business_client/add_order_screen.dart' show governorateLabel;
import 'onboarding/complete_profile_screen.dart';
import '../widgets/error_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthApiService _authService = AuthApiService();

  UserModel? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = SessionController.instance.user;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (!mounted) return;
      SessionController.instance.rememberUser(user);
      setState(() {
        _user = user;
        _error = null;
      });

    } on AlloException catch (_) {
      if (!mounted) return;
      if (_user == null) {
        setState(() => _error = context.s.cannotLoadProfile);
      }
    }
  }

  Future<void> _editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
    );
    if (mounted) {
      setState(() => _user = SessionController.instance.user ?? _user);
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: AppColors.beige,
        foregroundColor: AppColors.espresso,
        elevation: 0,
        title: Text(
          s.profile,
          style: const TextStyle(
            color: AppColors.espresso,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.espresso),
      ),
      body: _error != null && _user == null
          ? ErrorBanner(message: _error!, onRetry: _loadUserData)
          : _user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: AppColors.brand,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ProfileOverview(
                    user: _user!,
                    onEdit: _user!.role == 'business_client' ? _editProfile : null,
                  ),
                  if (_user!.role == 'business_client') ...[
                    const SizedBox(height: 16),
                    ProfileFinanceCard(
                      available: _user!.montantPaye,
                      unavailable: _user!.montantReste,
                      availableLabel: context.s.paidAmountLabel,
                      unavailableLabel: context.s.remainingAmountLabel,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class ProfileOverview extends StatelessWidget {
  const ProfileOverview({
    super.key,
    required this.user,
    this.onEdit,
  });

  final UserModel user;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final name = _displayName(user, s);
    final email = user.email.trim();
    final gov = governorateLabel(user.gouvernorat, s.ar);

    return Column(
      children: [
        _IdentityHeader(
          name: name,
          email: email,
          role: s.roleSingular(user.role),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: WebSurfaces.card(radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.personalInfo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: s.phone,
                value: user.phone,
              ),
              _InfoRow(
                icon: Icons.place_outlined,
                label: s.address,
                value: user.address,
              ),
              _InfoRow(
                icon: Icons.location_city_outlined,
                label: s.city,
                value: user.city,
              ),
              _InfoRow(
                icon: Icons.map_outlined,
                label: s.governorate,
                value: gov.isEmpty ? user.gouvernorat : gov,
              ),
              _InfoRow(
                icon: Icons.storefront_outlined,
                label: s.company,
                value: user.company,
              ),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: s.cin,
                value: user.cin,
              ),
              if (onEdit != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(s.editProfile),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _displayName(UserModel user, AppStrings s) {
    if (user.name.trim().isNotEmpty) return user.name.trim();
    if (user.company != null && user.company!.trim().isNotEmpty) {
      return user.company!.trim();
    }
    return s.nameUnavailable;
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCodes(trimmed.runes.take(1)).toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 3),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value == null || value!.trim().isEmpty ? '—' : value!.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.espresso,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileFinanceCard extends StatelessWidget {
  const ProfileFinanceCard({
    super.key,
    required this.available,
    required this.unavailable,
    this.availableLabel,
    this.unavailableLabel,
  });

  final double available;
  final double unavailable;
  final String? availableLabel;
  final String? unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: WebSurfaces.card(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.financeStats,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MoneyTile(
                  label: availableLabel ?? s.availableAmount,
                  amount: s.amountTnd(available.toStringAsFixed(2)),
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF15803D),
                  fill: const Color(0xFFDCFCE7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MoneyTile(
                  label: unavailableLabel ?? s.unavailableAmount,
                  amount: s.amountTnd(unavailable.toStringAsFixed(2)),
                  icon: Icons.lock_outline,
                  color: const Color(0xFFB91C1C),
                  fill: const Color(0xFFFEE2E2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.fill,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
