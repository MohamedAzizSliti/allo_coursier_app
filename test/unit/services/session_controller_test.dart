import 'package:allo_coursier_app/config/api_config.dart';
import 'package:allo_coursier_app/models/user_model.dart';
import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/services/session_controller.dart';
import 'package:allo_coursier_app/services/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api.dart' as mock;

void main() {
  test('hydrate restores cached role without calling the network', () async {
    final store = MemoryTokenStore();
    await store.write(ApiConfig.accessTokenKey, 'tok');
    await store.write(ApiConfig.userRoleKey, 'business_client');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/mobile'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          fail('hydrate must not call ${options.path}');
        },
      ),
    );

    final session = SessionController(api: AlloApi.test(dio: dio, store: store));
    await session.hydrate();

    expect(session.ready, isTrue);
    expect(session.role, 'business_client');
    expect(session.isSignedIn, isTrue);
  });

  test('network error during validate keeps the cached session', () async {
    final store = MemoryTokenStore();
    await store.write(ApiConfig.accessTokenKey, 'tok');
    await store.write(ApiConfig.userRoleKey, 'agent');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/mobile'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );

    final session = SessionController(api: AlloApi.test(dio: dio, store: store));
    await session.hydrate();
    await session.validateInBackground();

    expect(session.role, 'agent');
    expect(await store.read(ApiConfig.accessTokenKey), 'tok');
  });

  test('401 during validate signs the user out', () async {
    final sessionStore = MemoryTokenStore();
    await sessionStore.write(ApiConfig.accessTokenKey, 'tok');
    await sessionStore.write(ApiConfig.userRoleKey, 'admin');
    final sessionApi = AlloApi.test(
      dio: Dio(BaseOptions(baseUrl: 'https://example.test/api/mobile'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: mock.fail('unauthorized', 'expired'),
                ),
              );
            },
          ),
        ),
      store: sessionStore,
    );

    final session = SessionController(api: sessionApi);
    await session.hydrate();
    expect(session.isSignedIn, isTrue);

    await session.validateInBackground();
    expect(session.isSignedIn, isFalse);
    expect(await sessionStore.read(ApiConfig.accessTokenKey), isNull);
  });

  test('session expired envelope during validate signs the user out', () async {
    final sessionStore = MemoryTokenStore();
    await sessionStore.write(ApiConfig.accessTokenKey, 'tok');
    await sessionStore.write(ApiConfig.userRoleKey, 'business_client');
    final sessionApi = AlloApi.test(
      dio: Dio(
        BaseOptions(
          baseUrl: 'https://example.test/api/mobile',
          validateStatus: (status) => status != null && status < 500,
        ),
      )..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: mock.fail('unknown', 'Session invalide ou expirée.'),
                ),
              );
            },
          ),
        ),
      store: sessionStore,
    );

    final session = SessionController(api: sessionApi);
    await session.hydrate();
    expect(session.isSignedIn, isTrue);

    await session.validateInBackground();
    expect(session.isSignedIn, isFalse);
    expect(await sessionStore.read(ApiConfig.accessTokenKey), isNull);
  });

  test('rememberProfile keeps sender fields for the profile screen', () async {
    final session = SessionController(
      api: AlloApi.test(
        dio: Dio(BaseOptions(baseUrl: 'https://example.test/api/mobile')),
        store: MemoryTokenStore(),
      ),
    );
    const user = UserModel(
      id: '8',
      email: '',
      name: 'verona',
      role: 'business_client',
      phone: '55555555',
      city: 'zaghouan',
    );
    await session.signedIn(user.role, user: user);
    session.rememberProfile(user.copyWith(company: 'verona'));

    expect(session.user?.phone, '55555555');
    expect(session.user?.company, 'verona');
    expect(session.profileIncomplete, isFalse);
  });

  test('unknown stored role is treated as logged out', () async {
    final store = MemoryTokenStore();
    await store.write(ApiConfig.accessTokenKey, 'tok');
    await store.write(ApiConfig.userRoleKey, 'guest');
    final api = AlloApi.test(
      dio: Dio(BaseOptions(baseUrl: 'https://example.test/api/mobile')),
      store: store,
    );
    final session = SessionController(api: api);
    await session.hydrate();
    expect(session.isSignedIn, isFalse);
    expect(session.ready, isTrue);
  });
}
