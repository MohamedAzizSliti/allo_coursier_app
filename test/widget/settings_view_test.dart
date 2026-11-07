import 'package:allo_coursier_app/models/user_model.dart';
import 'package:allo_coursier_app/screens/settings/settings_screen.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserModel(
    id: '8',
    email: 'exp-1560@expediteur.allocoursier.tn',
    name: 'verona',
    role: 'business_client',
    phone: '54740030',
  );

  testWidgets('settings view shows account, language and logout', (tester) async {
    var openedProfile = false;
    var openedPassword = false;
    var loggedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsView(
              user: user,
              onOpenProfile: () => openedProfile = true,
              onEditProfile: () {},
              onChangePassword: () => openedPassword = true,
              onLogout: () => loggedOut = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('verona'), findsOneWidget);
    expect(find.text('الحساب'), findsOneWidget);
    expect(find.text('التفضيلات'), findsOneWidget);
    expect(find.text('الدعم'), findsOneWidget);
    expect(find.text('اللغة'), findsOneWidget);
    expect(find.text('تعديل الملف'), findsOneWidget);
    expect(find.text('تغيير كلمة المرور'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.text('اتصال بالمكتب'), findsOneWidget);

    expect(find.textContaining('عرض الملف الشخصي'), findsOneWidget);

    await tester.tap(find.text('verona'));
    await tester.tap(find.text('تغيير كلمة المرور'));
    await tester.tap(find.text('تسجيل الخروج'));

    expect(openedProfile, isTrue);
    expect(openedPassword, isTrue);
    expect(loggedOut, isTrue);
  });

  testWidgets('non-sender settings hide edit profile', (tester) async {
    const agent = UserModel(
      id: '20',
      email: 'agent@allocoursier.tn',
      name: 'rabeb',
      role: 'agent',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: SettingsView(
              user: agent,
              onOpenProfile: _noop,
              onChangePassword: _noop,
              onLogout: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.text('تعديل الملف'), findsNothing);
    expect(find.textContaining('وكيل'), findsOneWidget);
  });
}

void _noop() {}
