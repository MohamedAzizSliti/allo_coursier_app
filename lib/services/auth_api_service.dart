import '../models/user_model.dart';
import 'api_client.dart';
import 'onboarding_controller.dart';
import 'session_controller.dart';

/// Auth operations via the REST API.
class AuthApiService {
  AuthApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  Future<UserModel> login(String email, String password) async {
    final user = await _api.login(email, password);
    return UserModel.fromJson(user);
  }

  Future<void> logout() async {
    await _api.logout();
  }

  Future<UserModel> getCurrentUser() async {
    final data = await _api.get('/auth/me');
    var user = UserModel.fromJson(data);
    final storedId = user.id.isNotEmpty
        ? user.id
        : await _api.getStoredUserId();
    if (storedId != null && storedId.isNotEmpty) {
      try {
        final card = UserModel.fromJson(await _api.get('/users/$storedId'));
        user = user.mergedWith(card);
      } catch (_) {}
    }
    user = await OnboardingController.instance.overlay(user);
    final session = SessionController.instance.user;
    if (session != null) {
      user = user.mergedWith(session);
    }
    return user;
  }

  /// Live API accepts POST /auth/password (PATCH returns 405).
  /// Sends camelCase and snake_case so both server variants accept it.
  /// Returns true when the access token still carries must_change_password.
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final data = await _api.post('/auth/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return data['signInAgain'] == true;
  }

  /// Saves the signed-in user's own phone and email. A blank field is left as-is.
  Future<void> updateContact({String? phone, String? email}) async {
    await _api.post('/auth/contact', {
      'phone': phone?.trim() ?? '',
      'email': email?.trim() ?? '',
    });
  }
}
