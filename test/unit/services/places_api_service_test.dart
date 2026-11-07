import 'package:allo_coursier_app/services/places_api_service.dart';
import 'package:allo_coursier_app/services/supabase_rest.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api.dart';

SupabaseRest _mockSupabase(MockHandler handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/rest/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, interceptorHandler) {
        interceptorHandler.resolve(handler(options));
      },
    ),
  );
  return SupabaseRest(
    dio: dio,
    accessToken: () async => 'tok',
  );
}

void main() {
  test('listGouvernorats reads helpdesk_ticket_category via Supabase', () async {
    final supabase = _mockSupabase((options) {
      expect(options.path, '/helpdesk_ticket_category');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: [
          {
            'id': 1,
            'name': {'fr_FR': 'Tunis'},
            'tarif': 8,
            'active': true,
          },
        ],
      );
    });
    final rows = await PlacesApiService(supabase: supabase).listGouvernorats();
    expect(rows.single.label, 'Tunis');
    expect(rows.single.tarif, 8);
    expect(rows.single.gouvernorat, 'Tunis');
  });

  test('listVilles pages ville table via Supabase', () async {
    final supabase = _mockSupabase((options) {
      expect(options.path, '/ville');
      expect(options.queryParameters['category_id'], 'eq.1');
      expect(options.queryParameters['limit'], 25);
      return Response(
        requestOptions: options,
        statusCode: 200,
        headers: Headers.fromMap({
          'content-range': ['0-0/1'],
        }),
        data: [
          {
            'id': 9,
            'name': 'Zaghouan',
            'category_id': 1,
            'secteurs_id': null,
            'ordre': 2,
          },
        ],
      );
    });
    final page = await PlacesApiService(supabase: supabase).listVilles(categoryId: '1');
    expect(page.total, 1);
    expect(page.rows.single.name, 'Zaghouan');
    expect(page.rows.single.categoryId, '1');
  });

  test('saveSecteur posts then patches mobile API', () async {
    var calls = 0;
    final api = createMockApi((options) {
      calls += 1;
      if (calls == 1) {
        expect(options.method, 'POST');
        expect(options.path, '/places/secteurs');
        return Response(
          requestOptions: options,
          statusCode: 201,
          data: ok({'id': '4', 'name': 'Nord', 'ordre': 1}),
        );
      }
      expect(options.method, 'PATCH');
      expect(options.path, '/places/secteurs/4');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'id': '4', 'name': 'Nord Est', 'ordre': 2}),
      );
    });
    final service = PlacesApiService(api: api, supabase: _mockSupabase((o) {
      return Response(requestOptions: o, statusCode: 200, data: []);
    }));
    final created = await service.saveSecteur(name: 'Nord', ordre: 1);
    expect(created.id, '4');
    final updated = await service.saveSecteur(
      id: '4',
      name: 'Nord Est',
      ordre: 2,
    );
    expect(updated.name, 'Nord Est');
  });

  test('renameGouvernorat patches mobile API', () async {
    final api = createMockApi((options) {
      expect(options.method, 'PATCH');
      expect(options.path, '/places/gouvernorats/3');
      expect((options.data as Map)['gouvernorat'], 'Gabes');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'id': '3', 'gouvernorat': 'Gabes'}),
      );
    });
    await PlacesApiService(
      api: api,
      supabase: _mockSupabase((o) => Response(requestOptions: o, statusCode: 200, data: [])),
    ).renameGouvernorat('3', 'Gabes');
  });
}
