import '../models/vehicle_model.dart';
import 'api_client.dart';

class VehicleApiService {
  VehicleApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  Future<List<VehicleModel>> listVehicles() async {
    final list = await _api.getList('/vehicles');
    return list.map((e) => VehicleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VehicleModel> getVehicle(String id) async {
    final data = await _api.get('/vehicles/$id');
    return VehicleModel.fromJson(data);
  }

  Future<VehicleModel> createVehicle({
    required String matricule,
    required String model,
  }) async {
    final data = await _api.post('/vehicles', {
      'matricule': matricule,
      'model': model,
    });
    return VehicleModel.fromJson(data);
  }

  Future<VehicleModel> updateVehicle(String id, Map<String, dynamic> body) async {
    final data = await _api.patch('/vehicles/$id', body);
    return VehicleModel.fromJson(data);
  }

  Future<VehicleModel> assignLivreur(String id, String livreurId) async {
    final data = await _api.post('/vehicles/$id/assign', {'livreurId': livreurId});
    return VehicleModel.fromJson(data);
  }

  Future<void> deleteVehicle(String id) async {
    await _api.delete('/vehicles/$id');
  }
}
