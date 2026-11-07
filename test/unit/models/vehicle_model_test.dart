import 'package:allo_coursier_app/models/vehicle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses livreur id from string, number, or nested map', () {
    expect(
      VehicleModel.fromJson({
        'id': '1',
        'matricule': 'A',
        'model': 'B',
        'livreur': 'u-9',
      }).livreur,
      'u-9',
    );
    expect(
      VehicleModel.fromJson({
        'id': '1',
        'matricule': 'A',
        'model': 'B',
        'livreur': 12,
      }).livreur,
      '12',
    );
    expect(
      VehicleModel.fromJson({
        'id': '1',
        'matricule': 'A',
        'model': 'B',
        'livreur': {'id': 'drv-3'},
      }).livreur,
      'drv-3',
    );
  });

  test('treats empty livreur as null', () {
    expect(
      VehicleModel.fromJson({
        'id': '1',
        'matricule': 'A',
        'model': 'B',
        'livreur': '  ',
      }).livreur,
      isNull,
    );
  });
}
