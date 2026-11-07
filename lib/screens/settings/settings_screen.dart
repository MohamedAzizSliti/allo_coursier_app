import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/office_contact.dart';
import '../../l10n/l10n.dart';
import '../../models/user_model.dart';
import '../../services/auth_api_service.dart';
import '../../services/session_controller.dart';
import '../../theme/app_theme.dart';
import '../onboarding/complete_profile_screen.dart';
import '../profile_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _user = SessionController.instance.user;
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    try {
      final user = await AuthApiService().getCurrentUser();
      if (!mounted) return;
      SessionController.instance.rememberUser(user);
      setState(() => _user = user);
    } catch (_) {
      if (!mounted) return;
      setState(() => _user = SessionController.instance.user ?? _user);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) {
      setState(() => _user = SessionController.instance.user ?? _user);
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    await SessionController.instance.signedOut();
  }

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: AppColors.beige,
        foregroundColor: AppColors.espresso,
        elevation: 0,
        title: Text(
          s.settings,
          style: const TextStyle(
            color: AppColors.espresso,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.espresso),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUser,
        color: AppColors.brand,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SettingsView(
              user: user,
              onOpenProfile: () => _open(const ProfileScreen()),
              onEditProfile: user?.role == 'business_client'
                  ? () => _open(const CompleteProfileScreen())
                  : null,
              onChangePassword: () => _open(const ChangePasswordScreen()),
              onLogout: _logout,
              onCallOffice: () => _launch(Uri(scheme: 'tel', path: OfficeContact.phoneTel)),
              onEmailOffice: () => _launch(Uri(scheme: 'mailto', path: OfficeContact.email)),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.user,
    required this.onOpenProfile,
    required this.onChangePassword,
    required this.onLogout,
    this.onEditProfile,
    this.onCallOffice,
    this.onEmailOffice,
  });

  final UserModel? user;
  final VoidCallback onOpenProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;
  final VoidCallback? onEditProfile;
  final VoidCallback? onCallOffice;
  final VoidCallback? onEmailOffice;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UserCard(user: user, onTap: onOpenProfile),
        const SizedBox(height: 20),
        _Group(
          title: s.account,
          children: [
            if (onEditProfile != null)
              _Tile(
                icon: Icons.edit_outlined,
                title: s.editProfile,
                onTap: onEditProfile,
              ),
            _Tile(
              icon: Icons.lock_outline_rounded,
              title: s.changePassword,
              onTap: onChangePassword,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Group(
          title: s.preferences,
          children: const [_LanguageTile()],
        ),
        const SizedBox(height: 16),
        _Group(
          title: s.support,
          children: [
            _Tile(
              icon: Icons.phone_outlined,
              title: s.callOffice,
              subtitle: OfficeContact.phoneDisplay,
              onTap: onCallOffice,
            ),
            _Tile(
              icon: Icons.mail_outline_rounded,
              title: s.emailOffice,
              subtitle: OfficeContact.email,
              onTap: onEmailOffice,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              s.logout,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.appVersion('1.0.0'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textLight, fontSize: 12),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});

  final UserModel? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : s.nameUnavailable;
    final email = user?.email.trim() ?? '';
    final role = user == null ? '' : s.roleSingular(user!.role);
    final initial = name == s.nameUnavailable
        ? '?'
        : String.fromCharCodes(name.runes.take(1)).toUpperCase();

    return Material(
      color: AppColors.espresso,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      role.isEmpty ? s.viewProfile : '${s.viewProfile} · $role',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: WebSurfaces.card(radius: 20),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 56, endIndent: 16),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.brand, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.espresso,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
            ),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textLight),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final locale = LocaleController.instance;
        return _Tile(
          icon: Icons.language_rounded,
          title: locale.s.language,
          trailing: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('ع')),
              ButtonSegment(value: false, label: Text('FR')),
            ],
            selected: {locale.isArabic},
            onSelectionChanged: (value) => locale.setArabic(value.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.brand;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.brand;
                }
                return AppColors.cream;
              }),
            ),
          ),
        );
      },
    );
  }
}
