import 'package:allo_coursier_app/models/user_model.dart';
import 'package:allo_coursier_app/services/commande_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api.dart';

void main() {
  Map<String, dynamic> colis() => {
        'id': '83678',
        'client_nom': 'Ali',
        'status': 'En cours',
        'produit_prix_total': 10,
      };

  test('listCommandesPage maps Livrer to Livré', () async {
    final api = createMockApi((options) {
      expect(options.path, '/commandes');
      expect(options.queryParameters['shipment'], 'Livré');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'rows': [], 'total': 0}),
      );
    });
    await CommandeApiService(api).listCommandesPage(shipment: 'Livrer');
  });

  test('listCommandesPage sends shipment pagination', () async {
    final api = createMockApi((options) {
      expect(options.path, '/commandes');
      expect(options.queryParameters['shipment'], 'En route');
      expect(options.queryParameters['page'], 0);
      expect(options.queryParameters['pageSize'], 25);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'rows': [colis()],
          'total': 3829,
        }),
      );
    });
    final page = await CommandeApiService(api).listCommandesPage(shipment: 'En route');
    expect(page.rows.single.displayId, 'HT83678');
    expect(page.total, 3829);
  });

  test('scannerLookup posts id and reads found/order', () async {
    final api = createMockApi((options) {
      expect(options.method, 'POST');
      expect(options.path, '/scanner/lookup');
      expect(options.data['id'], '83678');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'found': true, 'order': colis()}),
      );
    });
    final c = await CommandeApiService(api).scannerLookup('HT83678');
    expect(c.id, '83678');
  });

  test('confirmColis posts vehicleId and deliveryDate', () async {
    final api = createMockApi((options) {
      expect(options.path, '/commandes/1/confirm-colis');
      expect(options.data['vehicleId'], '33');
      expect(options.data['deliveryDate'], '2026-10-03');
      expect(options.data.containsKey('livreur_id'), isFalse);
      return Response(requestOptions: options, statusCode: 200, data: ok(colis()));
    });
    await CommandeApiService(api).confirmColis(
      '1',
      vehicleId: '33',
      deliveryDate: '2026-10-03',
    );
  });

  test('claim deliver annuler relivrer hit transition paths', () async {
    final paths = <String>[];
    Map<String, dynamic>? lastBody;
    final api = createMockApi((options) {
      paths.add('${options.method} ${options.path}');
      if (options.data is Map) {
        lastBody = Map<String, dynamic>.from(options.data as Map);
      }
      return Response(requestOptions: options, statusCode: 200, data: ok(colis()));
    });
    final svc = CommandeApiService(api);
    await svc.claim('1');
    await svc.deliver('1');
    await svc.annuler('1', reason: 'absent');
    await svc.relivrer('1', reason: 'retry');
    expect(lastBody!['reason'], 'retry');
    await svc.relivrer('1', deliveryDate: '2026-10-09', vehicleId: '33');
    expect(lastBody!['deliveryDate'], '2026-10-09');
    expect(lastBody!['vehicleId'], '33');
    await svc.pay('1');
    expect(paths, [
      'POST /commandes/1/claim',
      'POST /commandes/1/deliver',
      'POST /commandes/1/annuler',
      'POST /commandes/1/relivrer',
      'POST /commandes/1/relivrer',
      'POST /commandes/1/pay',
    ]);
  });

  test('staff can assign a driver then put the parcel en route', () async {
    final paths = <String>[];
    Map<String, dynamic>? lastBody;
    final api = createMockApi((options) {
      paths.add('${options.method} ${options.path}');
      if (options.data is Map) {
        lastBody = Map<String, dynamic>.from(options.data as Map);
      }
      return Response(requestOptions: options, statusCode: 200, data: ok(colis()));
    });
    final svc = CommandeApiService(api);
    await svc.assignDelivery('83682', livreurId: '877');
    expect(lastBody, {'livreur_id': '877'});
    await svc.staffClaim('83682', vehicleId: '29');
    expect(lastBody, {'vehicleId': '29'});
    expect(paths, [
      'PATCH /commandes/83682',
      'POST /commandes/83682/claim',
    ]);
  });

  test('getCommande hits /commandes/:id', () async {
    final api = createMockApi((options) {
      expect(options.path, '/commandes/83678');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok(colis()),
      );
    });
    final row = await CommandeApiService(api).getCommande('83678');
    expect(row.id, '83678');
  });

  test('createCommande posts /commandes', () async {
    final api = createMockApi((options) {
      expect(options.method, 'POST');
      expect(options.path, '/commandes');
      expect(options.data['client_nom'], 'Ali');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok(colis()),
      );
    });
    final row = await CommandeApiService(api).createCommande({'client_nom': 'Ali'});
    expect(row.clientNom, 'Ali');
  });

  test('listCommandesForUserPage hits /users/:id/colis with sum', () async {
    final api = createMockApi((options) {
      expect(options.path, '/users/203/colis');
      expect(options.queryParameters['page'], 0);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'rows': [colis()],
          'total': 567,
          'sum': 46249,
        }),
      );
    });
    final page = await CommandeApiService(api).listCommandesForUserPage('203');
    expect(page.rows, hasLength(1));
    expect(page.total, 567);
    expect(page.sum, 46249);
  });

  test('shipmentTotalsForUser asks each board filter with pageSize 1', () async {
    final shipments = <String?>[];
    final api = createMockApi((options) {
      expect(options.path, '/users/8/colis');
      expect(options.queryParameters['pageSize'], 1);
      shipments.add(options.queryParameters['shipment'] as String?);
      final total = options.queryParameters['shipment'] == null ? 120 : 3;
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'rows': const [], 'total': total}),
      );
    });
    final totals = await CommandeApiService(api).shipmentTotalsForUser('8');
    expect(shipments, containsAll([
      null,
      'En cours',
      'En dépôt',
      'En route',
      'Relivrer',
      'Livré',
      'Payé',
      'Annuler',
    ]));
    expect(shipments, hasLength(8));
    expect(totals['Tous'], 120);
    expect(totals['En cours'], 3);
    expect(totals['Livré'], 3);
  });

  test('unpaidDeliveredTotalForUser filters Livré and skips paid rows', () async {
    final api = createMockApi((options) {
      expect(options.path, '/users/8/colis');
      expect(options.queryParameters['shipment'], 'Livré');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'rows': [
            {'id': '1', 'status': 'Livrer', 'paid': false, 'produit_prix_total': 20},
            {'id': '2', 'status': 'Livré', 'paid': false, 'produit_prix_total': 10},
            {'id': '3', 'status': 'Livrer', 'paid': true, 'produit_prix_total': 50},
          ],
          'total': 3,
        }),
      );
    });
    final total = await CommandeApiService(api).unpaidDeliveredTotalForUser('8');
    expect(total, 30);
  });

  test('listColisDuJour hits /colis-du-jour', () async {
    final api = createMockApi((options) {
      expect(options.path, '/colis-du-jour');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'rows': [colis()], 'total': 0}),
      );
    });
    final page = await CommandeApiService(api).listColisDuJour();
    expect(page.total, 0);
    expect(page.rows, hasLength(1));
  });

  test('listAssignedParcels loads multi-day En route from /commandes', () async {
    final api = createMockApi((options) {
      expect(options.path, '/commandes');
      expect(options.queryParameters['shipment'], 'En route');
      expect(options.queryParameters['vehicleId'], '29');
      expect(options.queryParameters.containsKey('deliveryFrom'), isFalse);
      expect(options.queryParameters.containsKey('deliveryTo'), isFalse);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'rows': [
            {
              'id': '1',
              'livreur_id': '824',
              'vehicle_id': '29',
              'status': 'En route',
              'delivery_date': '2026-10-25',
            },
            {
              'id': '2',
              'livreur_id': '99',
              'vehicle_id': '33',
              'status': 'En route',
            },
          ],
          'total': 2,
        }),
      );
    });
    const driver = UserModel(
      id: '824',
      email: '',
      name: 'Ahmed',
      role: 'delivery_person',
      vehicleId: '29',
    );
    final rows = await CommandeApiService(api).listAssignedParcels(
      driver,
      shipment: 'En route',
    );
    expect(rows.map((c) => c.id), ['1']);
  });

  test('listAssignedParcels home loads open circuit colis without a today date filter',
      () async {
    final shipments = <String?>[];
    final api = createMockApi((options) {
      expect(options.path, '/commandes');
      final shipment = options.queryParameters['shipment'] as String?;
      shipments.add(shipment);
      if (shipment == 'En route' ||
          shipment == 'Relivrer' ||
          shipment == 'En dépôt') {
        expect(options.queryParameters.containsKey('deliveryFrom'), isFalse);
      }
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'rows': [
            {
              'id': '83690',
              'livreur_id': '824',
              'vehicle_id': '29',
              'status': shipment ?? 'En route',
            },
          ],
          'total': 1,
        }),
      );
    });
    const driver = UserModel(
      id: '824',
      email: '',
      name: 'Ahmed',
      role: 'delivery_person',
      vehicleId: '29',
    );
    final rows = await CommandeApiService(api).listAssignedParcels(driver);
    expect(shipments, containsAll(['En route', 'Relivrer', 'En dépôt']));
    expect(rows.map((c) => c.id), contains('83690'));
  });

  test('listAssignedColisDuJour keeps parcels on the driver vehicle', () async {
    final api = createMockApi((options) {
      expect(options.path, '/colis-du-jour');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({
          'rows': [
            {'id': '1', 'livreur_id': '7', 'status': 'En route'},
            {'id': '2', 'livreur_id': '99', 'status': 'En route'},
            {'id': '3', 'vehicle_id': '33', 'status': 'Livrer'},
          ],
          'total': 3,
        }),
      );
    });
    const driver = UserModel(
      id: '1629',
      uid: '7',
      email: '',
      name: 'Ali',
      role: 'delivery_person',
      vehicleId: '33',
    );
    final rows = await CommandeApiService(api).listAssignedColisDuJour(driver);
    expect(rows.map((c) => c.id), ['3']);
  });

  test('listAssignedParcels is empty when the driver has no vehicle', () async {
    var called = false;
    final api = createMockApi((options) {
      called = true;
      return Response(requestOptions: options, statusCode: 200, data: ok({'rows': [], 'total': 0}));
    });
    const driver = UserModel(
      id: '824',
      email: '',
      name: 'Ahmed',
      role: 'delivery_person',
    );
    final rows = await CommandeApiService(api).listAssignedParcels(driver);
    expect(called, isFalse);
    expect(rows, isEmpty);
  });

  test('patch and delete commandes', () async {
    String? method;
    String? path;
    final api = createMockApi((options) {
      method = options.method;
      path = options.path;
      return Response(requestOptions: options, statusCode: 200, data: ok(colis()));
    });
    await CommandeApiService(api).patchCommande('83678', {'status': 'En dépôt'});
    expect(method, 'PATCH');
    expect(path, '/commandes/83678');
    await CommandeApiService(api).deleteCommande('83678');
    expect(method, 'DELETE');
    expect(path, '/commandes/83678');
  });
}
