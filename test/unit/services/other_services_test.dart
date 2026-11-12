import 'package:allo_coursier_app/models/user_model.dart';
import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/services/auth_service.dart';
import 'package:allo_coursier_app/services/dashboard_api_service.dart';
import 'package:allo_coursier_app/services/notification_api_service.dart';
import 'package:allo_coursier_app/services/payment_api_service.dart';
import 'package:allo_coursier_app/services/tarif_api_service.dart';
import 'package:allo_coursier_app/services/transaction_api_service.dart';
import 'package:allo_coursier_app/services/vehicle_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api.dart';

void main() {
  test('UserApiService listUsers hits /users with role', () async {
    final api = createMockApi((options) {
      expect(options.path, '/users');
      expect(options.queryParameters['role'], 'business_client');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok([
          {'id': '1', 'email': 'a@b.c', 'name': 'A', 'role': 'business_client'},
        ]),
      );
    });
    final users = await UserApiService(api).listUsers(role: 'business_client');
    expect(users.single.id, '1');
  });

  test('UserApiService getUser hits /users/:id', () async {
    final api = createMockApi((options) {
      expect(options.path, '/users/203');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'id': '203', 'email': 'a@b.c', 'name': 'M', 'role': 'agent'}),
      );
    });
    final user = await UserApiService(api).getUser('203');
    expect(user.id, '203');
  });

  test('UserApiService updateProfile PATCHes phone and address', () async {
    Map<String, dynamic>? body;
    final api = createMockApi((options) {
      expect(options.method, 'PATCH');
      expect(options.path, '/users/8');
      body = Map<String, dynamic>.from(options.data as Map);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'id': '8',
          'name': 'verona',
          'email': 's@x.tn',
          'role': 'business_client',
          'phone': '22123456',
          'address': 'Zaghouan',
        }),
      );
    });
    const filled = UserModel(
      id: '8',
      email: 's@x.tn',
      name: 'verona',
      role: 'business_client',
      phone: '22123456',
      address: 'Zaghouan',
      city: 'Zaghouan',
      gouvernorat: 'Zaghouan',
      company: 'verona',
      cin: '11111111',
    );
    final saved = await UserApiService(api).updateProfile(filled);
    expect(body!['phone'], '22123456');
    expect(body!['address'], 'Zaghouan');
    expect(saved.phone, '22123456');
    expect(saved.city, 'Zaghouan');
  });

  test('VehicleApiService listVehicles hits /vehicles', () async {
    final api = createMockApi((options) {
      expect(options.path, '/vehicles');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok([
          {'id': '33', 'matricule': 'x', 'model': 'Fiat'},
        ]),
      );
    });
    final rows = await VehicleApiService(api).listVehicles();
    expect(rows.single.id, '33');
  });

  test('VehicleApiService get patch and assign', () async {
    String? lastPath;
    Object? lastData;
    final api = createMockApi((options) {
      lastPath = options.path;
      lastData = options.data;
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'id': '33',
          'matricule': 'x',
          'model': 'Fiat',
          'livreur': '1629',
        }),
      );
    });
    final v = await VehicleApiService(api).getVehicle('33');
    expect(v.id, '33');
    await VehicleApiService(api).updateVehicle('33', {'model': 'Fiat'});
    await VehicleApiService(api).assignLivreur('33', '1629');
    expect(lastPath, '/vehicles/33/assign');
    expect((lastData as Map)['livreurId'], '1629');
  });

  test('VehicleApiService createVehicle posts matricule and model only', () async {
    Object? lastData;
    final api = createMockApi((options) {
      lastData = options.data;
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'id': '33', 'matricule': '123 TU', 'model': 'Fiat'}),
      );
    });
    await VehicleApiService(api).createVehicle(matricule: '123 TU', model: 'Fiat');
    final body = lastData as Map;
    expect(body['matricule'], '123 TU');
    expect(body['model'], 'Fiat');
    expect(body.containsKey('livreur'), isFalse);
    expect(body.containsKey('livreurId'), isFalse);
  });

  test('DashboardData reads both counts and insights', () {
    final data = DashboardData.fromJson({
      'counts': {'En dépôt': 4, 'business_clients': 9},
      'insights': {'livre': 2, 'annuler': 1},
      'totals': {'totalPrix': 50},
    });
    expect(data.enDepot, 4);
    expect(data.livre, 2);
    expect(data.annuler, 1);
    expect(data.businessClients, 9);
    expect(data.totals['totalPrix'], 50);
  });

  test('DashboardData ignores invalid counts without throwing', () {
    final data = DashboardData.fromJson({
      'counts': ['bad'],
      'totals': 'nope',
      'insights': {'livre': '2'},
      'commandesByDate': {'x': 1},
    });
    expect(data.livre, 2);
    expect(data.enDepot, 0);
    expect(data.commandesByDate, isEmpty);
  });

  test('getDashboardData does not chain extra list calls after a server error', () async {
    final api = createMockApi((options) {
      if (options.path == '/dashboard') {
        return Response(
          requestOptions: options,
          statusCode: 500,
          data: {
            'success': false,
            'error': {'code': 'unknown', 'message': 'boom'},
          },
        );
      }
      throw StateError('unexpected extra request ${options.path}');
    });

    await expectLater(
      DashboardApiService(api).getDashboardData(),
      throwsA(isA<AlloException>()),
    );
  });

  test('getDashboardData falls back to users and vehicles on 404', () async {
    final api = createMockApi((options) {
      if (options.path == '/dashboard') {
        return Response(
          requestOptions: options,
          statusCode: 404,
          data: {
            'success': false,
            'error': {'code': 'not_found', 'message': 'missing'},
          },
        );
      }
      if (options.path == '/users') {
        final role = options.queryParameters['role'];
        final rows = role == 'business_client'
            ? [
                {'id': '1', 'role': 'business_client'},
              ]
            : [
                {'id': '2', 'role': 'delivery_person'},
              ];
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: ok(rows),
        );
      }
      if (options.path == '/vehicles') {
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: ok([
            {'id': '33'},
          ]),
        );
      }
      throw StateError('unexpected path ${options.path}');
    });

    final data = await DashboardApiService(api).getDashboardData();
    expect(data.businessClients, 1);
    expect(data.deliveryPersons, 1);
    expect(data.vehicles, 1);
    expect(data.enDepot, 0);
  });

  test('DashboardData reads top-level entity keys', () {
    final data = DashboardData.fromJson({
      'business_clients': 3,
      'delivery_persons': 2,
      'vehicles': 1,
      'commandes_today': 7,
    });
    expect(data.businessClients, 3);
    expect(data.deliveryPersons, 2);
    expect(data.vehicles, 1);
    expect(data.commandesToday, 7);
  });

  test('PaymentApiService confirm and withdraw bodies', () async {
    Map<String, dynamic>? last;
    final api = createMockApi((options) {
      last = Map<String, dynamic>.from(options.data as Map);
      return Response(requestOptions: options, statusCode: 200, data: ok({}));
    });
    await PaymentApiService(api).confirmPayments(['1', '2']);
    expect(last!['orderIds'], ['1', '2']);
    expect(last!.containsKey('amount'), isFalse);
    await PaymentApiService(api).confirmPayments(['1'], amount: 12.5);
    expect(last!['orderIds'], ['1']);
    expect(last!['amount'], 12.5);
    await PaymentApiService(api).requestWithdrawal(expediteurId: '203');
    expect(last!['expediteurId'], '203');
    expect(last!.containsKey('amount'), isFalse);
  });

  test('PaymentApiService getPayoutSums hits /payments/payout-sums', () async {
    Map<String, dynamic>? query;
    final api = createMockApi((options) {
      expect(options.method, 'GET');
      expect(options.path, '/payments/payout-sums');
      query = Map<String, dynamic>.from(options.queryParameters);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'montant_paye': 756,
          'montant_reste': 12.5,
          'unpaidCount': 2,
          'paidCount': 1,
        }),
      );
    });
    final sums = await PaymentApiService(api).getPayoutSums(expediteurId: '203');
    expect(query!['expediteurId'], '203');
    expect(sums.montantPaye, 756);
    expect(sums.montantReste, 12.5);
    expect(sums.unpaidCount, 2);
    expect(sums.paidCount, 1);
  });

  test('Notification and tarif and transaction list paths', () async {
    final paths = <String>[];
    final api = createMockApi((options) {
      paths.add(options.path);
      return Response(requestOptions: options, statusCode: 200, data: ok([]));
    });
    await NotificationApiService(api).listNotifications();
    await TarifApiService(api).listTarifs();
    await TransactionApiService(api).listTransactions();
    expect(paths, ['/notifications', '/tarifs', '/transactions']);
  });

  test('registerPushToken posts /push-tokens and skips empty', () async {
    final paths = <String>[];
    final api = createMockApi((options) {
      paths.add(options.path);
      expect(options.data['token'], 'abc');
      expect(options.data['platform'], 'android');
      return Response(requestOptions: options, statusCode: 200, data: ok({}));
    });
    final svc = NotificationApiService(api);
    await svc.registerPushTokenIfAvailable();
    await svc.registerPushTokenIfAvailable('abc');
    expect(paths, ['/push-tokens']);
  });

  test('deleteNotification hits DELETE /notifications/:id', () async {
    String? method;
    String? path;
    final api = createMockApi((options) {
      method = options.method;
      path = options.path;
      return Response(requestOptions: options, statusCode: 200, data: ok({}));
    });
    await NotificationApiService(api).deleteNotification('9');
    expect(method, 'DELETE');
    expect(path, '/notifications/9');
  });

  test('NotificationItem reads camelCase API fields', () {
    final item = NotificationItem.fromJson({
      'id': 9,
      'title': 'Nouvelle Commande',
      'body': 'Une nouvelle commande a été placée!',
      'isRead': true,
      'sentAt': '2026-10-06T08:00:00.000Z',
      'orderId': '83678',
    });
    expect(item.id, '9');
    expect(item.isRead, isTrue);
    expect(item.orderId, '83678');
    expect(item.sentAt.toUtc().toIso8601String(), '2026-10-06T08:00:00.000Z');
  });

  test('markRead posts /notifications/:id/read', () async {
    String? method;
    String? path;
    final api = createMockApi((options) {
      method = options.method;
      path = options.path;
      return Response(requestOptions: options, statusCode: 200, data: ok({}));
    });
    await NotificationApiService(api).markRead('9');
    expect(method, 'POST');
    expect(path, '/notifications/9/read');
  });

  test('DashboardData reads Livré Payé Tous and totals', () {
    final data = DashboardData.fromJson({
      'counts': {
        'Tous': 82445,
        'En cours': 103,
        'Livré': 18295,
        'Payé': 48296,
      },
      'insights': {'weekDeliveries': 6},
      'totals': {'expediteurs': 1328, 'livreurs': 32, 'vehicles': 36},
    });
    expect(data.tous, 82445);
    expect(data.livre, 18295);
    expect(data.paye, 48296);
    expect(data.weekDeliveries, 6);
    expect(data.businessClients, 1328);
    expect(data.deliveryPersons, 32);
    expect(data.vehicles, 36);
  });

  test('DashboardData reads enRouteAmount and topPlaces', () {
    final data = DashboardData.fromJson({
      'counts': {'Tous': 10},
      'insights': {
        'weekDeliveries': 6,
        'enRouteAmount': 387600.5,
        'topPlaces': [
          {'name': 'Tunis', 'count': 17981},
          {'name': 'Sfax', 'count': 900},
        ],
      },
      'totals': {'expediteurs': 1, 'livreurs': 1, 'vehicles': 1},
    });
    expect(data.enRouteAmount, 387600.5);
    expect(data.topPlaces, [
      {'name': 'Tunis', 'count': 17981},
      {'name': 'Sfax', 'count': 900},
    ]);
  });
}
