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

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<AppNotification>> _loadNotifications() async {
    final notifications = await _service.getNotifications();
    await _service.markAllAsRead();
    return notifications;
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
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  );
                }

                final notifications = snapshot.data!;
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
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
        const SizedBox(width: 16),
        const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
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
