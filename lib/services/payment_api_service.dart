import 'api_client.dart';

class PayoutSums {
  const PayoutSums({
    required this.montantPaye,
    required this.montantReste,
    required this.unpaidCount,
    required this.paidCount,
  });

  final double montantPaye;
  final double montantReste;
  final int unpaidCount;
  final int paidCount;

  factory PayoutSums.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return PayoutSums(
      montantPaye: asDouble(json['montant_paye']),
      montantReste: asDouble(json['montant_reste']),
      unpaidCount: asInt(json['unpaidCount']),
      paidCount: asInt(json['paidCount']),
    );
  }
}

class PaymentApiService {
  PaymentApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  Future<Map<String, dynamic>> confirmPayments(
    List<String> orderIds, {
    double? amount,
  }) async {
    return _api.post('/payments/confirm', {
      'orderIds': orderIds,
      if (amount != null) 'amount': amount,
    });
  }

  /// Net Mon argent totals (`GET /payments/payout-sums`).
  Future<PayoutSums> getPayoutSums({String? expediteurId}) async {
    final query = <String, dynamic>{
      if (expediteurId != null && expediteurId.trim().isNotEmpty)
        'expediteurId': expediteurId.trim(),
    };
    final data = await _api.get('/payments/payout-sums', query);
    return PayoutSums.fromJson(data);
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required String expediteurId,
  }) async {
    return _api.post('/payments/withdraw', {
      'expediteurId': expediteurId,
    });
  }
}
