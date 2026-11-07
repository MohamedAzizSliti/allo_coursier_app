import 'package:allo_coursier_app/domain/delivery_fee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nearby gouvernorats pay 8 DT under 10 kg', () {
    expect(deliveryFeeFor(gouvernorat: 'Zaghouan', kg: 2), 8);
    expect(deliveryFeeFor(gouvernorat: 'Tunis', kg: 10), 8);
  });

  test('remote gouvernorats pay 9 DT under 10 kg', () {
    expect(deliveryFeeFor(gouvernorat: 'Tataouine', kg: 3), 9);
    expect(deliveryFeeFor(gouvernorat: 'Gabes', kg: 1), 9);
  });

  test('parcels over 10 kg cost 1 DT per kg', () {
    expect(deliveryFeeFor(gouvernorat: 'Tunis', kg: 12), 12);
    expect(deliveryFeeFor(gouvernorat: 'Medenine', kg: 15.5), 15.5);
  });

  test('référentiel tarif wins over name table for light parcels', () {
    expect(
      deliveryFeeFor(gouvernorat: 'Béja', kg: 2, tarif: 8),
      8,
    );
    expect(
      deliveryFeeFor(gouvernorat: 'Atlantis', kg: 3, tarif: 9),
      9,
    );
  });
}
