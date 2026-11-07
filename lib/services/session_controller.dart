import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'api_client.dart';
import 'notification_api_service.dart';
import 'onboarding_controller.dart';

/// In-memory session that hydrates from the token store and only
/// signs out when the server rejects the token (401).
class SessionController extends ChangeNotifier {
  SessionController({AlloApi? api}) : _api = api ?? AlloApi.instance;

  static final SessionController instance = SessionController();

  final AlloApi _api;

  String? _role;
  UserModel? _user;
  bool _ready = false;
  bool _validating = false;
  bool _profileIncomplete = false;

  String? get role => _role;
  UserModel? get user => _user;
  bool get ready => _ready;
  bool get isSignedIn => _isKnownRole(_role);
  bool get profileIncomplete => _profileIncomplete;
  bool get mustChangePassword => _user?.mustChangePassword == true;

  static bool _isKnownRole(String? role) {
    return role == 'admin' ||
        role == 'agent' ||
        role == 'business_client' ||
        role == 'delivery_person';
  }

  /// Restore token + cached role without waiting for the network.
  Future<void> hydrate() async {
    await _api.loadToken();
    final hasSession = await _api.hasStoredSession();
    if (!hasSession) {
      _role = null;
      _ready = true;
      notifyListeners();
      return;
    }

    final stored = await _api.getStoredRole();
    _role = _isKnownRole(stored) ? stored : null;
    final storedId = await _api.getStoredUserId();
    if (storedId != null && storedId.isNotEmpty) {
      _user = await OnboardingController.instance.overlay(
        UserModel(
          id: storedId,
          email: '',
          name: '',
          role: _role ?? '',
          mustChangePassword: await _api.getStoredMustChangePassword(),
        ),
      );
    }
    _ready = true;
    notifyListeners();
  }

  /// Confirm the token in the background. Network errors keep the session.
  Future<void> validateInBackground() async {
    if (_validating) return;
    final token = await _api.getAccessToken();
    if (token == null || token.isEmpty) return;

    _validating = true;
    try {
      final raw = await _api.get('/auth/me');
      await _api.persistIdentity(raw);
      final remote = await OnboardingController.instance.overlay(
        UserModel.fromJson(raw),
      );
      final user = _user == null ? remote : remote.mergedWith(_user!);
      _user = user;
      final nextRole = user.role;
      final incomplete = await _computeIncomplete(user);
      if ((_isKnownRole(nextRole) && nextRole != _role) ||
          incomplete != _profileIncomplete) {
        _role = _isKnownRole(nextRole) ? nextRole : _role;
        _profileIncomplete = incomplete;
      }
      notifyListeners();
      try {
        await NotificationApiService().registerPushTokenIfAvailable();
      } catch (_) {}
    } on AlloException catch (e) {
      if (e.isUnauthorized) {
        await _api.logout();
        _role = null;
        _user = null;
        _profileIncomplete = false;
        _ready = true;
        notifyListeners();
      }
    } finally {
      _validating = false;
    }
  }

  Future<void> signedIn(String role, {UserModel? user}) async {
    _role = _isKnownRole(role) ? role : null;
    _ready = true;
    if (user != null) {
      _user = await OnboardingController.instance.overlay(user);
      _profileIncomplete = await _computeIncomplete(_user!);
    } else {
      _profileIncomplete = role == 'business_client';
    }
    notifyListeners();
  }

  void rememberUser(UserModel user) {
    _user = _user == null ? user : user.mergedWith(_user!);
    notifyListeners();
  }

  void rememberProfile(UserModel user) {
    rememberUser(user);
    _profileIncomplete = false;
    notifyListeners();
  }

  Future<void> markProfileComplete() async {
    _profileIncomplete = false;
    notifyListeners();
  }

  Future<void> clearMustChangePassword() async {
    final user = _user;
    if (user == null || !user.mustChangePassword) return;
    _user = user.copyWith(mustChangePassword: false);
    await _api.persistMustChangePassword(false);
    notifyListeners();
  }

  Future<void> signedOut() async {
    await _api.logout();
    _role = null;
    _user = null;
    _profileIncomplete = false;
    _ready = true;
    notifyListeners();
  }

  Future<bool> _computeIncomplete(UserModel user) async {
    if (user.role != 'business_client') return false;
    if (await OnboardingController.instance.isProfileComplete(user.id)) {
      return false;
    }
    final merged = await OnboardingController.instance.overlay(user);
    return merged.needsCompletion;
  }
}
