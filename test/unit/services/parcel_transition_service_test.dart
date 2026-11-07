import 'package:allo_coursier_app/l10n/l10n.dart';
import 'package:allo_coursier_app/models/parcel_status.dart';
import 'package:allo_coursier_app/services/api_client.dart';
import 'package:allo_coursier_app/services/parcel_transition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svc = ParcelTransitionService();

  test('parseParcelStatus accepts French and English', () {
    expect(parseParcelStatus('En cours'), ParcelStatus.enCours);
    expect(parseParcelStatus('CREATED'), ParcelStatus.enCours);
    expect(parseParcelStatus('Livré'), ParcelStatus.livrer);
    expect(parseParcelStatus('REJECTED'), ParcelStatus.annuler);
  });

  test('scanIntent is role-gated', () {
    expect(
      svc.scanIntent(ParcelStatus.enCours, OfficeRole.admin),
      ScanIntent.confirmColis,
    );
    expect(
      svc.scanIntent(ParcelStatus.enCours, OfficeRole.deliveryPerson),
      ScanIntent.detailsOnly,
    );
    expect(
      svc.scanIntent(ParcelStatus.enDepot, OfficeRole.deliveryPerson),
      ScanIntent.claim,
    );
    expect(
      svc.scanIntent(ParcelStatus.relivrer, OfficeRole.deliveryPerson),
      ScanIntent.claim,
    );
    expect(
      svc.scanIntent(ParcelStatus.enRoute, OfficeRole.deliveryPerson),
      ScanIntent.outcome,
    );
    expect(
      svc.scanIntent(ParcelStatus.enDepot, OfficeRole.admin),
      ScanIntent.detailsOnly,
    );
  });

  test('assertValid allows the section-10 graph and rejects the rest', () {
    svc.assertValid(ParcelStatus.enCours, ParcelStatus.enDepot);
    svc.assertValid(ParcelStatus.enDepot, ParcelStatus.enRoute);
    svc.assertValid(ParcelStatus.relivrer, ParcelStatus.enRoute);
    svc.assertValid(ParcelStatus.relivrer, ParcelStatus.enDepot);
    svc.assertValid(ParcelStatus.enRoute, ParcelStatus.livrer);
    svc.assertValid(ParcelStatus.enRoute, ParcelStatus.annuler);
    svc.assertValid(ParcelStatus.annuler, ParcelStatus.enDepot);
    expect(
      () => svc.assertValid(ParcelStatus.enCours, ParcelStatus.enRoute),
      throwsA(isA<AlloException>().having((e) => e.isConflict, 'conflict', true)),
    );
  });

  test('driver scan miss explains assignment, not a missing parcel', () {
    const strings = AppStrings(true);
    expect(
      svc.scanLookupError(
        OfficeRole.deliveryPerson,
        const AlloException('not_found', 'Commande introuvable!'),
        strings,
      ),
      strings.scanNotAssigned,
    );
    expect(
      svc.scanLookupError(
        OfficeRole.admin,
        const AlloException('not_found', 'Commande introuvable!'),
        strings,
      ),
      'Commande introuvable!',
    );
  });

  test('admin-only pay and write gates', () {
    expect(svc.canPay(ParcelStatus.livrer, false, OfficeRole.admin), isTrue);
    expect(svc.canPay(ParcelStatus.livrer, false, OfficeRole.agent), isFalse);
    expect(svc.canWriteVehicles(OfficeRole.admin), isTrue);
    expect(svc.canWriteVehicles(OfficeRole.agent), isFalse);
    expect(svc.canCreateUsers(OfficeRole.agent), isFalse);
  });

  test('admin and agent can reassign delivery and claim a depot parcel', () {
    expect(
      svc.canReassignDelivery(ParcelStatus.enDepot, OfficeRole.agent),
      isTrue,
    );
    expect(
      svc.canReassignDelivery(ParcelStatus.enRoute, OfficeRole.admin),
      isTrue,
    );
    expect(
      svc.canReassignDelivery(ParcelStatus.livrer, OfficeRole.admin),
      isFalse,
    );
    expect(
      svc.canReassignDelivery(ParcelStatus.enDepot, OfficeRole.deliveryPerson),
      isFalse,
    );
    expect(svc.canStaffClaim(ParcelStatus.enDepot, OfficeRole.agent), isTrue);
    expect(svc.canStaffClaim(ParcelStatus.enRoute, OfficeRole.admin), isFalse);
    expect(svc.canAssignVehicleDriver(OfficeRole.agent), isTrue);
    expect(svc.canAssignVehicleDriver(OfficeRole.deliveryPerson), isFalse);
  });
}
