import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../l10n/l10n.dart';
import '../models/user_model.dart';
import 'token_store.dart';

Map<String, dynamic> jsonMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.trim().isNotEmpty) {
    return jsonMap(jsonDecode(raw));
  }
  throw AlloException('unknown', LocaleController.instance.s.unexpectedResponse);
}

/// Unwraps `{ success, data }` or throws [AlloException].
Map<String, dynamic> unwrapEnvelope(dynamic raw) {
  final json = jsonMap(raw);
  if (json['success'] == true) {
    final data = json['data'];
    if (data is Map) return jsonMap(data);
    return {'value': data};
  }
  final error = json['error'] is Map ? jsonMap(json['error']) : <String, dynamic>{};
  throw AlloException(
    error['code'] as String? ?? 'unknown',
    error['message'] as String? ?? LocaleController.instance.s.unexpectedError,
  );
}

/// Paginated `{ rows, total, sum }` payload from list endpoints.
class PageResult {
  const PageResult({required this.rows, required this.total, this.sum});

  final List<dynamic> rows;
  final int total;
  final double? sum;
}

/// Unwraps list endpoints (`data` is List or `{ rows: [] }`).
List<dynamic> unwrapListEnvelope(dynamic raw) {
  return unwrapPageEnvelope(raw).rows;
}

PageResult unwrapPageEnvelope(dynamic raw) {
  final json = jsonMap(raw);
  if (json['success'] == true) {
    final data = json['data'];
    if (data is List) {
      return PageResult(rows: data, total: data.length);
    }
    if (data is Map) {
      final map = jsonMap(data);
      if (map.containsKey('rows')) {
        final rows = map['rows'] is List ? map['rows'] as List : const [];
        return PageResult(
          rows: rows,
          total: (map['total'] as num?)?.toInt() ?? rows.length,
          sum: (map['sum'] as num?)?.toDouble(),
        );
      }
      return PageResult(rows: [map], total: 1);
    }
    if (data == null) return const PageResult(rows: [], total: 0);
    return PageResult(rows: [data], total: 1);
  }
  final error = json['error'] is Map ? jsonMap(json['error']) : <String, dynamic>{};
  throw AlloException(
    error['code'] as String? ?? 'unknown',
    error['message'] as String? ?? LocaleController.instance.s.unexpectedError,
  );
}

/// Maps a Dio failure to [AlloException], preferring the API envelope.
AlloException alloExceptionFromDio(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    if (map['success'] == false || map['error'] is Map) {
      try {
        unwrapEnvelope(map);
      } on AlloException catch (ae) {
        return ae;
      }
    }
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return AlloException(
        'network',
        LocaleController.instance.s.networkError,
      );
    default:
      final status = e.response?.statusCode;
      final s = LocaleController.instance.s;
      if (status == 401) {
        return AlloException(
          'invalid_credentials',
          s.invalidCredentials,
        );
      }
      if (status == 403) {
        return AlloException('forbidden', s.accessDenied);
      }
      if (status == 404) {
        return AlloException('not_found', s.notFound);
      }
      if (status == 409) {
        return AlloException('conflict', s.transitionRefused);
      }
      if (status == 429) {
        return AlloException(
          'rate_limited',
          s.tooManyAttempts,
        );
      }
      return AlloException('unknown', s.unexpectedError);
  }
}

Map<String, dynamic> _asMap(dynamic value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw AlloException('unknown', LocaleController.instance.s.unexpectedResponse);
}

class _GetCacheEntry {
  const _GetCacheEntry(this.value, this.at);

  final Object value;
  final DateTime at;
}

/// Singleton API client matching the server's `{ success, data, error }` envelope.
class AlloApi {
  AlloApi._({Dio? dio, TokenStore? store, bool cacheGets = false})
      : _store = store ?? FallbackTokenStore(const SecureTokenStore()),
        _cacheGets = cacheGets,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: {'Content-Type': 'application/json'},
              validateStatus: (status) => status != null && status < 500,
            ));

  static final AlloApi instance = AlloApi._(cacheGets: true);

  /// Isolated client for unit tests (no secure storage / no singleton).
  factory AlloApi.test({
    required Dio dio,
    TokenStore? store,
    bool cacheGets = false,
  }) {
    return AlloApi._(
      dio: dio,
      store: store ?? MemoryTokenStore(),
      cacheGets: cacheGets,
    );
  }

  final TokenStore _store;
  final Dio _dio;
  final bool _cacheGets;
  final Map<String, _GetCacheEntry> _getCache = {};
  Completer<bool>? _refreshing;

  static const _cacheTtl = Duration(seconds: 25);

  Dio get dio => _dio;

  String _cacheKey(String path, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return path;
    final parts = query.entries.map((e) => '${e.key}=${e.value}').toList()
      ..sort();
    return '$path?${parts.join('&')}';
  }

  Object? _readCache(String path, Map<String, dynamic>? query) {
    if (!_cacheGets) return null;
    final key = _cacheKey(path, query);
    final hit = _getCache[key];
    if (hit == null) return null;
    if (DateTime.now().difference(hit.at) > _cacheTtl) {
      _getCache.remove(key);
      return null;
    }
    return hit.value;
  }

  void _writeCache(String path, Map<String, dynamic>? query, Object value) {
    if (!_cacheGets) return;
    _getCache[_cacheKey(path, query)] = _GetCacheEntry(value, DateTime.now());
  }

  void clearGetCache() => _getCache.clear();

  Future<void> loadToken() async {
    final token = await _store.read(ApiConfig.accessTokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  bool _skipRefresh(String path) {
    return path == '/auth/login' ||
        path == '/auth/refresh' ||
        path == '/auth/logout' ||
        path == '/auth/password';
  }

  bool _isExpiredStatus(int? status, dynamic body) {
    if (status == 401) return true;
    if (status != 403) return false;
    try {
      if (body != null) unwrapEnvelope(body);
    } on AlloException catch (e) {
      return e.isUnauthorized;
    }
    return false;
  }

  Future<bool> _tryRefresh() async {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight.future;
    final lock = Completer<bool>();
    _refreshing = lock;
    var ok = false;
    try {
      final refresh = await _store.read(ApiConfig.refreshTokenKey);
      if (refresh == null || refresh.isEmpty) {
        lock.complete(false);
        _refreshing = null;
        return false;
      }
      final res = await _dio.request(
        '/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(method: 'POST'),
      );
      if (res.statusCode != 200) {
        lock.complete(false);
        _refreshing = null;
        return false;
      }
      final payload = unwrapEnvelope(res.data);
      final session = _asMap(payload['session'] ?? payload, 'session');
      final access = session['access_token']?.toString();
      final nextRefresh = session['refresh_token']?.toString();
      if (access == null || access.isEmpty) {
        lock.complete(false);
        _refreshing = null;
        return false;
      }
      _dio.options.headers['Authorization'] = 'Bearer $access';
      await _store.write(ApiConfig.accessTokenKey, access);
      if (nextRefresh != null && nextRefresh.isNotEmpty) {
        await _store.write(ApiConfig.refreshTokenKey, nextRefresh);
      }
      final user = payload['user'];
      if (user is Map) await persistIdentity(jsonMap(user));
      clearGetCache();
      ok = true;
    } catch (_) {
      ok = false;
    }
    lock.complete(ok);
    _refreshing = null;
    return ok;
  }

  Future<Response<dynamic>> _send(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      Future<Response<dynamic>> request() {
        return _dio.request(
          path,
          data: data,
          queryParameters: query,
          options: Options(method: method),
        );
      }

      var res = await request();
      if (_isExpiredStatus(res.statusCode, res.data) && !_skipRefresh(path)) {
        if (await _tryRefresh()) {
          res = await request();
        }
      }
      if (res.statusCode == 401) {
        throw unauthorizedFromBody(res.data);
      }
      return res;
    } on AlloException {
      rethrow;
    } on DioException catch (e) {
      throw alloExceptionFromDio(e);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _send('POST', '/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = unwrapEnvelope(res.data);
    final session = _asMap(data['session'] ?? data, 'session');
    final access = session['access_token']?.toString() ??
        data['access_token']?.toString();
    final refresh = session['refresh_token']?.toString() ??
        data['refresh_token']?.toString();
    if (access == null || access.isEmpty) {
      throw AlloException('unknown', LocaleController.instance.s.unexpectedResponse);
    }

    _dio.options.headers['Authorization'] = 'Bearer $access';
    await _store.write(ApiConfig.accessTokenKey, access);
    if (refresh != null && refresh.isNotEmpty) {
      await _store.write(ApiConfig.refreshTokenKey, refresh);
    }

    final user = _asMap(data['user'] ?? data, 'user');
    await persistIdentity(user);
    clearGetCache();

    return user;
  }

  Future<void> persistIdentity(Map<String, dynamic> user) async {
    final parsed = UserModel.fromJson(user);
    if (parsed.role.isNotEmpty) {
      await _store.write(ApiConfig.userRoleKey, parsed.role);
    }
    if (parsed.id.isNotEmpty) {
      await _store.write(ApiConfig.userIdKey, parsed.id);
    }
    await persistMustChangePassword(parsed.mustChangePassword);
  }

  Future<void> persistMustChangePassword(bool value) async {
    if (value) {
      await _store.write(ApiConfig.mustChangePasswordKey, '1');
    } else {
      await _store.delete(ApiConfig.mustChangePasswordKey);
    }
  }

  Future<bool> getStoredMustChangePassword() async {
    return await _store.read(ApiConfig.mustChangePasswordKey) == '1';
  }

  Future<void> logout() async {
    try {
      await _send('POST', '/auth/logout');
    } catch (_) {
      // Even if server call fails, clear local session keys.
    }
    await _store.delete(ApiConfig.accessTokenKey);
    await _store.delete(ApiConfig.refreshTokenKey);
    await _store.delete(ApiConfig.userRoleKey);
    await _store.delete(ApiConfig.userIdKey);
    await _store.delete(ApiConfig.mustChangePasswordKey);
    _dio.options.headers.remove('Authorization');
    clearGetCache();
  }

  Future<Map<String, dynamic>> get(String path, [Map<String, dynamic>? query]) async {
    final cached = _readCache(path, query);
    if (cached is Map<String, dynamic>) return cached;
    final res = await _send('GET', path, query: query);
    final data = unwrapEnvelope(res.data);
    _writeCache(path, query, data);
    return data;
  }

  Future<List<dynamic>> getList(
    String path, [
    Map<String, dynamic>? query,
    bool fresh = false,
  ]) async {
    return (await getPage(path, query, fresh)).rows;
  }

  Future<PageResult> getPage(
    String path, [
    Map<String, dynamic>? query,
    bool fresh = false,
  ]) async {
    if (!fresh) {
      final cached = _readCache(path, query);
      if (cached is PageResult) return cached;
    }
    final res = await _send('GET', path, query: query);
    final page = unwrapPageEnvelope(res.data);
    _writeCache(path, query, page);
    return page;
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final res = await _send('POST', path, data: body ?? {});
    clearGetCache();
    return unwrapEnvelope(res.data);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final res = await _send('PATCH', path, data: body);
    clearGetCache();
    return unwrapEnvelope(res.data);
  }

  Future<void> delete(String path) async {
    final res = await _send('DELETE', path);
    unwrapEnvelope(res.data);
    clearGetCache();
  }

  Future<String?> getStoredRole() => _store.read(ApiConfig.userRoleKey);
  Future<String?> getStoredUserId() => _store.read(ApiConfig.userIdKey);
  Future<String?> getAccessToken() => _store.read(ApiConfig.accessTokenKey);
  Future<bool> hasStoredSession() async {
    final token = await _store.read(ApiConfig.accessTokenKey);
    return token != null && token.isNotEmpty;
  }
}

AlloException unauthorizedFromBody(dynamic data) {
  try {
    if (data != null) unwrapEnvelope(data);
  } on AlloException catch (e) {
    return AlloException('unauthorized', e.message);
  } catch (_) {}
  return AlloException(
    'unauthorized',
    LocaleController.instance.s.invalidCredentials,
  );
}

class AlloException implements Exception {
  final String code;
  final String message;

  const AlloException(this.code, this.message);

  bool get isUnauthorized {
    switch (code) {
      case 'unauthorized':
      case 'invalid_credentials':
      case 'unauthenticated':
      case 'session_expired':
      case 'invalid_session':
      case 'invalid_token':
      case 'token_expired':
      case 'jwt_expired':
        return true;
    }
    final normalized = message.toLowerCase();
    return normalized.contains('session') &&
        (normalized.contains('expir') ||
            normalized.contains('invalide') ||
            normalized.contains('invalid'));
  }
  bool get isInvalidPassword => code == 'invalid_current_password';
  bool get isForbidden => code == 'forbidden';
  bool get isNotFound => code == 'not_found';
  bool get isConflict => code == 'conflict';
  bool get isRateLimited => code == 'rate_limited';
  bool get isNetwork => code == 'network';

  @override
  String toString() => message;
}
