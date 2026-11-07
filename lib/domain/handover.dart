import '../models/commande_model.dart';

/// Half the delivery fee, rounded to millimes, charged when a cancelled parcel is paid.
double cancellationFee(num fraisLivraison) {
  final frais = fraisLivraison.isFinite ? fraisLivraison.toDouble() : 0;
  return (frais / 2 * 1000).round() / 1000;
}

class HandoverTotals {
  const HandoverTotals({
    required this.totalCollected,
    required this.totalDeliveryFees,
    required this.cancellationFees,
  });

  final double totalCollected;
  final double totalDeliveryFees;
  final double cancellationFees;
}

HandoverTotals paymentTotals(Iterable<CommandeModel> orders) {
  var collected = 0.0;
  var fees = 0.0;
  var cancelled = 0.0;
  for (final order in orders) {
    if (order.status == 'Livrer') {
      collected += order.produitPrixTotal;
      fees += order.fraisLivraison;
    } else if (order.status == 'Annuler') {
      cancelled += cancellationFee(order.fraisLivraison);
    }
  }
  return HandoverTotals(
    totalCollected: (collected * 1000).round() / 1000,
    totalDeliveryFees: (fees * 1000).round() / 1000,
    cancellationFees: (cancelled * 1000).round() / 1000,
  );
}

/// Unpaid delivered parcels and unpaid cancellations that still carry a fee.
List<String> paymentOrderIds(Iterable<CommandeModel> orders) {
  return [
    for (final order in orders)
      if (!order.paid &&
          (order.status == 'Livrer' ||
              (order.status == 'Annuler' && cancellationFee(order.fraisLivraison) > 0)))
        order.id,
  ];
}
