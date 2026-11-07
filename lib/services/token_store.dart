import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token persistence used by [AlloApi].
abstract class TokenStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  static const FlutterSecureStorage _box = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> write(String key, String value) => _box.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _box.read(key: key);

  @override
  Future<void> delete(String key) => _box.delete(key: key);

  @override
  Future<void> deleteAll() => _box.deleteAll();
}

/// Keeps tokens in memory if the platform secure store fails (emulator KeyStore).
class FallbackTokenStore implements TokenStore {
  FallbackTokenStore(this._primary);

  final TokenStore _primary;
  final MemoryTokenStore _memory = MemoryTokenStore();

  @override
  Future<void> write(String key, String value) async {
    _memory.data[key] = value;
    try {
      await _primary.write(key, value);
    } catch (_) {}
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _primary.read(key) ?? _memory.data[key];
    } catch (_) {
      return _memory.data[key];
    }
  }

  @override
  Future<void> delete(String key) async {
    _memory.data.remove(key);
    try {
      await _primary.delete(key);
    } catch (_) {}
  }

  @override
  Future<void> deleteAll() async {
    _memory.data.clear();
    try {
      await _primary.deleteAll();
    } catch (_) {}
  }
}

/// In-memory store for unit tests (no platform channel).
class MemoryTokenStore implements TokenStore {
  final Map<String, String> data = {};

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }

  @override
  Future<void> deleteAll() async => data.clear();
}
