import 'package:dio/dio.dart';

import '../config/supabase_config.dart';
import '../l10n/l10n.dart';
import 'api_client.dart';

/// Thin PostgREST client — same backend the web VillePicker uses via Supabase.
class SupabaseRest {
  SupabaseRest({
    Dio? dio,
    Future<String?> Function()? accessToken,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: SupabaseConfig.restUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'apikey': SupabaseConfig.anonKey,
                  'Accept': 'application/json',
                },
              ),
            ),
        _accessToken = accessToken ?? _defaultAccessToken;

  static Future<String?> _defaultAccessToken() =>
      AlloApi.instance.getAccessToken();

  final Dio _dio;
  final Future<String?> Function() _accessToken;

  Future<Options> _authOptions({Map<String, dynamic>? headers}) async {
    final token = await _accessToken();
    if (token == null || token.isEmpty) {
      throw AlloException(
        'unauthorized',
        LocaleController.instance.s.notAuthenticated,
      );
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'apikey': SupabaseConfig.anonKey,
        ...?headers,
      },
    );
  }

  /// GET `/rest/v1/{table}` with optional Prefer count.
  Future<({List<dynamic> rows, int? total})> select(
    String table, {
    required String select,
    Map<String, dynamic>? filters,
    String? order,
    int? limit,
    int? offset,
    bool countExact = false,
  }) async {
    final query = <String, dynamic>{
      'select': select,
      if (order != null && order.isNotEmpty) 'order': order,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      ...?filters,
    };
    try {
      final res = await _dio.get<dynamic>(
        '/$table',
        queryParameters: query,
        options: await _authOptions(
          headers: countExact
              ? {'Prefer': 'count=exact', 'Accept': 'application/json'}
              : null,
        ),
      );
      final rows = res.data is List ? res.data as List : const [];
      int? total;
      if (countExact) {
        final range = res.headers.value('content-range');
        // e.g. 0-24/212 or */0
        final match = RegExp(r'/(\d+|\*)\s*$').firstMatch(range ?? '');
        final raw = match?.group(1);
        if (raw != null && raw != '*') total = int.tryParse(raw);
      }
      return (rows: rows, total: total ?? rows.length);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<dynamic>> rpc(String name, [Map<String, dynamic>? body]) async {
    try {
      final res = await _dio.post<dynamic>(
        '/rpc/$name',
        data: body ?? const {},
        options: await _authOptions(),
      );
      if (res.data is List) return res.data as List;
      return const [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AlloException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? message;
    if (data is Map) {
      message = data['message']?.toString() ?? data['error']?.toString();
    }
    final s = LocaleController.instance.s;
    if (status == 401 || status == 403) {
      return AlloException('forbidden', message ?? s.accessDenied);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return AlloException('network', s.networkError);
    }
    return AlloException('unknown', message ?? s.unexpectedError);
  }
}
