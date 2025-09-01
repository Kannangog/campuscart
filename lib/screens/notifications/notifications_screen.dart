// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscart/utilities/app_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'New Order',
      'message': 'You have received a new order #1234',
      'time': '2 hours ago',
      'read': false,
    },
    {
      'id': '2',
      'title': 'Order Completed',
      'message': 'Order #1234 has been completed successfully',
      'time': '5 hours ago',
      'read': true,
    },
    {
      'id': '3',
      'title': 'New Review',
      'message': 'You have received a new 5-star review',
      'time': '1 day ago',
      'read': true,
    },
    {
      'id': '4',
      'title': 'System Update',
      'message': 'New features have been added to the restaurant dashboard',
      'time': '2 days ago',
      'read': true,
    },
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['read'] = true;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Clear All Notifications'),
          content: const Text('Are you sure you want to clear all notifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _notifications.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared')),
                );
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                  key: Key(notification['id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteNotification(notification['id']),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification['read']
                          ? theme.colorScheme.onSurface.withOpacity(0.2)
                          : theme.primaryColor,
                      child: Icon(
                        Icons.notifications,
                        color: notification['read']
                            ? theme.colorScheme.onSurface.withOpacity(0.5)
                            : Colors.white,
                      ),
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['read'] ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message']),
                        const SizedBox(height: 4),
                        Text(
                          notification['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    trailing: !notification['read']
                        ? IconButton(
                            icon: const Icon(Icons.mark_email_read),
                            onPressed: () => _markAsRead(notification['id']),
                            tooltip: 'Mark as read',
                          )
                        : null,
                    onTap: () {
                      if (!notification['read']) {
                        _markAsRead(notification['id']);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}