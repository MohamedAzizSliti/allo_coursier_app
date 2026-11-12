import '../models/commande_model.dart';
import '../models/parcel_status.dart';

double _roundDt(num value) {
  final n = value.isFinite ? value.toDouble() : 0;
  return (n * 1000).round() / 1000;
}

bool _isDelivered(CommandeModel order) =>
    parseParcelStatus(order.status) == ParcelStatus.livrer;

/// Net credit owed to the expéditeur (COD minus delivery fee).
double orderNetCredit(CommandeModel order) {
  return _roundDt(order.produitPrixTotal - order.fraisLivraison);
}

/// Remaining net still owed on a delivered unpaid/partial colis.
double orderRemainingPayout(CommandeModel order) {
  if (!_isDelivered(order) || order.paid) return 0;
  return _roundDt((orderNetCredit(order) - order.montantPaye).clamp(0, double.infinity));
}

/// Credited net for one colis. Fully paid rows with missing `montant_paye`
/// (legacy / pre-migration) fall back to COD − frais.
double creditedNet(CommandeModel order) {
  final net = orderNetCredit(order);
  if (order.montantPaye > 0) {
    return order.montantPaye < net ? order.montantPaye : net;
  }
  if (order.paid) return net;
  return 0;
}

/// Sum of amounts already paid out on delivered/paid colis (net).
double montantPayeTotal(Iterable<CommandeModel> orders) {
  var sum = 0.0;
  for (final order in orders) {
    if (!_isDelivered(order) && !order.paid) continue;
    sum += creditedNet(order);
  }
  return _roundDt(sum);
}

/// Sum of remaining net on delivered unpaid/partial colis.
double montantResteTotal(Iterable<CommandeModel> orders) {
  var sum = 0.0;
  for (final order in orders) {
    sum += orderRemainingPayout(order);
  }
  return _roundDt(sum);
}

class PayoutAllocation {
  const PayoutAllocation({
    required this.orderId,
    required this.expediteurId,
    required this.amount,
    required this.fullyPaid,
  });

  final String orderId;
  final String expediteurId;
  final double amount;
  final bool fullyPaid;
}

class ColisPayoutPlan {
  const ColisPayoutPlan({required this.allocations, required this.total});

  final List<PayoutAllocation> allocations;
  final double total;
}

/// FIFO payout plan for a cash amount over selected colis.
ColisPayoutPlan planColisPayout(Iterable<CommandeModel> orders, num amount) {
  final payable = [
    for (final order in orders)
      if (orderRemainingPayout(order) > 0) (order: order, remaining: orderRemainingPayout(order)),
  ];
  if (payable.isEmpty) {
    throw StateError('Aucun colis à payer');
  }

  final target = _roundDt(amount);
  if (target <= 0) {
    throw ArgumentError('Le montant doit être positif');
  }

  final maxPayable = _roundDt(payable.fold<double>(0, (s, row) => s + row.remaining));
  if (target > maxPayable) {
    throw ArgumentError('Le montant dépasse le reste à payer');
  }

  var left = target;
  final allocations = <PayoutAllocation>[];
  for (final row in payable) {
    if (left <= 0) break;
    final amountForOrder = _roundDt(left < row.remaining ? left : row.remaining);
    if (amountForOrder <= 0) continue;
    allocations.add(
      PayoutAllocation(
        orderId: row.order.id,
        expediteurId: row.order.expediteurId,
        amount: amountForOrder,
        fullyPaid: amountForOrder >= row.remaining,
      ),
    );
    left = _roundDt(left - amountForOrder);
  }

  return ColisPayoutPlan(allocations: allocations, total: target);
}
