import 'commande_model.dart';
import 'parcel_status.dart';
import 'user_model.dart';

/// Same rule as the web livreur portal: a parcel belongs to the driver only
/// when it is on the vehicle assigned to that driver.
bool isAssignedToDriver(CommandeModel parcel, {required UserModel driver}) {
  final vehicle = driver.vehicleId?.trim();
  final parcelVehicle = parcel.vehicleId?.trim();
  return vehicle != null &&
      vehicle.isNotEmpty &&
      parcelVehicle != null &&
      parcelVehicle.isNotEmpty &&
      parcelVehicle == vehicle;
}

class DriverDayStats {
  const DriverDayStats({
    required this.rows,
    required this.inRoute,
    required this.delivered,
    required this.cancelled,
    required this.redeliver,
    required this.earnings,
  });

  final List<CommandeModel> rows;
  final int inRoute;
  final int delivered;
  final int cancelled;
  final int redeliver;
  final double earnings;

  int get total => rows.length;

  factory DriverDayStats.fromRows(List<CommandeModel> rows) {
    var inRoute = 0;
    var delivered = 0;
    var cancelled = 0;
    var redeliver = 0;
    var earnings = 0.0;
    for (final row in rows) {
      switch (parseParcelStatus(row.status)) {
        case ParcelStatus.enRoute:
          inRoute++;
        case ParcelStatus.livrer:
          delivered++;
          earnings += row.produitPrixTotal;
        case ParcelStatus.annuler:
          cancelled++;
        case ParcelStatus.relivrer:
          redeliver++;
        default:
          break;
      }
    }
    return DriverDayStats(
      rows: rows,
      inRoute: inRoute,
      delivered: delivered,
      cancelled: cancelled,
      redeliver: redeliver,
      earnings: earnings,
    );
  }
}
