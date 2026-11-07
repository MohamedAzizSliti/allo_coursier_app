import '../models/commande_model.dart';

/// Columns of the paper delivery sheet (web `CIRCUIT_COLUMNS`) — no ville.
const kCircuitColumns = <({String key, String label})>[
  (key: 'expediteur', label: 'Expéditeur'),
  (key: 'adresse', label: 'Adresse'),
  (key: 'gouv', label: 'Gouv'),
  (key: 'phone', label: 'Téléphone'),
  (key: 'total', label: 'Total TTC (7% TVA)'),
  (key: 'article', label: 'Nom Article'),
  (key: 'description', label: 'Description'),
  (key: 'remarques', label: 'Remarques'),
];

/// Relative flex widths matching the web circuit PDF.
const kCircuitColumnFlex = <String, double>{
  'expediteur': 1.45,
  'adresse': 1.85,
  'gouv': 0.85,
  'phone': 1,
  'total': 0.95,
  'article': 1.15,
  'description': 0.95,
  'remarques': 0.9,
};

/// Bon de livraison number as printed: 1 → BL0001, 2749 → BL2749.
String formatBonLivraison(int id) {
  final n = id.truncate();
  final raw = n.abs().toString();
  if (raw.length >= 4) return 'BL$raw';
  return 'BL${raw.padLeft(4, '0')}';
}

/// Millimes with a comma, as on the printed sheet: 80 → 80,000.
String formatCircuitAmount(num value) {
  return value.toDouble().toStringAsFixed(3).replaceAll('.', ',');
}

String circuitCell(CommandeModel order, String key) {
  switch (key) {
    case 'expediteur':
      return order.expediteurName;
    case 'adresse':
      return order.clientAdresse;
    case 'gouv':
      return order.clientGouvernorat;
    case 'phone':
      return order.clientTelephone;
    case 'total':
      return formatCircuitAmount(order.produitPrixTotal);
    case 'article':
      return order.produitNom;
    case 'description':
      return '';
    case 'remarques':
      return order.reason?.trim() ?? '';
    default:
      return '';
  }
}

/// Same route order as web: gouvernorat then ville.
List<CommandeModel> sortCircuitOrders(Iterable<CommandeModel> orders) {
  final rows = [...orders];
  rows.sort((a, b) {
    final byGov = a.clientGouvernorat.toLowerCase().compareTo(
      b.clientGouvernorat.toLowerCase(),
    );
    if (byGov != 0) return byGov;
    return a.clientVille.toLowerCase().compareTo(b.clientVille.toLowerCase());
  });
  return rows;
}
