import 'package:allo_coursier_app/services/commande_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_api.dart';

void main() {
  test('paymentSums hits /commandes/payment-sums', () async {
    final api = createMockApi((options) {
      expect(options.path, '/commandes/payment-sums');
      expect(options.queryParameters['shipment'], 'Livré');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: ok({'amount': 120.5, 'deliveryFees': 16}),
      );
    });
    final sums = await CommandeApiService(api).paymentSums(shipment: 'Livré');
    expect(sums.amount, 120.5);
    expect(sums.deliveryFees, 16);
  });
}
