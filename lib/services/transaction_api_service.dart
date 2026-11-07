import 'api_client.dart';

class TransactionItem {
  final String id;
  final double montant;
  final String type;
  final DateTime date;

  const TransactionItem({
    required this.id,
    required this.montant,
    required this.type,
    required this.date,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id']?.toString() ?? '',
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String? ?? 'inconnu',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TransactionApiService {
  TransactionApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  /// GET /transactions — confirmed on live API (403 without auth).
  Future<List<TransactionItem>> listTransactions() async {
    final list = await _api.getList('/transactions');
    return list.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
