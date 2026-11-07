import 'api_client.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime sentAt;
  final String? orderId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.sentAt,
    this.orderId,
  });

  NotificationItem copyWith({bool? isRead, String? orderId}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt,
      orderId: orderId ?? this.orderId,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final order = json['orderId'] ?? json['order_id'];
    final orderId = order?.toString().trim();
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      isRead: _asBool(json['isRead'] ?? json['is_read']),
      sentAt: DateTime.tryParse(
            (json['sentAt'] ?? json['sent_at'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      orderId: (orderId == null || orderId.isEmpty) ? null : orderId,
    );
  }
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.toLowerCase().trim();
    return text == 'true' || text == '1';
  }
  return false;
}

/// Holds a device push token when a provider (FCM, etc.) supplies one.
class PushTokenHolder {
  static String? token;
}

class NotificationApiService {
  NotificationApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  Future<List<NotificationItem>> listNotifications({bool fresh = false}) async {
    final list = await _api.getList('/notifications', null, fresh);
    return list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }

  Future<void> markRead(String id) async {
    await _api.post('/notifications/$id/read');
  }

  Future<void> registerPushToken(String token, {String platform = 'android'}) async {
    await _api.post('/push-tokens', {'token': token, 'platform': platform});
  }

  /// No-op when no token is available (the app has no FCM SDK today).
  Future<void> registerPushTokenIfAvailable([String? token]) async {
    final value = token ?? PushTokenHolder.token;
    if (value == null || value.isEmpty) return;
    await registerPushToken(value);
  }
}
