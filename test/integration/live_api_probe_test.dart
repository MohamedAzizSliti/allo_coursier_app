import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unauthenticated probe of the production mobile API.
/// Records existence (not 404) vs missing routes.
void main() {
  const base = 'https://allo-coursier.vercel.app/api/mobile';

  test('live routes exist or are documented as missing', () async {
    final dio = Dio(BaseOptions(
      baseUrl: base,
      validateStatus: (_) => true,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ));

    Future<int> hit(String method, String path) async {
      final res = await dio.request(
        path,
        options: Options(method: method, contentType: 'application/json'),
        data: method == 'GET' || method == 'DELETE' ? null : {},
      );
      return res.statusCode ?? 0;
    }

    final results = <String, int>{
      'POST /auth/login': await hit('POST', '/auth/login'),
      'GET /auth/me': await hit('GET', '/auth/me'),
      'POST /auth/password': await hit('POST', '/auth/password'),
      'PATCH /auth/password': await hit('PATCH', '/auth/password'),
      'GET /commandes': await hit('GET', '/commandes'),
      'GET /commandes/1': await hit('GET', '/commandes/1'),
      'PATCH /commandes/1': await hit('PATCH', '/commandes/1'),
      'DELETE /commandes/1': await hit('DELETE', '/commandes/1'),
      'POST /commandes/1/pay': await hit('POST', '/commandes/1/pay'),
      'GET /colis-du-jour': await hit('GET', '/colis-du-jour'),
      'GET /users/1': await hit('GET', '/users/1'),
      'GET /vehicles/1': await hit('GET', '/vehicles/1'),
      'PATCH /vehicles/1': await hit('PATCH', '/vehicles/1'),
      'POST /vehicles/1/assign': await hit('POST', '/vehicles/1/assign'),
      'GET /transactions': await hit('GET', '/transactions'),
      'GET /payments': await hit('GET', '/payments'),
      'POST /scanner/lookup': await hit('POST', '/scanner/lookup'),
      'GET /scanner/lookup': await hit('GET', '/scanner/lookup'),
      'PATCH /notifications/1': await hit('PATCH', '/notifications/1'),
      'POST /notifications/1/read': await hit('POST', '/notifications/1/read'),
      'POST /push-tokens': await hit('POST', '/push-tokens'),
      'POST /reclamations': await hit('POST', '/reclamations'),
      'POST /auth/forgot-password': await hit('POST', '/auth/forgot-password'),
      'GET /commandes/1/history': await hit('GET', '/commandes/1/history'),
    };

    expect(results['POST /auth/login'], isNot(404));
    expect(results['GET /transactions'], isNot(404));
    expect(results['GET /users/1'], isNot(404));
    expect(results['GET /vehicles/1'], isNot(404));
    expect(results['GET /payments'], 404);
    expect(results['GET /scanner/lookup'], 405);
    expect(results['PATCH /auth/password'], 405);
    expect(results['PATCH /notifications/1'], 405);
    expect(results['POST /reclamations'], 404);
    expect(results['POST /auth/forgot-password'], 404);
    expect(results['GET /commandes/1/history'], 404);
    expect(results['GET /colis-du-jour'], isNot(404));
    expect(results['POST /commandes/1/pay'], isNot(404));
    expect(results['PATCH /commandes/1'], isNot(404));
    expect(results['POST /vehicles/1/assign'], isNot(404));
    expect(results['POST /notifications/1/read'], isNot(404));
  }, skip: const bool.fromEnvironment('SKIP_LIVE_API', defaultValue: false));
}
