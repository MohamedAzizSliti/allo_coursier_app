import '../domain/colis_payout.dart';
import 'parcel_status.dart';

/// Immutable commande model matching the API's FLAT field schema.
///
/// Display the order number as `HT$id`. Amounts in dinars, two decimals.
class CommandeModel {
  final String id;

  // Client (flat)
  final String clientNom;
  final String clientTelephone;
  final String clientGouvernorat;
  final String clientAdresse;
  final String clientVille;

  // Produit (flat)
  final String produitNom;
  final double produitPrixTotal;
  final bool produitFragile;
  final bool produitOuvrirAvantPaiement;
  final List<Map<String, dynamic>> produitList;

  // Expediteur
  final String expediteurId;
  final String expediteurName;

  // Assignment
  final String? livreurId;
  final String? vehicleId;

  // Status & payment
  final String status;
  final bool paid;
  /// Net already paid out to the expéditeur for this colis.
  final double montantPaye;
  final String livraison;
  final double fraisLivraison;
  final String? reason;

  // Dates (ISO strings from API)
  final String? date;
  final String? deliveryDate;

  const CommandeModel({
    required this.id,
    this.clientNom = '',
    this.clientTelephone = '',
    this.clientGouvernorat = '',
    this.clientAdresse = '',
    this.clientVille = '',
    this.produitNom = '',
    this.produitPrixTotal = 0,
    this.produitFragile = false,
    this.produitOuvrirAvantPaiement = false,
    this.produitList = const [],
    this.expediteurId = '',
    this.expediteurName = '',
    this.livreurId,
    this.vehicleId,
    this.status = 'En cours',
    this.paid = false,
    this.montantPaye = 0,
    this.livraison = '',
    this.fraisLivraison = 0,
    this.reason,
    this.date,
    this.deliveryDate,
  });

  /// Display ID: `HT83678`
  String get displayId => 'HT$id';

  /// Colis amount plus the delivery tarif.
  double get totalDue => produitPrixTotal + fraisLivraison;

  /// Net still owed on a delivered unpaid/partial colis.
  double get remainingPayout => orderRemainingPayout(this);

  /// Parsed date for display.
  DateTime? get dateTime => date != null ? DateTime.tryParse(date!) : null;

  /// Parsed delivery date for display.
  DateTime? get deliveryDateTime =>
      deliveryDate != null ? DateTime.tryParse(deliveryDate!) : null;

  static String _str(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }

  static bool _flag(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final t = value.trim().toLowerCase();
      return t == 'true' || t == '1' || t == 'yes';
    }
    return false;
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    final products = <Map<String, dynamic>>[];
    final rawList = json['produit_list'];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map) products.add(Map<String, dynamic>.from(item));
      }
    }
    return CommandeModel(
      id: json['id']?.toString() ?? '',
      clientNom: _str(json['client_nom']),
      clientTelephone: _str(json['client_telephone']),
      clientGouvernorat: _str(json['client_gouvernorat']),
      clientAdresse: _str(json['client_adresse']),
      clientVille: _str(json['client_ville']),
      produitNom: _str(json['produit_nom']),
      produitPrixTotal: _num(json['produit_prix_total']),
      produitFragile: _flag(json['produit_fragile']),
      produitOuvrirAvantPaiement: _flag(json['produit_ouvrir_avant_paiement']),
      produitList: products,
      expediteurId: json['expediteur_id']?.toString() ?? '',
      expediteurName: _str(json['expediteur_name']),
      livreurId: json['livreur_id']?.toString(),
      vehicleId: json['vehicle_id']?.toString(),
      status: _str(json['status']).isEmpty ? 'En cours' : _str(json['status']),
      paid: _flag(json['paid']),
      montantPaye: _num(json['montant_paye']),
      livraison: _str(json['livraison']),
      fraisLivraison: _num(json['frais_livraison']),
      reason: _str(json['reason']).isEmpty ? null : _str(json['reason']),
      date: _str(json['date']).isEmpty ? null : _str(json['date']),
      deliveryDate:
          _str(json['delivery_date']).isEmpty ? null : _str(json['delivery_date']),
    );
  }

  /// Body for POST /commandes (create).
  /// Live API requires `expediteur_id` even for the logged-in sender.
  Map<String, dynamic> toCreateJson() {
    return {
      'client_nom': clientNom.trim(),
      'client_telephone': clientTelephone.trim(),
      'client_gouvernorat': clientGouvernorat.trim(),
      'client_adresse': clientAdresse.trim(),
      'client_ville': clientVille.trim(),
      'produit_nom': produitNom.trim(),
      'produit_prix_total': produitPrixTotal,
      'produit_fragile': produitFragile,
      'produit_ouvrir_avant_paiement': produitOuvrirAvantPaiement,
      'produit_list': sanitizeProduitList(produitList),
      'expediteur_id': expediteurId,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CommandeModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CommandeModel(id: $id, status: $status)';
}

/// Drops empty table rows so Zod `{ name, quantity, pricePerKilo }` stays valid.
List<Map<String, dynamic>> sanitizeProduitList(List<Map<String, dynamic>> raw) {
  return [
    for (final item in raw)
      if ((item['name'] ?? '').toString().trim().isNotEmpty)
        {
          'name': (item['name'] ?? '').toString().trim(),
          'quantity': (item['quantity'] as num?)?.toDouble() ?? 0.0,
          'pricePerKilo': (item['pricePerKilo'] as num?)?.toDouble() ?? 0.0,
        },
  ];
}

/// POST /commandes body expected by `/api/mobile`.
///
/// When [categoryId] + [villeId] are set (web add-order parity), the API files
/// the ticket under that référentiel place instead of matching by name.
Map<String, dynamic> buildCreateCommandeBody({
  required String expediteurId,
  required String clientNom,
  required String clientTelephone,
  required String clientGouvernorat,
  required String clientAdresse,
  required String clientVille,
  required String produitNom,
  required double produitPrixTotal,
  required bool produitFragile,
  required bool produitOuvrirAvantPaiement,
  required List<Map<String, dynamic>> products,
  String? categoryId,
  String? villeId,
  String? deliveryDate,
}) {
  final list = sanitizeProduitList(products);
  final name = produitNom.trim().isNotEmpty
      ? produitNom.trim()
      : list.map((e) => e['name']).join(', ');
  final body = CommandeModel(
    id: '',
    clientNom: clientNom,
    clientTelephone: clientTelephone,
    clientGouvernorat: clientGouvernorat,
    clientAdresse: clientAdresse,
    clientVille: clientVille,
    produitNom: name,
    produitPrixTotal: produitPrixTotal,
    produitFragile: produitFragile,
    produitOuvrirAvantPaiement: produitOuvrirAvantPaiement,
    produitList: list,
    expediteurId: expediteurId,
    deliveryDate: deliveryDate,
  ).toCreateJson();

  final cat = categoryId?.trim() ?? '';
  final ville = villeId?.trim() ?? '';
  if (cat.isNotEmpty && ville.isNotEmpty) {
    return {
      ...body,
      'place': {'categoryId': cat, 'villeId': ville},
    };
  }
  return body;
}

/// Remaining net owed on delivered unpaid/partial parcels.
double unpaidDeliveredTotal(Iterable<CommandeModel> rows) {
  return montantResteTotal(rows);
}
