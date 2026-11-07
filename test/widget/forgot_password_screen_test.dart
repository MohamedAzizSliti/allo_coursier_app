import 'package:allo_coursier_app/screens/auth/forgot_password_screen.dart';
import 'package:allo_coursier_app/screens/auth/login_screen.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login fills the beige canvas and shows forgot-password',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LoginScreen(),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.beige);
    expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
    expect(find.text('مرحباً !'), findsOneWidget);
  });

  testWidgets('forgot password validates email and phone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ForgotPasswordScreen(),
      ),
    );

    await tester.ensureVisible(find.text('إرسال الطلب'));
    await tester.tap(find.text('إرسال الطلب'));
    await tester.pump();

    expect(find.text('أدخل بريدك الإلكتروني'), findsOneWidget);
    expect(find.text('أدخل رقم الهاتف'), findsOneWidget);
  });

  testWidgets('forgot password sends an office reclamation', (tester) async {
    String? sentEmail;
    String? sentPhone;
    String? sentNote;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ForgotPasswordScreen(
          initialEmail: 'rabeb@allocoursier.tn',
          sender: (reclamation) async {
            sentEmail = reclamation.email;
            sentPhone = reclamation.phone;
            sentNote = reclamation.note;
          },
        ),
      ),
    );

    expect(find.text('rabeb@allocoursier.tn'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '25406333');
    await tester.enterText(find.byType(TextFormField).at(2), 'Merci de m’appeler');
    await tester.ensureVisible(find.text('إرسال الطلب'));
    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();

    expect(sentEmail, 'rabeb@allocoursier.tn');
    expect(sentPhone, '25406333');
    expect(sentNote, 'Merci de m’appeler');
    expect(
      find.textContaining('سيتصل بك المكتب'),
      findsWidgets,
    );
  });
}
