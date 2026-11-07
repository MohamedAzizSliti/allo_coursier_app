import '../../config/office_contact.dart';
import '../../l10n/l10n.dart';

class PasswordReclamation {
  const PasswordReclamation({
    required this.email,
    required this.phone,
    this.note,
  });

  final String email;
  final String phone;
  final String? note;
}

typedef PasswordReclamationSender = Future<void> Function(
  PasswordReclamation reclamation,
);

String? validateForgotEmail(String? value) {
  final s = LocaleController.instance.s;
  if (value == null || value.trim().isEmpty) {
    return s.enterEmail;
  }
  if (!value.contains('@')) {
    return s.enterValidEmail;
  }
  return null;
}

String? validateForgotPhone(String? value) {
  final s = LocaleController.instance.s;
  if (value == null || value.trim().isEmpty) {
    return s.enterPhone;
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8) {
    return s.invalidPhone;
  }
  return null;
}

Uri buildPasswordReclamationMailto({
  required String email,
  required String phone,
  String? note,
}) {
  final trimmedNote = note?.trim() ?? '';
  final body = StringBuffer()
    ..writeln('Type : Réclamation mot de passe oublié')
    ..writeln('Email : $email')
    ..writeln('Téléphone : $phone');
  if (trimmedNote.isNotEmpty) {
    body.writeln('Message : $trimmedNote');
  }
  body
    ..writeln()
    ..writeln(
      'Merci de contacter cette personne et de lui envoyer un nouveau mot de passe.',
    );

  return Uri(
    scheme: 'mailto',
    path: OfficeContact.email,
    queryParameters: {
      'subject': 'Réclamation : mot de passe oublié',
      'body': body.toString(),
    },
  );
}
