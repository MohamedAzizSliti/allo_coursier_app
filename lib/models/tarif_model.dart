/// Tarif model matching the API schema.
///
/// Fields: `id`, `type` (zone name), `prix`, `prix_retour`.
class TarifModel {
  final String id;
  final String type;
  final double prix;
  final double prixRetour;

  const TarifModel({
    required this.id,
    required this.type,
    required this.prix,
    required this.prixRetour,
  });

  factory TarifModel.fromJson(Map<String, dynamic> json) {
    return TarifModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? json['zone']?.toString() ?? '',
      prix: (json['prix'] as num?)?.toDouble() ??
          double.tryParse(json['prix']?.toString() ?? '') ??
          0.0,
      prixRetour: (json['prix_retour'] as num?)?.toDouble() ??
          (json['prixRetour'] as num?)?.toDouble() ??
          0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TarifModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
