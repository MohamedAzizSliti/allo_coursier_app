import 'package:allo_coursier_app/domain/monthly_invoice.dart';
import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:flutter_test/flutter_test.dart';

CommandeModel order({
  required String id,
  required String date,
  String? deliveryDate,
  double prix = 10,
  double frais = 5,
  String status = 'Livrer',
}) {
  return CommandeModel(
    id: id,
    clientNom: 'Client $id',
    produitPrixTotal: prix,
    fraisLivraison: frais,
    status: status,
    date: date,
    deliveryDate: deliveryDate,
  );
}

void main() {
  test('buildMonthlyInvoice sums parcels in the chosen month', () {
    final invoice = buildMonthlyInvoice(
      orders: [
        order(id: '1', date: '2026-11-02T10:00:00.000Z', prix: 20, frais: 8),
        order(
          id: '2',
          date: '2026-10-01T10:00:00.000Z',
          deliveryDate: '2026-11-15T00:00:00.000Z',
          prix: 30,
          frais: 11,
        ),
        order(id: '3', date: '2026-10-20T10:00:00.000Z', prix: 99, frais: 99),
        order(
          id: '4',
          date: '2026-11-05T10:00:00.000Z',
          status: 'En dépôt',
          prix: 5,
          frais: 5,
        ),
      ],
      year: 2026,
      month: 11,
    );

    expect(invoice.rows.map((o) => o.id), ['1', '2', '4']);
    expect(invoice.parcelTotal, 55);
    expect(invoice.feeTotal, 24);
    expect(invoice.deliveredCount, 2);
    expect(invoice.grandTotal, 79);
  });
}
