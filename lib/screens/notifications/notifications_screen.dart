// notifications_screen.dart
import 'package:campuscart/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscart/utilities/app_theme.dart';
import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  void _markAsRead(String notificationId) {
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.markAsRead(notificationId);
  }

  void _markAllAsRead(String userId) {
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.markAllAsRead(userId);
  }

  void _deleteNotification(String notificationId) {
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.deleteNotification(notificationId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  void _clearAllNotifications(String userId) {
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
                final notificationService = ref.read(notificationServiceProvider);
                notificationService.clearAllNotifications(userId);
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

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please login to view notifications')),
      );
    }

    final notificationsAsync = ref.watch(notificationListProvider(user.uid));
    final unreadCountAsync = ref.watch(unreadCountProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          // Mark all as read button - only show if there are unread notifications
          if (unreadCountAsync.valueOrNull != null && unreadCountAsync.value! > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: () => _markAllAsRead(user.uid),
              tooltip: 'Mark all as read',
            ),
          // Clear all button - only show if there are notifications
          if (notificationsAsync.valueOrNull != null && notificationsAsync.value!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _clearAllNotifications(user.uid),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          print('Error loading notifications: $error');
          print('Stack trace: $stack');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notifications',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
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
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New orders and updates will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Unread count badge
              if (unreadCountAsync.valueOrNull != null && unreadCountAsync.value! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: theme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${unreadCountAsync.value} unread notification${unreadCountAsync.value! > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // Notifications list
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    
                    return Dismissible(
                      key: Key(notification.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _deleteNotification(notification.id),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notification.read
                              ? theme.colorScheme.onSurface.withOpacity(0.2)
                              : theme.primaryColor,
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: notification.read
                                ? theme.colorScheme.onSurface.withOpacity(0.5)
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.message),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(Timestamp.fromDate(notification.createdAt)),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        trailing: !notification.read
                            ? IconButton(
                                icon: const Icon(Icons.mark_email_read),
                                onPressed: () => _markAsRead(notification.id),
                                tooltip: 'Mark as read',
                              )
                            : null,
                        onTap: () {
                          if (!notification.read) {
                            _markAsRead(notification.id);
                          }
                          // You can add navigation to relevant screens here based on notification type
                          _handleNotificationTap(notification);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'new_order':
        // Navigate to order details screen
        // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: notification.data['orderId'])));
        break;
      case 'order_status_update':
        // Navigate to order details screen
        // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: notification.data['orderId'])));
        break;
      default:
        // Do nothing or handle other notification types
        break;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_bag;
      case 'order_status_update':
        return Icons.delivery_dining;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}