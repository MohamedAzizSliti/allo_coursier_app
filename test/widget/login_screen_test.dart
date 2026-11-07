import 'package:allo_coursier_app/l10n/l10n.dart';
import 'package:allo_coursier_app/screens/auth/login_messages.dart';
import 'package:allo_coursier_app/screens/auth/login_screen.dart';
import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login validates empty identifier and short password', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LoginScreen(),
      ),
    );

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pump();

    expect(find.text('أدخل المعرّف'), findsOneWidget);
    expect(
      find.text('كلمة المرور قصيرة جداً (6 أحرف على الأقل)'),
      findsOneWidget,
    );
  });

  testWidgets('login accepts sender name without @', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LoginScreen(),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'mouna mbarek');
    await tester.pump();

    expect(find.text('mouna mbarek'), findsOneWidget);
    expect(find.text('البريد أو الاسم أو المعرّف'), findsOneWidget);
    expect(find.text('أدخل بريداً صالحاً'), findsNothing);
    expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
  });

  test('loginErrorMessage maps AlloException codes', () {
    expect(
      loginErrorMessage(const AlloException('rate_limited', 'slow')),
      LocaleController.instance.s.tooManyAttempts,
    );
    expect(
      loginErrorMessage(const AlloException('unauthorized', 'nope')),
      LocaleController.instance.s.invalidCredentials,
    );
    expect(
      loginErrorMessage(const AlloException('conflict', 'busy')),
      'busy',
    );
    expect(
      loginErrorMessage(Exception('x')),
      LocaleController.instance.s.networkError,
    );
    expect(
      loginErrorMessage(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
            data: {
              'success': false,
              'error': {
                'code': 'invalid_credentials',
                'message': 'Email ou mot de passe incorrect',
              },
            },
          ),
        ),
      ),
      LocaleController.instance.s.invalidCredentials,
    );
  });
}
