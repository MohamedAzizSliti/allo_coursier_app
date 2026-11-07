import 'package:allo_coursier_app/domain/account_access.dart';
import 'package:allo_coursier_app/domain/handover.dart';
import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:flutter_test/flutter_test.dart';

CommandeModel order({
  required String id,
  required String status,
  double price = 0,
  double fee = 0,
  bool paid = false,
}) {
  return CommandeModel(
    id: id,
    status: status,
    produitPrixTotal: price,
    fraisLivraison: fee,
    paid: paid,
  );
}

void main() {
  test('cancellation fee is half the delivery fee', () {
    expect(cancellationFee(8), 4);
    expect(cancellationFee(7), 3.5);
    expect(cancellationFee(0), 0);
  });

  test('handover totals split cash, delivery fees, and half cancellation fees', () {
    final totals = paymentTotals([
      order(id: '1', status: 'Livrer', price: 28, fee: 8),
      order(id: '2', status: 'Annuler', fee: 8),
      order(id: '3', status: 'En route', price: 10, fee: 7),
    ]);
    expect(totals.totalCollected, 28);
    expect(totals.totalDeliveryFees, 8);
    expect(totals.cancellationFees, 4);
  });

  test('confirm payment includes unpaid delivered and cancelled parcels', () {
    expect(
      paymentOrderIds([
        order(id: '1', status: 'Livrer', paid: false),
        order(id: '2', status: 'Livrer', paid: true),
        order(id: '3', status: 'Annuler', fee: 8, paid: false),
        order(id: '4', status: 'Annuler', fee: 0, paid: false),
        order(id: '5', status: 'En route'),
      ]),
      ['1', '3'],
    );
  });

  test('agents create expéditeurs and agents, only admin creates a driver', () {
    expect(canCreateAccount('admin', 'delivery_person'), isTrue);
    expect(canCreateAccount('agent', 'delivery_person'), isFalse);
    expect(canCreateAccount('agent', 'business_client'), isTrue);
    expect(canCreateAccount('agent', 'agent'), isTrue);
    expect(canCreateAccount('business_client', 'business_client'), isFalse);
  });
}
