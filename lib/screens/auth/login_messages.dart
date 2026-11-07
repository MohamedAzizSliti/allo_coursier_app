import 'package:dio/dio.dart';

import '../../l10n/l10n.dart';
import '../../services/api_client.dart';

/// Staff uses email; expéditeur uses partner name (`mouna mbarek`).
String? validateLoginIdentifier(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocaleController.instance.s.enterIdentifier;
  }
  return null;
}

String? validateLoginPassword(String? value) {
  if (value == null || value.length < 6) {
    return LocaleController.instance.s.passwordTooShort;
  }
  return null;
}

String loginErrorMessage(Object error) {
  final s = LocaleController.instance.s;
  if (error is DioException) {
    return loginErrorMessage(alloExceptionFromDio(error));
  }
  if (error is AlloException) {
    if (error.isRateLimited) return s.tooManyAttempts;
    if (error.isUnauthorized) return s.invalidCredentials;
    if (error.isNetwork) return s.networkError;
    return error.message;
  }
  return s.networkError;
}
