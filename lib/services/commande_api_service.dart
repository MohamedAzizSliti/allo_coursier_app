import '../l10n/l10n.dart';
import '../models/commande_model.dart';
import '../models/driver_day_stats.dart';
import '../models/parcel_status.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class CommandePage {
  const CommandePage({required this.rows, required this.total, this.sum});

  final List<CommandeModel> rows;
  final int total;
  final double? sum;
}

class CommandeApiService {
  CommandeApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  static const int defaultPageSize = 25;
  static const int maxPageSize = 50;

  CommandePage _toPage(PageResult page) {
    final rows = <CommandeModel>[];
    for (final row in page.rows) {
      try {
        rows.add(CommandeModel.fromJson(jsonMap(row)));
      } catch (_) {}
    }
    return CommandePage(
      rows: rows,
      total: page.total,
      sum: page.sum,
    );
  }

  Future<CommandePage> listCommandesPage({
    int page = 0,
    int pageSize = defaultPageSize,
    String? shipment,
    String? gouvernorat,
    String? search,
    String? vehicleId,
    String? deliveryFrom,
    String? deliveryTo,
  }) async {
    final size = pageSize.clamp(1, maxPageSize);
    final query = <String, dynamic>{
      'page': page,
      'pageSize': size,
    };
    if (shipment != null && shipment.isNotEmpty && shipment != 'Tous') {
      query['shipment'] = shipmentBoardFilter(shipment);
    }
    if (gouvernorat != null && gouvernorat.isNotEmpty) {
      query['gouvernorat'] = gouvernorat;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (vehicleId != null && vehicleId.trim().isNotEmpty) {
      query['vehicleId'] = vehicleId.trim();
    }
    if (deliveryFrom != null && deliveryFrom.isNotEmpty) {
      query['deliveryFrom'] = deliveryFrom;
    }
    if (deliveryTo != null && deliveryTo.isNotEmpty) {
      query['deliveryTo'] = deliveryTo;
    }
    return _toPage(await _api.getPage('/commandes', query));
  }

  Future<List<CommandeModel>> listCommandes({
    String? status,
    String? shipment,
  }) async {
    final page = await listCommandesPage(
      shipment: shipment ?? status,
      pageSize: maxPageSize,
    );
    return page.rows;
  }

  static const shipmentStatFilters = [
    'En cours',
    'En dépôt',
    'En route',
    'Relivrer',
    'Livré',
    'Payé',
    'Annuler',
  ];

  Future<Map<String, int>> shipmentTotalsForUser(String userId) async {
    const labels = ['Tous', ...shipmentStatFilters];
    final pages = await Future.wait([
      for (final label in labels)
        listCommandesForUserPage(
          userId,
          pageSize: 1,
          shipment: label == 'Tous' ? null : label,
        ),
    ]);
    return {
      for (var i = 0; i < labels.length; i++) labels[i]: pages[i].total,
    };
  }

  Future<CommandePage> listCommandesForUserPage(
    String userId, {
    int page = 0,
    int pageSize = defaultPageSize,
    String? search,
    String? shipment,
  }) async {
    final size = pageSize.clamp(1, maxPageSize);
    final query = <String, dynamic>{
      'page': page,
      'pageSize': size,
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (shipment != null && shipment.isNotEmpty && shipment != 'Tous') {
      query['shipment'] = shipmentBoardFilter(shipment);
    }
    return _toPage(await _api.getPage('/users/$userId/colis', query));
  }

  Future<double> unpaidDeliveredTotalForUser(String userId) async {
    var pageIndex = 0;
    var loaded = 0;
    var total = 0.0;
    var expected = 0;
    var batch = 0;
    do {
      final page = await listCommandesForUserPage(
        userId,
        page: pageIndex,
        pageSize: maxPageSize,
        shipment: 'Livré',
      );
      if (pageIndex == 0) expected = page.total;
      batch = page.rows.length;
      total += unpaidDeliveredTotal(page.rows);
      loaded += batch;
      pageIndex += 1;
    } while (batch > 0 && loaded < expected && pageIndex < 20);
    return total;
  }

  Future<List<CommandeModel>> listCommandesForUser(String userId) async {
    final page = await listCommandesForUserPage(userId, pageSize: maxPageSize);
    return page.rows;
  }

  Future<CommandePage> listColisDuJour({
    int page = 0,
    int pageSize = defaultPageSize,
    String? shipment,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize.clamp(1, maxPageSize),
    };
    if (shipment != null && shipment.isNotEmpty && shipment != 'Tous') {
      query['shipment'] = shipmentBoardFilter(shipment);
    }
    return _toPage(await _api.getPage('/colis-du-jour', query));
  }

  Future<List<CommandeModel>> listAssignedColisDuJour(
    UserModel driver, {
    String? shipment,
  }) async {
    if (!_hasAssignedVehicle(driver)) return const [];
    return _pageAssigned(
      driver,
      (pageIndex) => listColisDuJour(
        page: pageIndex,
        pageSize: maxPageSize,
        shipment: shipment,
      ),
    );
  }

  /// Driver home and lists: parcels on the driver's vehicle (`GET /commandes`).
  /// South Tunisia runs last 2+ days, so En route / Relivrer / En dépôt are
  /// not limited to today's delivery date. Livré / Annuler stay a 14-day window.
  Future<List<CommandeModel>> listAssignedParcels(
    UserModel driver, {
    String? shipment,
  }) async {
    if (!_hasAssignedVehicle(driver)) return const [];
    if (shipment != null && shipment.isNotEmpty && shipment != 'Tous') {
      return _pageAssignedDriver(driver, shipment);
    }
    final chunks = await Future.wait([
      for (final status in const ['En route', 'Relivrer', 'En dépôt', 'Livré', 'Annuler'])
        _pageAssignedDriver(driver, status),
    ]);
    final byId = <String, CommandeModel>{};
    for (final rows in chunks) {
      for (final row in rows) {
        byId[row.id] = row;
      }
    }
    return byId.values.toList();
  }

  Future<List<CommandeModel>> _pageAssignedDriver(
    UserModel driver,
    String shipment,
  ) {
    final closed = _isClosedShipment(shipment);
    return _pageAssigned(
      driver,
      (pageIndex) => listCommandesPage(
        page: pageIndex,
        pageSize: maxPageSize,
        shipment: shipment,
        vehicleId: driver.vehicleId,
        deliveryFrom: closed ? _daysAgo(14) : null,
        deliveryTo: closed ? _daysAhead(1) : null,
      ),
    );
  }

  Future<List<CommandeModel>> _pageAssigned(
    UserModel driver,
    Future<CommandePage> Function(int pageIndex) loadPage,
  ) async {
    var pageIndex = 0;
    var loaded = 0;
    var expected = 0;
    var batch = 0;
    final rows = <CommandeModel>[];
    do {
      final page = await loadPage(pageIndex);
      if (pageIndex == 0) expected = page.total;
      batch = page.rows.length;
      rows.addAll(page.rows);
      loaded += batch;
      pageIndex += 1;
    } while (batch > 0 && loaded < expected && pageIndex < 20);
    return rows.where((row) => isAssignedToDriver(row, driver: driver)).toList();
  }

  Future<CommandeModel> getCommande(String id) async {
    final data = await _api.get('/commandes/$id');
    return CommandeModel.fromJson(data);
  }

  Future<CommandeModel> createCommande(Map<String, dynamic> body) async {
    final data = await _api.post('/commandes', body);
    return CommandeModel.fromJson(data);
  }

  /// Admin ledger totals for Livré / Payé filters.
  Future<({double amount, double deliveryFees})> paymentSums({
    String? shipment,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (shipment != null && shipment.isNotEmpty && shipment != 'Tous') {
      query['shipment'] = shipmentBoardFilter(shipment);
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final data = await _api.get(
      '/commandes/payment-sums',
      query.isEmpty ? null : query,
    );
    return (
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      deliveryFees: (data['deliveryFees'] as num?)?.toDouble() ??
          (data['delivery_fees'] as num?)?.toDouble() ??
          0,
    );
  }

  Future<CommandeModel> patchCommande(String id, Map<String, dynamic> body) async {
    final data = await _api.patch('/commandes/$id', body);
    return CommandeModel.fromJson(data);
  }

  Future<void> deleteCommande(String id) async {
    await _api.delete('/commandes/$id');
  }

  Future<CommandeModel> confirmColis(
    String id, {
    String? vehicleId,
    String? deliveryDate,
  }) async {
    final body = <String, dynamic>{};
    if (vehicleId != null && vehicleId.trim().isNotEmpty) {
      body['vehicleId'] = vehicleId.trim();
    }
    if (deliveryDate != null && deliveryDate.trim().isNotEmpty) {
      body['deliveryDate'] = deliveryDate.trim();
    }
    final data = await _api.post('/commandes/$id/confirm-colis', body);
    return CommandeModel.fromJson(data);
  }

  Future<CommandeModel> claim(String id) async {
    final data = await _api.post('/commandes/$id/claim');
    return CommandeModel.fromJson(data);
  }

  /// Admin/agent: En dépôt | Relivrer → En route with a chosen driver.
  /// Admin/agent: put the parcel En route on this vehicle.
  Future<CommandeModel> staffClaim(String id, {required String vehicleId}) async {
    final data = await _api.post('/commandes/$id/claim', {'vehicleId': vehicleId});
    return CommandeModel.fromJson(data);
  }

  /// Admin/agent: move the parcel onto that driver's vehicle.
  Future<CommandeModel> assignDelivery(String id, {required String livreurId}) async {
    return patchCommande(id, {'livreur_id': livreurId});
  }

  Future<CommandeModel> deliver(String id) async {
    final data = await _api.post('/commandes/$id/deliver');
    return CommandeModel.fromJson(data);
  }

  Future<CommandeModel> annuler(String id, {required String reason}) async {
    final data = await _api.post('/commandes/$id/annuler', {'reason': reason});
    return CommandeModel.fromJson(data);
  }

  /// Livreur: `{ reason }` from En route → Relivrer.
  /// Admin/agent: `{ deliveryDate, vehicleId? }` from Relivrer → En dépôt.
  Future<CommandeModel> relivrer(
    String id, {
    String? reason,
    String? deliveryDate,
    String? vehicleId,
  }) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;
    if (deliveryDate != null) body['deliveryDate'] = deliveryDate;
    if (vehicleId != null) body['vehicleId'] = vehicleId;
    final data = await _api.post('/commandes/$id/relivrer', body);
    return CommandeModel.fromJson(data);
  }

  Future<CommandeModel> pay(String id) async {
    final data = await _api.post('/commandes/$id/pay');
    return CommandeModel.fromJson(data);
  }

  /// Live API: POST /scanner/lookup `{ "id": "83678" }` → `{ found, order }`.
  Future<CommandeModel> scannerLookup(String code) async {
    final id = normalizeScanId(code);
    final data = await _api.post('/scanner/lookup', {'id': id});
    if (data['found'] == false) {
      throw AlloException('not_found', LocaleController.instance.s.parcelNotFound);
    }
    final order = data['order'] ?? data;
    return CommandeModel.fromJson(jsonMap(order));
  }
}

String normalizeScanId(String raw) {
  final trimmed = raw.trim();
  if (trimmed.toUpperCase().startsWith('HT')) {
    return trimmed.substring(2);
  }
  return trimmed;
}

/// Board query value: live API rejects `Livrer` and expects `Livré`.
String shipmentBoardFilter(String shipment) {
  switch (parseParcelStatus(shipment)) {
    case ParcelStatus.livrer:
      return 'Livré';
    default:
      return shipment;
  }
}

bool _hasAssignedVehicle(UserModel driver) {
  final vehicle = driver.vehicleId?.trim();
  return vehicle != null && vehicle.isNotEmpty;
}

bool _isClosedShipment(String shipment) {
  final status = parseParcelStatus(shipment);
  return status == ParcelStatus.livrer || status == ParcelStatus.annuler;
}

String _ymd(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _daysAgo(int days) =>
    _ymd(DateTime.now().subtract(Duration(days: days)));

String _daysAhead(int days) => _ymd(DateTime.now().add(Duration(days: days)));
