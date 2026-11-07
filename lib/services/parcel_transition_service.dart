import '../l10n/l10n.dart';
import '../models/parcel_status.dart';
import 'api_client.dart';

enum OfficeRole { admin, agent, deliveryPerson, businessClient }

OfficeRole parseOfficeRole(String? role) {
  switch (role) {
    case 'admin':
      return OfficeRole.admin;
    case 'agent':
      return OfficeRole.agent;
    case 'delivery_person':
      return OfficeRole.deliveryPerson;
    default:
      return OfficeRole.businessClient;
  }
}

enum ScanIntent {
  confirmColis,
  claim,
  outcome,
  detailsOnly,
}

class ParcelTransitionService {
  const ParcelTransitionService();

  String scanLookupError(OfficeRole role, AlloException error, AppStrings s) {
    if (role == OfficeRole.deliveryPerson &&
        (error.isNotFound || error.isForbidden || error.isUnauthorized)) {
      return s.scanNotAssigned;
    }
    return error.message;
  }

  ScanIntent scanIntent(ParcelStatus status, OfficeRole role) {
    final isOffice = role == OfficeRole.admin || role == OfficeRole.agent;
    final isDriver = role == OfficeRole.deliveryPerson;

    if (isOffice && status == ParcelStatus.enCours) {
      return ScanIntent.confirmColis;
    }
    if (isDriver &&
        (status == ParcelStatus.enDepot || status == ParcelStatus.relivrer)) {
      return ScanIntent.claim;
    }
    if (isDriver && status == ParcelStatus.enRoute) {
      return ScanIntent.outcome;
    }
    return ScanIntent.detailsOnly;
  }

  void assertValid(ParcelStatus from, ParcelStatus to) {
    if (!_allowed.containsKey(from) || !_allowed[from]!.contains(to)) {
      throw AlloException(
        'conflict',
        LocaleController.instance.isArabic
            ? 'رُفض الانتقال : لا يمكن للطرد « ${from.apiValue} » أن يصبح « ${to.apiValue} ».'
            : 'Transition refusée : un colis « ${from.apiValue} » ne peut pas passer à « ${to.apiValue} ».',
      );
    }
  }

  bool canPay(ParcelStatus status, bool paid, OfficeRole role) {
    return role == OfficeRole.admin && status == ParcelStatus.livrer && !paid;
  }

  bool canAdminRelivrer(ParcelStatus status, OfficeRole role) {
    return status == ParcelStatus.relivrer &&
        (role == OfficeRole.admin || role == OfficeRole.agent);
  }

  bool canReturnToDepot(ParcelStatus status, OfficeRole role) {
    return status == ParcelStatus.annuler &&
        (role == OfficeRole.admin || role == OfficeRole.agent);
  }

  bool canDeleteCommande(OfficeRole role) {
    return role == OfficeRole.admin || role == OfficeRole.agent;
  }

  bool canReassignDelivery(ParcelStatus status, OfficeRole role) {
    if (role != OfficeRole.admin && role != OfficeRole.agent) return false;
    switch (status) {
      case ParcelStatus.enDepot:
      case ParcelStatus.enRoute:
      case ParcelStatus.relivrer:
        return true;
      default:
        return false;
    }
  }

  bool canStaffClaim(ParcelStatus status, OfficeRole role) {
    if (role != OfficeRole.admin && role != OfficeRole.agent) return false;
    return status == ParcelStatus.enDepot || status == ParcelStatus.relivrer;
  }

  bool canAssignVehicleDriver(OfficeRole role) =>
      role == OfficeRole.admin || role == OfficeRole.agent;

  bool canWriteVehicles(OfficeRole role) => role == OfficeRole.admin;

  bool canCreateUsers(OfficeRole role) => role == OfficeRole.admin;

  static const _allowed = {
    ParcelStatus.enCours: {ParcelStatus.enDepot},
    ParcelStatus.enDepot: {ParcelStatus.enRoute},
    ParcelStatus.relivrer: {ParcelStatus.enRoute, ParcelStatus.enDepot},
    ParcelStatus.enRoute: {
      ParcelStatus.livrer,
      ParcelStatus.annuler,
      ParcelStatus.relivrer,
    },
    ParcelStatus.annuler: {ParcelStatus.enDepot},
    ParcelStatus.livrer: <ParcelStatus>{},
  };
}
