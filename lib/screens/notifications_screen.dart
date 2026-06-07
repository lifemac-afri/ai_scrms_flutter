import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final n = await ApiService.notifications();
    await ApiService.markRead();
    if (mounted) setState(() { _notifs = n; _loading = false; });
  }

  IconData _icon(String type) => switch (type) {
    'booking_confirmed' => Icons.check_circle_rounded,
    'waitlist_added' => Icons.hourglass_top_rounded,
    'waitlist_promoted' => Icons.celebration_rounded,
    'system_alert' => Icons.warning_amber_rounded,
    _ => Icons.notifications_rounded,
  };

  Color _color(String type) => switch (type) {
    'booking_confirmed' => AppTheme.green,
    'waitlist_added' => AppTheme.amber,
    'waitlist_promoted' => AppTheme.teal,
    'system_alert' => AppTheme.red,
    _ => AppTheme.blue,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget();
    if (_notifs.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No Notifications',
        subtitle: 'You\'re all caught up!',
      );
    }
    return RefreshIndicator(
      color: AppTheme.teal,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifs.length,
        itemBuilder: (_, i) {
          final n = _notifs[i];
          final color = _color(n.notificationType);
          return Dismissible(
            key: Key(n.notificationId.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: AppTheme.red,
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() {
                _notifs.removeAt(i);
              });
              // In a real app, call API to delete notification
            },
            child: AppCard(
              borderColor: n.isRead ? null : color.withValues(alpha: 0.3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(_icon(n.notificationType), color: color, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.notificationType.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(n.messageBody,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(n.createdAt,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
