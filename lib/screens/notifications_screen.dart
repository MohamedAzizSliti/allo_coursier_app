import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../services/notification_api_service.dart';
import '../services/notification_inbox.dart';
import '../services/session_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import 'agent/commande_details_screen.dart';
import 'business_client/order_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.active = true, this.service});

  final bool active;
  final NotificationApiService? service;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationApiService _notifService =
      widget.service ?? NotificationApiService();

  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;

  bool get _live => widget.service == null;

  @override
  void initState() {
    super.initState();
    if (_live) {
      final inbox = NotificationInbox.instance;
      _notifications = inbox.items;
      _isLoading = !inbox.hasLoaded;
      inbox.addListener(_syncInbox);
    } else {
      _fetchNotifications(blocking: true);
    }
  }

  @override
  void dispose() {
    if (_live) NotificationInbox.instance.removeListener(_syncInbox);
    super.dispose();
  }

  @override
  void didUpdateWidget(NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      if (_live) {
        NotificationInbox.instance.refresh();
      } else {
        _fetchNotifications();
      }
    }
  }

  void _syncInbox() {
    final inbox = NotificationInbox.instance;
    if (!mounted) return;
    setState(() {
      _notifications = inbox.items;
      _isLoading = !inbox.hasLoaded;
      _error = inbox.hasError ? context.s.cannotLoadNotifications : null;
    });
  }

  Future<void> _fetchNotifications({bool blocking = false}) async {
    final showSpinner = blocking && _notifications.isEmpty;
    if (showSpinner && mounted) setState(() => _isLoading = true);
    try {
      final notifications = await _notifService.listNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = context.s.cannotLoadNotifications;
        });
      }
    }
  }

  Future<void> _markRead(NotificationItem notif, int index) async {
    if (notif.isRead) return;
    try {
      await _notifService.markRead(notif.id);
      if (!mounted) return;
      if (_live) {
        NotificationInbox.instance.markReadLocal(notif.id);
      } else if (mounted) {
        setState(() {
          _notifications[index] = notif.copyWith(isRead: true);
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.cannotMarkRead)),
      );
    }
  }

  Future<void> _open(NotificationItem notif, int index) async {
    await _markRead(notif, index);
    final orderId = notif.orderId;
    if (orderId == null || orderId.isEmpty || !mounted) return;
    final role = SessionController.instance.role;
    final page = role == 'business_client'
        ? OrderDetailsScreen(orderId: orderId)
        : CommandeDetailsScreen(commandeId: orderId);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _deleteNotification(String id, int index) async {
    try {
      await _notifService.deleteNotification(id);
      if (!mounted) return;
      if (_live) {
        NotificationInbox.instance.removeLocal(id);
      } else if (mounted) {
        setState(() => _notifications.removeAt(index));
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.s.notificationDeleted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.s.cannotDeleteNotification),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null && _notifications.isEmpty) {
      return ErrorBanner(
        message: _error!,
        onRetry: () => _live
            ? NotificationInbox.instance.refresh()
            : _fetchNotifications(blocking: true),
      );
    }
    if (_notifications.isEmpty) {
      if (_isLoading) return const SizedBox.shrink();
      return EmptyState(
        message: context.s.notificationsNone,
        icon: Icons.notifications_off_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _live ? NotificationInbox.instance.refresh : _fetchNotifications,
      child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];

                  return Dismissible(
                    key: Key(notif.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    onDismissed: (_) => _deleteNotification(notif.id, index),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: notif.isRead
                              ? Colors.grey
                              : Colors.brown,
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: notif.isRead ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text(
                              notif.body,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(notif.sentAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: notif.isRead
                            ? const Icon(Icons.check_circle, color: Colors.grey)
                            : const Icon(
                                Icons.circle,
                                color: Colors.brown,
                                size: 12,
                              ),
                        onTap: () => _open(notif, index),
                      ),
                    ),
                  );
                },
      ),
    );
  }
}
