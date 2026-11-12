import '../models/commande_model.dart';
import '../models/parcel_status.dart';

class MonthlyInvoiceTotals {
  const MonthlyInvoiceTotals({
    required this.rows,
    required this.parcelTotal,
    required this.feeTotal,
    required this.deliveredCount,
  });

  final List<CommandeModel> rows;
  final double parcelTotal;
  final double feeTotal;
  final int deliveredCount;

  double get grandTotal => parcelTotal + feeTotal;
}

/// Parcels whose create or delivery date falls in [year]/[month] (1–12).
MonthlyInvoiceTotals buildMonthlyInvoice({
  required List<CommandeModel> orders,
  required int year,
  required int month,
}) {
  final rows = orders.where((o) {
    final raw = (o.deliveryDate != null && o.deliveryDate!.trim().isNotEmpty)
        ? o.deliveryDate
        : o.date;
    if (raw == null || raw.trim().isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;
    final local = parsed.toLocal();
    return local.year == year && local.month == month;
  }).toList();

  var parcelTotal = 0.0;
  var feeTotal = 0.0;
  var deliveredCount = 0;
  for (final o in rows) {
    parcelTotal += o.produitPrixTotal;
    feeTotal += o.fraisLivraison;
    if (parseParcelStatus(o.status) == ParcelStatus.livrer) {
      deliveredCount += 1;
    }
  }
  return MonthlyInvoiceTotals(
    rows: rows,
    parcelTotal: parcelTotal,
    feeTotal: feeTotal,
    deliveredCount: deliveredCount,
  );
}
