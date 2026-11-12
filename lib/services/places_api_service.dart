import '../domain/delivery_schedule.dart';
import '../domain/gouvernorat_canon.dart';
import 'api_client.dart';
import 'supabase_rest.dart';

class GouvernoratPlace {
  const GouvernoratPlace({
    required this.id,
    required this.name,
    required this.tarif,
    required this.active,
    this.gouvernorat,
    this.tickets,
    this.villes,
    this.weekdays = const [],
  });

  final String id;
  final String name;
  final String? gouvernorat;
  final double tarif;
  final bool active;
  final int? tickets;
  final int? villes;

  /// ISO weekdays 1=Mon…7=Sun from `delivery_weekdays` RPC.
  final List<int> weekdays;

  String get label =>
      (gouvernorat != null && gouvernorat!.trim().isNotEmpty) ? gouvernorat! : name;

  factory GouvernoratPlace.fromJson(Map<String, dynamic> json) {
    final rawDays = json['weekdays'];
    final days = <int>[];
    if (rawDays is List) {
      for (final d in rawDays) {
        final n = d is num ? d.toInt() : int.tryParse(d.toString());
        if (n != null && n >= 1 && n <= 7) days.add(n);
      }
    }
    return GouvernoratPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gouvernorat: json['gouvernorat']?.toString(),
      tarif: (json['tarif'] as num?)?.toDouble() ?? 0,
      active: json['active'] != false,
      tickets: (json['tickets'] as num?)?.toInt(),
      villes: (json['villes'] as num?)?.toInt(),
      weekdays: days,
    );
  }
}

class VillePlace {
  const VillePlace({
    required this.id,
    required this.name,
    this.categoryId,
    this.secteurId,
    this.ordre,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String? secteurId;
  final int? ordre;

  factory VillePlace.fromJson(Map<String, dynamic> json) {
    return VillePlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? json['category_id']?.toString(),
      secteurId: json['secteurId']?.toString() ??
          json['secteur_id']?.toString() ??
          json['secteurs_id']?.toString(),
      ordre: (json['ordre'] as num?)?.toInt(),
    );
  }
}

class SecteurPlace {
  const SecteurPlace({
    required this.id,
    required this.name,
    this.ordre,
  });

  final String id;
  final String name;
  final int? ordre;

  factory SecteurPlace.fromJson(Map<String, dynamic> json) {
    return SecteurPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ordre: (json['ordre'] as num?)?.toInt(),
    );
  }
}

class VillePage {
  const VillePage({required this.rows, required this.total});

  final List<VillePlace> rows;
  final int total;
}

/// Places for order forms / référentiel.
///
/// **Reads** hit Supabase PostgREST directly (same as web VillePicker).
/// **Writes** still go through `/api/mobile` (admin tools).
class PlacesApiService {
  PlacesApiService({AlloApi? api, SupabaseRest? supabase})
      : _api = api ?? AlloApi.instance,
        _supabase = supabase ?? SupabaseRest();

  final AlloApi _api;
  final SupabaseRest _supabase;

  Future<List<GouvernoratPlace>> listGouvernorats() async {
    final categories = await _supabase.select(
      'helpdesk_ticket_category',
      select: 'id,name,tarif,active',
      order: 'id.asc',
      limit: 500,
    );

    Map<String, ({int tickets, int villes})> usage = {};
    try {
      final raw = await _supabase.rpc('category_usage');
      for (final row in raw) {
        if (row is! Map) continue;
        final id = row['category_id']?.toString();
        if (id == null || id.isEmpty) continue;
        usage = {
          ...usage,
          id: (
            tickets: (row['tickets'] as num?)?.toInt() ?? 0,
            villes: (row['villes'] as num?)?.toInt() ?? 0,
          ),
        };
      }
    } catch (_) {
      // Usage counts are optional for the order form.
    }

    Map<String, List<int>> schedule = {};
    try {
      final raw = await _supabase.rpc('delivery_weekdays');
      for (final row in raw) {
        if (row is! Map) continue;
        final name = row['gouvernorat']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final days = <int>[];
        final rawDays = row['weekdays'];
        if (rawDays is List) {
          for (final d in rawDays) {
            final n = d is num ? d.toInt() : int.tryParse(d.toString());
            if (n != null && n >= 1 && n <= 7) days.add(n);
          }
        }
        if (days.isNotEmpty) schedule = {...schedule, name: days};
      }
    } catch (_) {
      // Schedule RPC missing until migration — use offline fallback.
    }

    final rows = <GouvernoratPlace>[];
    for (final raw in categories.rows) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final name = localizedPlaceName(map['name']);
      final id = map['id']?.toString() ?? '';
      final counts = usage[id];
      final canon = canonicalGouvernorat(name);
      final weekdays = schedule[canon ?? ''] ?? schedule[name] ?? const <int>[];
      rows.add(
        GouvernoratPlace(
          id: id,
          name: name,
          gouvernorat: canon,
          tarif: (map['tarif'] as num?)?.toDouble() ??
              double.tryParse(map['tarif']?.toString() ?? '') ??
              0,
          active: map['active'] != false,
          tickets: counts?.tickets,
          villes: counts?.villes,
          weekdays: weekdays,
        ),
      );
    }
    rows.sort((a, b) {
      final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
      if (byLabel != 0) return byLabel;
      return a.id.compareTo(b.id);
    });

    DeliveryScheduleCache.replaceAll({
      for (final g in rows)
        if ((g.gouvernorat ?? g.name).trim().isNotEmpty && g.weekdays.isNotEmpty)
          (g.gouvernorat ?? g.name): g.weekdays.toSet(),
    });

    return rows;
  }

  Future<void> renameGouvernorat(String id, String gouvernorat) async {
    await _api.patch('/places/gouvernorats/$id', {'gouvernorat': gouvernorat});
  }

  Future<void> setGouvernoratActive(String id, bool active) async {
    await _api.patch('/places/gouvernorats/$id', {'active': active});
  }

  Future<void> mergeGouvernorats(String fromId, String intoId) async {
    await _api.patch('/places/gouvernorats/$fromId', {'mergeIntoId': intoId});
  }

  Future<VillePage> listVilles({
    String? categoryId,
    String? search,
    int page = 0,
    int pageSize = 25,
  }) async {
    final size = pageSize.clamp(1, 100);
    final filters = <String, dynamic>{};
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      filters['category_id'] = 'eq.${categoryId.trim()}';
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().replaceAll('%', r'\%').replaceAll(',', ' ');
      filters['name'] = 'ilike.*$q*';
    }

    final result = await _supabase.select(
      'ville',
      select: 'id,name,category_id,secteurs_id,ordre',
      filters: filters,
      order: 'name.asc,id.asc',
      limit: size,
      offset: page * size,
      countExact: true,
    );

    return VillePage(
      rows: [
        for (final raw in result.rows)
          if (raw is Map) VillePlace.fromJson(Map<String, dynamic>.from(raw)),
      ],
      total: result.total ?? result.rows.length,
    );
  }

  Future<VillePlace> saveVille({
    String? id,
    required String name,
    required String categoryId,
    String? secteurId,
    int? ordre,
  }) async {
    final body = {
      'name': name.trim(),
      'categoryId': categoryId,
      'secteurId': secteurId,
      'ordre': ordre,
    };
    final data = id == null || id.isEmpty
        ? await _api.post('/places/villes', body)
        : await _api.patch('/places/villes/$id', body);
    return VillePlace.fromJson(data);
  }

  Future<void> removeVille(String id) async {
    await _api.delete('/places/villes/$id');
  }

  Future<List<SecteurPlace>> listSecteurs() async {
    try {
      final result = await _supabase.select(
        'secteur',
        select: 'id,name,ordre',
        order: 'ordre.asc.nullslast,name.asc',
        limit: 1000,
      );
      return [
        for (final raw in result.rows)
          if (raw is Map) SecteurPlace.fromJson(Map<String, dynamic>.from(raw)),
      ];
    } on AlloException {
      return const [];
    }
  }

  Future<SecteurPlace> saveSecteur({
    String? id,
    required String name,
    int? ordre,
  }) async {
    final body = {'name': name.trim(), 'ordre': ordre};
    final data = id == null || id.isEmpty
        ? await _api.post('/places/secteurs', body)
        : await _api.patch('/places/secteurs/$id', body);
    return SecteurPlace.fromJson(data);
  }

  Future<void> removeSecteur(String id) async {
    await _api.delete('/places/secteurs/$id');
  }
}
