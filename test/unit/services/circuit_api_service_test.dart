import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/services/circuit_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveBonLabel prefers API label', () {
    expect(resolveBonLabel({'id': 7, 'label': 'BL0007'}), 'BL0007');
  });

  test('resolveBonLabel formats numeric id when label missing', () {
    expect(resolveBonLabel({'id': 7}), 'BL0007');
    expect(resolveBonLabel({'id': '42'}), 'BL0042');
  });

  test('resolveBonLabel throws when neither label nor id is usable', () {
    expect(
      () => resolveBonLabel({'id': 'x'}),
      throwsA(isA<AlloException>()),
    );
  });
}
