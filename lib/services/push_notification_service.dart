import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Status-bar notifications for Allo Coursier.
///
/// The phone shows these in the shade and as a heads-up alert. FCM delivery
/// while the app is closed still depends on a registered device token.
class PushNotificationService {
  PushNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _localNotifications = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'allo_coursier_channel';

  final FlutterLocalNotificationsPlugin _localNotifications;
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    const androidSettings = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        'Allo Coursier',
        description: 'Colis, paiements et livraisons',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android?.requestNotificationsPermission();
    _ready = true;
  }

  /// Shows a notification in the phone's status bar.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    if (title.trim().isEmpty && body.trim().isEmpty) return;
    await initialize();
    await _localNotifications.show(
      id ?? title.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Allo Coursier',
          channelDescription: 'Colis, paiements et livraisons',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_stat_notify',
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
