import '../domain/circuit_sheet.dart';
import 'api_client.dart';

class CircuitApiService {
  CircuitApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  /// Stable sheet number for one vehicle on one day, for example `BL0007`.
  Future<String> bonLivraison({
    required String vehicleId,
    required String day,
  }) async {
    final data = await _api.post('/circuits/bon', {
      'vehicleId': vehicleId,
      'day': day,
    });
    return resolveBonLabel(data);
  }
}

/// Prefer API `label`; fall back to formatting numeric `id`.
String resolveBonLabel(Map<String, dynamic> data) {
  final label = data['label']?.toString().trim() ?? '';
  if (label.isNotEmpty) return label;

  final id = data['id'];
  if (id is num) return formatBonLivraison(id.toInt());
  final parsed = int.tryParse(id?.toString() ?? '');
  if (parsed != null) return formatBonLivraison(parsed);

  throw const AlloException('unknown', 'Bon de livraison manquant.');
}
