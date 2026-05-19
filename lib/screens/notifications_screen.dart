// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onNotificationRead;

  const NotificationsScreen({super.key, this.onNotificationRead});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _notificationService.getNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    await _loadNotifications();
    widget.onNotificationRead?.call();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.clearAll();
      await _loadNotifications();
      widget.onNotificationRead?.call();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Notifications will appear here',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Dismissible(
                      key: Key(notification.id),
                      background: Container(color: Colors.red),
                      onDismissed: (_) async {
                        await _notificationService.deleteNotification(notification.id);
                        await _loadNotifications();
                        widget.onNotificationRead?.call();
                      },
                      child: InkWell(
                        onTap: () async {
                          if (!notification.isRead) {
                            await _notificationService.markAsRead(notification.id);
                            await _loadNotifications();
                            widget.onNotificationRead?.call();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? null
                                : (isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05)),
                            border: Border(
                              bottom: BorderSide(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: _getIconForType(notification.type, isDarkMode),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.message),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(notification.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: notification.isRead
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Icon _getIconForType(String type, bool isDarkMode) {
    switch (type) {
      case 'dry_pattern':
        return Icon(Icons.warning, color: Colors.orange);
      case 'weekly_checkin':
        return Icon(Icons.calendar_today, color: Colors.green);
      default:
        return Icon(Icons.notifications, color: isDarkMode ? Colors.white70 : Colors.black54);
    }
  }
}