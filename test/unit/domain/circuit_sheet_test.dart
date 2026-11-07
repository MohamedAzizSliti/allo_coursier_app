import 'package:allo_coursier_app/domain/circuit_sheet.dart';
import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:flutter_test/flutter_test.dart';

CommandeModel order({
  String gov = 'Tunis',
  String ville = 'Le Kram',
  String adresse = 'Jardin de Carthage',
  String expediteur = 'Mme Birachted',
  String phone = '22123456',
  String article = '2kg kaak',
  double total = 80,
  String? reason,
}) {
  return CommandeModel(
    id: '100',
    clientNom: 'Sami',
    clientTelephone: phone,
    clientGouvernorat: gov,
    clientAdresse: adresse,
    clientVille: ville,
    produitNom: article,
    produitPrixTotal: total,
    expediteurName: expediteur,
    reason: reason,
  );
}

void main() {
  test('formatBonLivraison pads to at least four digits', () {
    expect(formatBonLivraison(1), 'BL0001');
    expect(formatBonLivraison(42), 'BL0042');
    expect(formatBonLivraison(2749), 'BL2749');
    expect(formatBonLivraison(10000), 'BL10000');
  });

  test('circuit columns match web and omit ville', () {
    expect(
      kCircuitColumns.map((c) => c.label).toList(),
      [
        'Expéditeur',
        'Adresse',
        'Gouv',
        'Téléphone',
        'Total TTC (7% TVA)',
        'Nom Article',
        'Description',
        'Remarques',
      ],
    );
    expect(kCircuitColumns.any((c) => c.label.toLowerCase().contains('ville')), isFalse);
  });

  test('circuitCell uses street address and reason for remarques', () {
    final row = order(reason: 'Client absent', total: 68.5);
    expect(circuitCell(row, 'adresse'), 'Jardin de Carthage');
    expect(circuitCell(row, 'gouv'), 'Tunis');
    expect(circuitCell(row, 'expediteur'), 'Mme Birachted');
    expect(circuitCell(row, 'phone'), '22123456');
    expect(circuitCell(row, 'article'), '2kg kaak');
    expect(circuitCell(row, 'description'), '');
    expect(circuitCell(row, 'remarques'), 'Client absent');
    expect(circuitCell(row, 'total'), '68,500');
  });

  test('formatCircuitAmount uses three decimals with a comma', () {
    expect(formatCircuitAmount(423), '423,000');
    expect(formatCircuitAmount(80), '80,000');
    expect(formatCircuitAmount(0), '0,000');
  });

  test('sortCircuitOrders orders by gouvernorat then ville', () {
    final sorted = sortCircuitOrders([
      order(gov: 'Zaghouan', ville: 'Zaghouan'),
      order(gov: 'Tunis', ville: 'La Marsa'),
      order(gov: 'Tunis', ville: 'Le Kram'),
    ]);
    expect(sorted.map((o) => '${o.clientGouvernorat}/${o.clientVille}').toList(), [
      'Tunis/La Marsa',
      'Tunis/Le Kram',
      'Zaghouan/Zaghouan',
    ]);
  });
}
