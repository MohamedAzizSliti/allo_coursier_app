import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/services/token_store.dart';
import 'package:dio/dio.dart';

typedef MockHandler = Response Function(RequestOptions options);

AlloApi createMockApi(MockHandler handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/mobile'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, interceptorHandler) {
        interceptorHandler.resolve(handler(options));
      },
    ),
  );
  return AlloApi.test(dio: dio, store: MemoryTokenStore());
}

Map<String, dynamic> ok(Object? data) => {'success': true, 'data': data};

Map<String, dynamic> fail(String code, String message) => {
      'success': false,
      'error': {'code': code, 'message': message},
    };
