import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'token_store.dart';

/// First-launch language/onboarding and local sender profile overlay.
class OnboardingController extends ChangeNotifier {
  OnboardingController._({TokenStore? store})
      : _store = store ?? FallbackTokenStore(const SecureTokenStore());

  static final OnboardingController instance = OnboardingController._();

  @visibleForTesting
  factory OnboardingController.forTest(TokenStore store) {
    return OnboardingController._(store: store);
  }

  static const _onboardingKey = 'onboarding_v1_done';
  static const _profilePrefix = 'profile_overlay_';
  static const _completePrefix = 'profile_complete_';

  final TokenStore _store;
  final Map<String, Map<String, dynamic>> _memory = {};

  bool _ready = false;
  bool _seenOnboarding = false;

  bool get ready => _ready;
  bool get hasSeenOnboarding => _seenOnboarding;

  Future<void> load() async {
    try {
      _seenOnboarding = await _store.read(_onboardingKey) == '1';
    } catch (_) {
      _seenOnboarding = false;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _seenOnboarding = true;
    notifyListeners();
    try {
      await _store.write(_onboardingKey, '1');
    } catch (_) {}
  }

  Future<bool> isProfileComplete(String userId) async {
    try {
      return await _store.read('$_completePrefix$userId') == '1';
    } catch (_) {
      return false;
    }
  }

  Future<UserModel> overlay(UserModel user) async {
    final merged = {
      ...?await _readMap(''),
      ...?await _readMap(user.id),
    };
    if (merged.isEmpty) return user;
    return user.mergedWith(
      UserModel(
        id: _text(merged['id']) ?? user.id,
        email: _text(merged['email']) ?? '',
        name: _text(merged['name']) ?? '',
        role: _text(merged['role']) ?? user.role,
        phone: _text(merged['phone']),
        address: _text(merged['address']),
        city: _text(merged['city']),
        gouvernorat: _text(merged['gouvernorat']),
        company: _text(merged['company']),
        cin: _text(merged['cin']),
      ),
    );
  }

  Future<void> saveOverlay(UserModel user) async {
    final body = user.toLocalCard();
    _memory[user.id] = body;
    if (user.id.isNotEmpty) {
      _memory[''] = {...?_memory[''], ...body};
    } else {
      _memory[''] = body;
    }
    try {
      final encoded = jsonEncode(body);
      await _store.write('$_profilePrefix${user.id}', encoded);
      if (!user.needsCompletion && user.id.isNotEmpty) {
        await _store.write('$_completePrefix${user.id}', '1');
      }
    } catch (_) {
      // RAM overlay still applies for this session.
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _readMap(String userId) async {
    final ram = _memory[userId];
    if (ram != null && ram.isNotEmpty) return ram;
    try {
      final raw = await _store.read('$_profilePrefix$userId');
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return Map<String, dynamic>.from(map);
    } catch (_) {
      return null;
    }
  }

  static String? _text(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
