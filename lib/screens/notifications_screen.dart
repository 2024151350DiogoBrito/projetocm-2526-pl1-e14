import 'dart:async';

import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  late Future<List<AppNotification>> _notificationsFuture;
  final List<AppNotification> _localNotifications = [];
  bool _isCreatingDemo = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<AppNotification>> _loadNotifications() async {
    final notifications = await _service.getNotifications().timeout(
      const Duration(seconds: 25),
    );
    unawaited(_service.markAllAsRead().catchError((_) {}));
    return notifications;
  }

  Future<void> _createDemoNotification() async {
    if (_isCreatingDemo) return;
    setState(() {
      _isCreatingDemo = true;
      _localNotifications.insert(0, _service.createDemoNotification());
    });

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _isCreatingDemo = false);
  }

  Future<void> _clearNotifications() async {
    if (_isClearing) return;
    setState(() {
      _isClearing = true;
      _localNotifications.clear();
      _notificationsFuture = Future.value([]);
    });

    try {
      await _service.clearNotifications().timeout(const Duration(seconds: 15));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível limpar as notificações.'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          Expanded(
            child: FutureBuilder<List<AppNotification>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _errorState();
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  );
                }

                final notifications = _mergeNotifications(snapshot.data!);
                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ainda não tens notificações.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) =>
                      _notificationTile(notifications[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'NOTIFICATIONS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _isCreatingDemo ? null : _createDemoNotification,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryRed,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'DEMO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Limpar notificações',
          onPressed: _isClearing ? null : _clearNotifications,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white54,
            size: 19,
          ),
        ),
      ],
    ),
  );

  List<AppNotification> _mergeNotifications(List<AppNotification> remote) {
    final byId = <String, AppNotification>{};
    for (final notification in remote) {
      byId[notification.id] = notification;
    }
    for (final notification in _localNotifications.reversed) {
      byId[notification.id] = notification;
    }

    final merged = byId.values.toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppTheme.primaryRed,
            size: 36,
          ),
          const SizedBox(height: 14),
          const Text(
            'Não foi possível carregar as notificações.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _notificationsFuture = _loadNotifications();
              });
            },
            child: const Text('TENTAR NOVAMENTE'),
          ),
        ],
      ),
    ),
  );

  Widget _notificationTile(AppNotification notification) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: notification.read
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.primaryRed.withValues(alpha: 0.45),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            notification.type == 'season'
                ? Icons.tv_rounded
                : Icons.local_movies_rounded,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                notification.message,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
