import 'package:allo_coursier_app/models/commande_model.dart';
import 'package:allo_coursier_app/models/driver_day_stats.dart';
import 'package:allo_coursier_app/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isAssignedToDriver matches the driver vehicle, not the livreur id', () {
    const parcel = CommandeModel(
      id: '1',
      livreurId: '7',
      vehicleId: '33',
    );
    expect(
      isAssignedToDriver(
        parcel,
        driver: const UserModel(
          id: '1629',
          email: '',
          name: 'Ali',
          role: 'delivery_person',
          uid: '7',
        ),
      ),
      isFalse,
    );
    expect(
      isAssignedToDriver(
        parcel,
        driver: const UserModel(
          id: '99',
          email: '',
          name: 'Ali',
          role: 'delivery_person',
          vehicleId: '33',
        ),
      ),
      isTrue,
    );
    expect(
      isAssignedToDriver(
        const CommandeModel(id: '2', livreurId: '7', vehicleId: '99'),
        driver: const UserModel(
          id: '1629',
          email: '',
          name: 'Ali',
          role: 'delivery_person',
          uid: '7',
          vehicleId: '33',
        ),
      ),
      isFalse,
    );
    expect(
      isAssignedToDriver(
        parcel,
        driver: const UserModel(
          id: '99',
          email: '',
          name: 'Ali',
          role: 'delivery_person',
        ),
      ),
      isFalse,
    );
  });

  test('DriverDayStats counts Livré as delivered and sums earnings', () {
    const rows = [
      CommandeModel(id: '1', status: 'En route'),
      CommandeModel(id: '2', status: 'Livrer', produitPrixTotal: 10),
      CommandeModel(id: '3', status: 'Livré', produitPrixTotal: 5),
      CommandeModel(id: '4', status: 'Annuler'),
      CommandeModel(id: '5', status: 'Relivrer'),
    ];
    final stats = DriverDayStats.fromRows(rows);
    expect(stats.total, 5);
    expect(stats.inRoute, 1);
    expect(stats.delivered, 2);
    expect(stats.cancelled, 1);
    expect(stats.redeliver, 1);
    expect(stats.earnings, 15);
  });
}
