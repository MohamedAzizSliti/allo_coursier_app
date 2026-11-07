import 'api_client.dart';

class DashboardApiService {
  DashboardApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  Future<Map<String, dynamic>> getDashboard() async {
    return _api.get('/dashboard');
  }

  Future<DashboardData> getDashboardData() async {
    try {
      final raw = await getDashboard();
      return DashboardData.fromJson(raw);
    } on AlloException catch (e) {
      if (e.isNotFound) {
        return _composeFromLists();
      }
      rethrow;
    }
  }

  Future<DashboardData> _composeFromLists() async {
    // Never dump GET /commandes (can be tens of thousands of rows).
    final results = await Future.wait([
      _api.getList('/users', {'role': 'business_client'}),
      _api.getList('/users', {'role': 'delivery_person'}),
      _api.getList('/vehicles'),
    ]);
    final expediteurs = results[0];
    final livreurs = results[1];
    final vehicles = results[2];

    return DashboardData(
      counts: {
        'business_clients': expediteurs.length,
        'delivery_persons': livreurs.length,
        'vehicles': vehicles.length,
      },
      totals: {
        'expediteurs': expediteurs.length.toDouble(),
        'livreurs': livreurs.length.toDouble(),
        'vehicles': vehicles.length.toDouble(),
      },
      commandesByDate: const [],
    );
  }
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

/// Parsed dashboard data. Accepts both spec status-name counts and insights keys.
class DashboardData {
  final Map<String, int> counts;
  final Map<String, double> totals;
  final List<dynamic> commandesByDate;
  final Map<String, int> insights;
  final double enRouteAmount;
  final List<Map<String, dynamic>> topPlaces;

  const DashboardData({
    required this.counts,
    required this.totals,
    required this.commandesByDate,
    this.insights = const {},
    this.enRouteAmount = 0,
    this.topPlaces = const [],
  });

  int countOf(String status) => counts[status] ?? 0;

  int get enDepot =>
      counts['En dépôt'] ?? insights['en_depot'] ?? 0;
  int get enRoute =>
      counts['En route'] ?? insights['en_route'] ?? 0;
  int get livre =>
      counts['Livré'] ?? counts['Livrer'] ?? insights['livre'] ?? 0;
  int get paye =>
      counts['Payé'] ?? counts['Paye'] ?? insights['paye'] ?? 0;
  int get tous =>
      counts['Tous'] ?? insights['tous'] ?? commandesToday;
  int get relivrer =>
      counts['Relivrer'] ?? insights['relivrer'] ?? 0;
  int get annuler =>
      counts['Annuler'] ?? insights['annuler'] ?? 0;
  int get enCours =>
      counts['En cours'] ?? insights['en_cours'] ?? 0;
  int get weekDeliveries =>
      insights['weekDeliveries'] ?? 0;

  int get businessClients =>
      counts['business_clients'] ??
      insights['business_clients'] ??
      totals['expediteurs']?.toInt() ??
      0;
  int get deliveryPersons =>
      counts['delivery_persons'] ??
      insights['delivery_persons'] ??
      totals['livreurs']?.toInt() ??
      0;
  int get vehicles =>
      counts['vehicles'] ?? insights['vehicles'] ?? totals['vehicles']?.toInt() ?? 0;
  int get commandesToday =>
      counts['commandes_today'] ?? insights['commandes_today'] ?? counts['Tous'] ?? 0;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final rawCounts = _asMap(json['counts']);
    final rawTotals = _asMap(json['totals']);
    final rawInsights = _asMap(json['insights']);

    const extraKeys = [
      'business_clients',
      'delivery_persons',
      'vehicles',
      'commandes_today',
      'en_depot',
      'livre',
      'relivrer',
      'annuler',
      'en_route',
      'en_cours',
      'weekDeliveries',
    ];
    for (final key in extraKeys) {
      final value = json[key];
      if ((value is num || value is String) &&
          !rawCounts.containsKey(key) &&
          !rawInsights.containsKey(key)) {
        rawInsights[key] = value;
      }
    }

    return DashboardData(
      counts: rawCounts.map((k, v) => MapEntry(k, _asInt(v))),
      totals: rawTotals.map((k, v) => MapEntry(k, _asDouble(v))),
      commandesByDate:
          json['commandesByDate'] is List ? json['commandesByDate'] as List : const [],
      insights: {
        for (final entry in rawInsights.entries)
          if (entry.key != 'topPlaces' && entry.key != 'enRouteAmount')
            entry.key: _asInt(entry.value),
      },
      enRouteAmount: _asDouble(
        rawInsights['enRouteAmount'] ?? json['enRouteAmount'],
      ),
      topPlaces: _asPlaceList(rawInsights['topPlaces'] ?? json['topPlaces']),
    );
  }
}

List<Map<String, dynamic>> _asPlaceList(dynamic value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map)
        {
          'name': Map<String, dynamic>.from(item)['name']?.toString() ?? '',
          'count': _asInt(Map<String, dynamic>.from(item)['count']),
        },
  ];
}
