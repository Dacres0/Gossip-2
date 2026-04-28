import 'package:flutter/material.dart';
import 'package:gossip_app/models/app_notification.dart';
import 'package:gossip_app/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.userId,
    required this.notificationService,
  });

  final String userId;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await notificationService.markAllAsRead(userId);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: notificationService.streamNotifications(userId),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.06), height: 1),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.isRead
                      ? Colors.white.withOpacity(0.08)
                      : theme.colorScheme.primary.withOpacity(0.28),
                  child: Icon(_iconFor(item.type), size: 18),
                ),
                title: Text(item.title),
                subtitle: Text(item.body),
                trailing: Text(
                  _timeText(item.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'vote':
        return Icons.how_to_vote_outlined;
      case 'challenge':
        return Icons.emoji_events_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeText(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
