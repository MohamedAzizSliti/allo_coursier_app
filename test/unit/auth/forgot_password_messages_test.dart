import 'package:allo_coursier_app/config/office_contact.dart';
import 'package:allo_coursier_app/screens/auth/forgot_password_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validateForgotEmail requires a valid email', () {
    expect(validateForgotEmail(null), 'أدخل بريدك الإلكتروني');
    expect(validateForgotEmail(''), 'أدخل بريدك الإلكتروني');
    expect(validateForgotEmail('not-an-email'), 'أدخل بريداً صالحاً');
    expect(validateForgotEmail('rabeb@allocoursier.tn'), isNull);
  });

  test('validateForgotPhone requires a Tunisian-length number', () {
    expect(validateForgotPhone(null), 'أدخل رقم الهاتف');
    expect(validateForgotPhone('12'), 'رقم هاتف غير صالح');
    expect(validateForgotPhone('25 406 333'), isNull);
    expect(validateForgotPhone('+21625406333'), isNull);
  });

  test('buildPasswordReclamationMailto emails the office', () {
    final uri = buildPasswordReclamationMailto(
      email: 'client@test.tn',
      phone: '25 000 129',
      note: 'Compte bloqué',
    );

    expect(uri.scheme, 'mailto');
    expect(uri.path, OfficeContact.email);
    expect(uri.queryParameters['subject'], contains('mot de passe'));
    expect(uri.queryParameters['body'], contains('client@test.tn'));
    expect(uri.queryParameters['body'], contains('25 000 129'));
    expect(uri.queryParameters['body'], contains('Compte bloqué'));
    expect(uri.queryParameters['body'], contains('Réclamation'));
  });
}
