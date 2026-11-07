import 'api_client.dart';

class PaymentApiService {
  PaymentApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  Future<Map<String, dynamic>> confirmPayments(List<String> orderIds) async {
    return _api.post('/payments/confirm', {'orderIds': orderIds});
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required String expediteurId,
  }) async {
    return _api.post('/payments/withdraw', {
      'expediteurId': expediteurId,
    });
  }
}
