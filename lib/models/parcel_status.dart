/// Canonical parcel statuses used by `/api/mobile`.
enum ParcelStatus {
  enCours,
  enDepot,
  enRoute,
  livrer,
  relivrer,
  annuler,
}

extension ParcelStatusX on ParcelStatus {
  String get apiValue {
    switch (this) {
      case ParcelStatus.enCours:
        return 'En cours';
      case ParcelStatus.enDepot:
        return 'En dépôt';
      case ParcelStatus.enRoute:
        return 'En route';
      case ParcelStatus.livrer:
        return 'Livrer';
      case ParcelStatus.relivrer:
        return 'Relivrer';
      case ParcelStatus.annuler:
        return 'Annuler';
    }
  }

  String get label {
    switch (this) {
      case ParcelStatus.livrer:
        return 'Livré';
      case ParcelStatus.annuler:
        return 'Annulé';
      default:
        return apiValue;
    }
  }
}

ParcelStatus? parseParcelStatus(String? raw) {
  switch (raw?.trim()) {
    case 'En cours':
    case 'CREATED':
      return ParcelStatus.enCours;
    case 'En dépôt':
    case 'IN_DEPOT':
      return ParcelStatus.enDepot;
    case 'En route':
    case 'IN_ROUTE':
      return ParcelStatus.enRoute;
    case 'Livrer':
    case 'Livré':
    case 'DELIVERED':
      return ParcelStatus.livrer;
    case 'Relivrer':
    case 'REDELIVER':
      return ParcelStatus.relivrer;
    case 'Annuler':
    case 'Annulé':
    case 'REJECTED':
      return ParcelStatus.annuler;
    default:
      return null;
  }
}

const shipmentFilters = [
  'Tous',
  'En cours',
  'En dépôt',
  'En route',
  'Relivrer',
  'Livré',
  'Payé',
  'Annuler',
];
