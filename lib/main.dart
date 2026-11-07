import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'l10n/l10n.dart';
import 'screens/agent/agent_dashboard.dart';
import 'screens/auth/login_screen.dart';
import 'screens/business_client/client_dashboard.dart';
import 'screens/livreur/livreur_dashboard.dart';
import 'screens/onboarding/complete_profile_screen.dart';
import 'screens/onboarding/language_welcome_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/settings/change_password_screen.dart';
import 'services/app_entry.dart';
import 'widgets/live_notifications.dart';
import 'services/onboarding_controller.dart';
import 'services/session_controller.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.load();
  await OnboardingController.instance.load();
  await SessionController.instance.hydrate();
  runApp(const MyApp());
  unawaited(SessionController.instance.validateInBackground());
  unawaited(Permission.notification.request());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final locale = LocaleController.instance;
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: locale.locale,
          supportedLocales: const [Locale('ar'), Locale('fr')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LiveNotificationHost(child: SessionGate()),
        );
      },
    );
  }
}

/// Switches login vs dashboard from [SessionController] without remounting
/// [MaterialApp] when the language changes.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        SessionController.instance,
        OnboardingController.instance,
        LocaleController.instance,
      ]),
      builder: (context, _) {
        final session = SessionController.instance;
        final onboarding = OnboardingController.instance;
        if (!session.ready || !onboarding.ready) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        switch (resolveAppEntry(
          hasChosenLanguage: LocaleController.instance.hasChosenLanguage,
          hasSeenOnboarding: onboarding.hasSeenOnboarding,
          isSignedIn: session.isSignedIn,
          profileIncomplete: session.profileIncomplete,
          mustChangePassword: session.mustChangePassword,
        )) {
          case AppEntry.language:
            return const LanguageWelcomeScreen();
          case AppEntry.onboarding:
            return const OnboardingScreen();
          case AppEntry.completeProfile:
            return const CompleteProfileScreen();
          case AppEntry.changePassword:
            return const ChangePasswordScreen(requiredChange: true);
          case AppEntry.shell:
            return shellForRole(session.role);
        }
      },
    );
  }
}

Widget shellForRole(String? role) {
  switch (role) {
    case 'admin':
      return const AgentDashboard(role: 'admin');
    case 'agent':
      return const AgentDashboard(role: 'agent');
    case 'business_client':
      return const ClientDashboard();
    case 'delivery_person':
      return const LivreurDashboard();
    default:
      return const LoginScreen();
  }
}
