import 'dart:async';

import 'package:flutter/foundation.dart';

import 'notification_api_service.dart';

/// Polls the inbox so a new notification shows up without opening the tab.
class NotificationInbox extends ChangeNotifier {
  NotificationInbox({
    NotificationApiService? service,
    this.onArrived,
    Duration pollEvery = const Duration(seconds: 8),
  })  : _service = service ?? NotificationApiService(),
        _pollEvery = pollEvery;

  static final NotificationInbox instance = NotificationInbox();

  final NotificationApiService _service;
  final Duration _pollEvery;
  void Function(NotificationItem item)? onArrived;

  List<NotificationItem> items = const [];
  bool hasLoaded = false;
  bool get hasError => _error;
  int get unread => items.where((item) => !item.isRead).length;

  Timer? _timer;
  bool _inFlight = false;
  bool _primed = false;
  bool _error = false;
  int _generation = 0;
  final Set<String> _knownIds = {};

  void start() {
    if (_timer != null) return;
    unawaited(refresh());
    _timer = Timer.periodic(_pollEvery, (_) => refresh());
  }

  void stop() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _primed = false;
    _knownIds.clear();
    items = const [];
    hasLoaded = false;
    _error = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_inFlight) return;
    _inFlight = true;
    final generation = _generation;
    try {
      final list = await _service.listNotifications(fresh: true);
      if (generation != _generation) return;
      final arrived = _primed
          ? [
              for (final item in list)
                if (!_knownIds.contains(item.id) && !item.isRead) item,
            ]
          : const <NotificationItem>[];
      _knownIds
        ..clear()
        ..addAll(list.map((item) => item.id));
      _primed = true;
      items = list;
      hasLoaded = true;
      _error = false;
      notifyListeners();
      for (final item in arrived.take(3)) {
        onArrived?.call(item);
      }
    } catch (_) {
      _error = !hasLoaded;
      notifyListeners();
    } finally {
      _inFlight = false;
    }
  }

  void markReadLocal(String id) {
    items = [
      for (final item in items)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    notifyListeners();
  }

  void removeLocal(String id) {
    items = [for (final item in items) if (item.id != id) item];
    _knownIds.remove(id);
    notifyListeners();
  }
}
