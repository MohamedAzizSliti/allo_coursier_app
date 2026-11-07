/// Immutable vehicle model matching the API schema.
///
/// Fields: `id`, `matricule`, `model`, `livreur` (livreur ID), `status`.
class VehicleModel {
  final String id;
  final String matricule;
  final String model;
  final String? livreur; // livreur user ID
  final String status;

  const VehicleModel({
    required this.id,
    required this.matricule,
    required this.model,
    this.livreur,
    this.status = 'available',
  });

  /// Display name: `Fiat/doblo - 249tunis5247`
  String get displayName => '$model - $matricule';

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id']?.toString() ?? '',
      matricule: json['matricule'] as String? ?? '',
      model: json['model'] as String? ?? '',
      livreur: _livreurId(json['livreur']),
      status: json['status'] as String? ?? 'available',
    );
  }

  static String? _livreurId(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (raw is num) return raw.toString();
    if (raw is Map) {
      final id = raw['id'] ?? raw['userId'];
      final asString = id?.toString().trim() ?? '';
      return asString.isEmpty ? null : asString;
    }
    final fallback = raw.toString().trim();
    return fallback.isEmpty ? null : fallback;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VehicleModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VehicleModel(id: $id, matricule: $matricule)';
}
