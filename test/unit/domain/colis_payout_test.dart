import 'package:allo_coursier_app/domain/colis_payout.dart';
import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:flutter_test/flutter_test.dart';

CommandeModel order({
  required String id,
  String status = 'Livrer',
  double price = 50,
  double fee = 7,
  double montantPaye = 0,
  bool paid = false,
  String expediteurId = '203',
}) {
  return CommandeModel(
    id: id,
    status: status,
    produitPrixTotal: price,
    fraisLivraison: fee,
    montantPaye: montantPaye,
    paid: paid,
    expediteurId: expediteurId,
  );
}

void main() {
  test('orderNetCredit is COD minus delivery fee', () {
    expect(orderNetCredit(order(id: '1', price: 50, fee: 7)), 43);
  });

  test('orderRemainingPayout ignores paid and non-delivered', () {
    expect(orderRemainingPayout(order(id: '1', paid: true, montantPaye: 43)), 0);
    expect(orderRemainingPayout(order(id: '2', status: 'En route')), 0);
    expect(orderRemainingPayout(order(id: '3', montantPaye: 10)), 33);
  });

  test('montantPayeTotal and montantResteTotal aggregate nets', () {
    final rows = [
      order(id: '1', montantPaye: 20),
      order(id: '2', paid: true, montantPaye: 43),
      order(id: '3', status: 'En cours'),
    ];
    expect(montantPayeTotal(rows), 63);
    expect(montantResteTotal(rows), 23);
  });

  test('montantPayeTotal falls back to net when paid but montant_paye is 0', () {
    expect(
      montantPayeTotal([
        order(id: '1', paid: true, montantPaye: 0, price: 50, fee: 7),
      ]),
      43,
    );
  });

  test('planColisPayout covers FIFO with a partial last allocation', () {
    final plan = planColisPayout(
      [
        order(id: '1', price: 30, fee: 5),
        order(id: '2', price: 40, fee: 5),
      ],
      30,
    );
    expect(plan.total, 30);
    expect(plan.allocations, hasLength(2));
    expect(plan.allocations[0].orderId, '1');
    expect(plan.allocations[0].amount, 25);
    expect(plan.allocations[0].fullyPaid, isTrue);
    expect(plan.allocations[1].orderId, '2');
    expect(plan.allocations[1].amount, 5);
    expect(plan.allocations[1].fullyPaid, isFalse);
  });

  test('planColisPayout rejects empty or oversize amounts', () {
    expect(() => planColisPayout([], 10), throwsStateError);
    expect(
      () => planColisPayout([order(id: '1')], 0),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => planColisPayout([order(id: '1', price: 20, fee: 5)], 20),
      throwsA(isA<ArgumentError>()),
    );
  });
}
