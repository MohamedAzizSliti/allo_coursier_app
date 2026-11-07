import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/services/auth_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api.dart' hide fail;
import '../../helpers/mock_api.dart' as mock;

void main() {
  test('login unwraps user and stores token', () async {
    final api = createMockApi((options) {
      expect(options.path, '/auth/login');
      expect(options.method, 'POST');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'session': {
            'access_token': 'acc',
            'refresh_token': 'ref',
          },
          'user': {
            'id': '203',
            'email': 'a@b.c',
            'name': 'Mouna',
            'role': 'admin',
          },
        }),
      );
    });

    final user = await AuthApiService(api).login('a@b.c', 'secret');
    expect(user.id, '203');
    expect(user.role, 'admin');
    expect(await api.getAccessToken(), 'acc');
  });

  test('login accepts live user+session envelope', () async {
    final api = createMockApi((options) {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'success': true,
          'data': {
            'user': {
              'id': '20',
              'uid': '7',
              'email': 'rabeb@allocoursier.tn',
              'name': 'Rabeb',
              'role': 'admin',
              'phone': null,
              'address': null,
              'fcm_token': null,
              'montant_disponible': 0,
              'vehicleId': null,
            },
            'session': {
              'access_token': 'live-access',
              'refresh_token': 'live-refresh',
              'expires_at': 1791641418,
              'expires_in': 3600,
            },
          },
        },
      );
    });

    final user = await AuthApiService(api).login('rabeb@allocoursier.tn', '12345678');
    expect(user.id, '20');
    expect(user.email, 'rabeb@allocoursier.tn');
    expect(user.role, 'admin');
    expect(await api.getAccessToken(), 'live-access');
  });

  test('login 401 envelope becomes AlloException', () async {
    final api = createMockApi((options) {
      return Response(
        requestOptions: options,
        statusCode: 401,
        data: mock.fail('invalid_credentials', 'Email ou mot de passe incorrect'),
      );
    });

    expect(
      () => AuthApiService(api).login('rabebb@allocoursier.tn', 'wrong'),
      throwsA(
        isA<AlloException>()
            .having((e) => e.isUnauthorized, 'isUnauthorized', true)
            .having((e) => e.message, 'message', 'Email ou mot de passe incorrect'),
      ),
    );
  });

  test('changePassword uses POST /auth/password', () async {
    String? method;
    String? path;
    Map<String, dynamic>? body;
    final api = createMockApi((options) {
      method = options.method;
      path = options.path;
      body = Map<String, dynamic>.from(options.data as Map);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({}),
      );
    });

    final signInAgain = await AuthApiService(api).changePassword('old', 'newpass');
    expect(signInAgain, isFalse);
    expect(method, 'POST');
    expect(path, '/auth/password');
    expect(body!['currentPassword'], 'old');
    expect(body!['newPassword'], 'newpass');
    expect(body!['current_password'], 'old');
    expect(body!['new_password'], 'newpass');
  });

  test('changePassword returns signInAgain from the server', () async {
    final api = createMockApi((options) {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'ok': true, 'signInAgain': true}),
      );
    });
    expect(await AuthApiService(api).changePassword('22123456', 'nouveau123'), isTrue);
  });

  test('getCurrentUser hits GET /auth/me', () async {
    final api = createMockApi((options) {
      if (options.path.startsWith('/users/')) {
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: ok({
            'id': '1',
            'email': 'a@b.c',
            'name': 'A',
            'role': 'agent',
          }),
        );
      }
      expect(options.path, '/auth/me');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'id': '1',
          'email': 'a@b.c',
          'name': 'A',
          'role': 'agent',
        }),
      );
    });
    final user = await AuthApiService(api).getCurrentUser();
    expect(user.role, 'agent');
  });

  test('getCurrentUser unwraps nested user from GET /auth/me', () async {
    final api = createMockApi((options) {
      if (options.path.startsWith('/users/')) {
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: ok({
            'id': '8',
            'name': 'verona',
            'role': 'business_client',
            'montant_disponible': 42.5,
          }),
        );
      }
      expect(options.path, '/auth/me');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'user': {
            'id': '8',
            'email': '',
            'name': 'verona',
            'role': 'business_client',
            'phone': null,
            'address': null,
          },
        }),
      );
    });
    final user = await AuthApiService(api).getCurrentUser();
    expect(user.id, '8');
    expect(user.name, 'verona');
    expect(user.role, 'business_client');
    expect(user.montantDisponible, 42.5);
  });

  test('getCurrentUser fills balance from GET /users/:id when /auth/me omits it', () async {
    final api = createMockApi((options) {
      if (options.path == '/users/8') {
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: ok({
            'id': '8',
            'name': 'verona',
            'role': 'business_client',
            'montant_disponible': '18.75',
          }),
        );
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'id': '8',
          'name': 'verona',
          'role': 'business_client',
        }),
      );
    });
    final user = await AuthApiService(api).getCurrentUser();
    expect(user.montantDisponible, 18.75);
  });

  test('logout hits POST /auth/logout', () async {
    String? method;
    String? path;
    final api = createMockApi((options) {
      method = options.method;
      path = options.path;
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({}),
      );
    });

    await AuthApiService(api).logout();
    expect(method, 'POST');
    expect(path, '/auth/logout');
  });
}
