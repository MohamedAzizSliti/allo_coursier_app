/// API configuration constants.
///
/// Default host is production. Override at build time:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/mobile`
///
/// Local alternatives:
/// - Emulator Android: `http://10.0.2.2:3000/api/mobile`
/// - Simulator iOS: `http://localhost:3000/api/mobile`
/// - Physical device: `http://<PC_IP>:3000/api/mobile`
class ApiConfig {
  ApiConfig._();

  static const String _defaultBaseUrl =
      'https://allo-coursier.vercel.app/api/mobile';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String mustChangePasswordKey = 'must_change_password';
}
