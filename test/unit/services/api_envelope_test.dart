import 'package:allo_coursier_app/config/api_config.dart';
import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/services/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unwrapEnvelope returns data map on success', () {
    final data = unwrapEnvelope({
      'success': true,
      'data': {'id': '1'},
    });
    expect(data['id'], '1');
  });

  test('unwrapEnvelope throws AlloException on error', () {
    expect(
      () => unwrapEnvelope({
        'success': false,
        'error': {'code': 'unauthorized', 'message': 'Non autorisé'},
      }),
      throwsA(
        isA<AlloException>()
            .having((e) => e.isUnauthorized, 'isUnauthorized', true)
            .having((e) => e.message, 'message', 'Non autorisé'),
      ),
    );
  });

  test('unwrapListEnvelope accepts rows wrapper', () {
    final list = unwrapListEnvelope({
      'success': true,
      'data': {
        'rows': [
          {'id': '1'},
        ],
      },
    });
    expect(list, hasLength(1));
  });

  test('unwrapPageEnvelope reads rows total sum', () {
    final page = unwrapPageEnvelope({
      'success': true,
      'data': {
        'rows': [
          {'id': '1'},
        ],
        'total': 567,
        'sum': 46249,
      },
    });
    expect(page.rows, hasLength(1));
    expect(page.total, 567);
    expect(page.sum, 46249);
  });

  test('alloExceptionFromDio maps 409 conflict', () {
    final error = alloExceptionFromDio(
      DioException(
        requestOptions: RequestOptions(path: '/commandes/1/claim'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/commandes/1/claim'),
          statusCode: 409,
          data: {
            'success': false,
            'error': {
              'code': 'conflict',
              'message': 'Transition refusée : un colis « En cours » ne peut pas passer à « En route ».',
            },
          },
        ),
      ),
    );
    expect(error.isConflict, isTrue);
    expect(error.message, contains('Transition refusée'));
  });

  test('AlloException conflict and rate limit flags', () {
    expect(const AlloException('conflict', 'x').isConflict, isTrue);
    expect(const AlloException('rate_limited', 'x').isRateLimited, isTrue);
    expect(const AlloException('network', 'x').isNetwork, isTrue);
  });

  test('alloExceptionFromDio reads 401 envelope', () {
    final error = alloExceptionFromDio(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {
            'success': false,
            'error': {
              'code': 'invalid_credentials',
              'message': 'Email ou mot de passe incorrect',
            },
          },
        ),
      ),
    );
    expect(error.isUnauthorized, isTrue);
    expect(error.message, 'Email ou mot de passe incorrect');
  });

  test('alloExceptionFromDio maps connection errors', () {
    final error = alloExceptionFromDio(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(error.isNetwork, isTrue);
  });

  test('GET 401 session expired is unauthorized', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test/api/mobile',
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 401,
              data: {
                'success': false,
                'error': {
                  'code': 'unknown',
                  'message': 'Session invalide ou expirée.',
                },
              },
            ),
          );
        },
      ),
    );
    final api = AlloApi.test(dio: dio);
    expect(
      () => api.get('/users/8/colis'),
      throwsA(
        isA<AlloException>()
            .having((e) => e.isUnauthorized, 'isUnauthorized', true)
            .having((e) => e.message, 'message', 'Session invalide ou expirée.'),
      ),
    );
  });

  test('expired session message is unauthorized even without HTTP 401', () {
    expect(
      const AlloException('unknown', 'Session invalide ou expirée.')
          .isUnauthorized,
      isTrue,
    );
  });

  test('GET 401 refreshes the session then retries', () async {
    var dashboardHits = 0;
    final store = MemoryTokenStore();
    await store.write(ApiConfig.accessTokenKey, 'old');
    await store.write(ApiConfig.refreshTokenKey, 'ref');
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test/api/mobile',
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/refresh') {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'user': {
                      'id': '1',
                      'email': 'a@b.c',
                      'name': 'A',
                      'role': 'admin',
                    },
                    'session': {
                      'access_token': 'new',
                      'refresh_token': 'ref2',
                    },
                  },
                },
              ),
            );
            return;
          }
          dashboardHits += 1;
          if (dashboardHits == 1) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 401,
                data: {
                  'success': false,
                  'error': {
                    'code': 'unauthorized',
                    'message': 'Session invalide ou expirée.',
                  },
                },
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {'ok': true},
              },
            ),
          );
        },
      ),
    );
    final api = AlloApi.test(dio: dio, store: store);
    await api.loadToken();
    final data = await api.get('/dashboard');
    expect(data['ok'], true);
    expect(dashboardHits, 2);
    expect(await api.getAccessToken(), 'new');
  });

  test('GET cache skips a second network call until cleared', () async {
    var hits = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/mobile'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          hits += 1;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {'ok': true},
              },
            ),
          );
        },
      ),
    );
    final api = AlloApi.test(dio: dio, cacheGets: true);
    await api.get('/dashboard');
    await api.get('/dashboard');
    expect(hits, 1);
    api.clearGetCache();
    await api.get('/dashboard');
    expect(hits, 2);
  });
}
