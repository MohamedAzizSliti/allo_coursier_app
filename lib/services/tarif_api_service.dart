import '../models/tarif_model.dart';
import 'api_client.dart';

class TarifApiService {
  TarifApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  Future<List<TarifModel>> listTarifs() async {
    final list = await _api.getList('/tarifs');
    return list
        .whereType<Map>()
        .map((e) => TarifModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
