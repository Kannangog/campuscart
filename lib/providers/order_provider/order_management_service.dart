// ignore_for_file: avoid_print

import 'dart:async';
import 'package:campuscart/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_error_handler.dart';
import 'notification_service.dart';

// Constants
const _orderAcceptanceTimeout = Duration(hours: 3);
const _autoCancelCheckInterval = Duration(minutes: 5);
const _maxRetries = 3;

// Track sent notifications to prevent duplicates
final _sentNotifications = <String, bool>{};

// Order Management Service
final orderManagementProvider = Provider<OrderManagementService>((ref) {
  return OrderManagementService(ref);
});

class OrderManagementService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _autoCancelTimer;

  OrderManagementService(this.ref) {
    _startAutoCancelTimer();
  }

  void _startAutoCancelTimer() {
    _autoCancelTimer = Timer.periodic(_autoCancelCheckInterval, (_) {
      _checkAndCancelExpiredOrders();
    });
  }

  Future<void> _checkAndCancelExpiredOrders() async {
    try {
      final threeHoursAgo = DateTime.now().subtract(_orderAcceptanceTimeout);
      final snapshot = await _firestore.collection('orders').get();
      
      for (final doc in snapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        final orderCreatedAt = order.createdAt;
        
        if (orderCreatedAt.isBefore(threeHoursAgo)) {
          if (order.status == OrderStatus.pending) {
            await _autoCancelOrder(order, 'Order was not accepted within 3 hours');
          } else if (_isProcessing(order.status)) {
            await _autoCancelOrder(order, 'Order was not delivered within 3 hours');
          }
        }
      }
    } catch (e) {
      print('Auto-cancellation check error: $e');
    }
  }

  bool _isProcessing(OrderStatus status) {
    return status == OrderStatus.confirmed || 
           status == OrderStatus.outForDelivery;
  }

  Future<void> _autoCancelOrder(OrderModel order, String reason) async {
    try {
      if (order.status != OrderStatus.cancelled && order.status != OrderStatus.delivered) {
        await _firestore.collection('orders').doc(order.id).update({
          'status': OrderStatus.cancelled.toString().split('.').last,
          'cancellationReason': 'Auto-cancelled: $reason',
          'updatedAt': Timestamp.now(),
          'cancelledAt': Timestamp.now(),
          'cancelledBy': 'system',
        });
        
        await _sendAutoCancellationNotification(order, reason);
      }
    } catch (e) {
      print('Auto-cancel error ${order.id}: $e');
    }
  }

  Future<void> _sendAutoCancellationNotification(OrderModel order, String reason) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.sendNotificationToUser(
        userId: order.userId,
        title: 'Order Auto-Cancelled',
        message: 'Your order #${_getOrderShortId(order.id)} was automatically cancelled: $reason',
        type: 'order_cancelled',
        data: {
          'orderId': order.id,
          'screen': 'order_details',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'userType': 'customer',
        },
      );
    } catch (e) {
      print('Auto-cancellation notification error: $e');
    }
  }

  String _getOrderShortId(String orderId) => orderId.substring(0, 8);

  Future<void> _sendNewOrderNotification(OrderModel order) async {
    try {
      final notificationKey = 'new_order_${order.id}';
      if (_sentNotifications.containsKey(notificationKey)) {
        return;
      }

      final restaurantDoc = await _firestore
          .collection('restaurants')
          .doc(order.restaurantId)
          .get();
      
      if (restaurantDoc.exists) {
        final restaurantData = restaurantDoc.data()!;
        final restaurantOwnerId = restaurantData['ownerId'];
        
        if (restaurantOwnerId == null) {
          return;
        }

        final notificationService = ref.read(notificationServiceProvider);
        final orderShortId = _getOrderShortId(order.id);
        
        await notificationService.sendNotificationToUser(
          userId: restaurantOwnerId,
          title: 'New Order Received! 🎉',
          message: 'You have a new order #$orderShortId from ${order.customerName}',
          type: 'new_order_restaurant',
          data: {
            'orderId': order.id,
            'orderNumber': orderShortId.toUpperCase(),
            'customerName': order.customerName,
            'itemCount': order.items.length,
            'total': order.total.toStringAsFixed(2),
            'screen': 'restaurant_orders',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'userType': 'restaurant_owner',
          },
        );

        _sentNotifications[notificationKey] = true;
      }
    } catch (e) {
      print('New order notification error: $e');
    }
  }

  Future<void> _sendOrderStatusUpdateNotification(OrderModel order, OrderStatus newStatus) async {
    try {
      if (!_shouldSendStatusNotification(newStatus)) {
        return;
      }

      final notificationConfig = _getNotificationConfig(order, newStatus);
      if (notificationConfig == null) return;

      final notificationKey = 'status_${order.id}_${newStatus.toString()}';
      if (_sentNotifications.containsKey(notificationKey)) {
        return;
      }

      final notificationService = ref.read(notificationServiceProvider);
      
      bool success = await notificationService.sendNotificationToUser(
        userId: notificationConfig.userId,
        title: notificationConfig.title,
        message: notificationConfig.message,
        type: notificationConfig.type,
        data: notificationConfig.data,
      );

      if (success) {
        _sentNotifications[notificationKey] = true;
      }
    } catch (e) {
      print('Status notification error: $e');
    }
  }

  bool _shouldSendStatusNotification(OrderStatus status) {
    // Only send notifications for these key status changes
    return status == OrderStatus.confirmed ||
           status == OrderStatus.outForDelivery ||
           status == OrderStatus.delivered ||
           status == OrderStatus.cancelled;
  }

  _NotificationConfig? _getNotificationConfig(OrderModel order, OrderStatus newStatus) {
    final orderShortId = _getOrderShortId(order.id);
    
    switch (newStatus) {
      case OrderStatus.confirmed:
        return _NotificationConfig(
          order.userId,
          'customer',
          'Order Confirmed! ✅',
          'Your order #$orderShortId has been confirmed by the restaurant.',
          'order_confirmed',
          {
            'orderId': order.id,
            'orderNumber': orderShortId.toUpperCase(),
            'status': newStatus.toString().split('.').last,
            'screen': 'order_details',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'userType': 'customer',
          }
        );
      
      case OrderStatus.outForDelivery:
        return _NotificationConfig(
          order.userId,
          'customer',
          'Order Out for Delivery! 🚚',
          'Your order #$orderShortId is on its way to you.',
          'order_out_for_delivery',
          {
            'orderId': order.id,
            'orderNumber': orderShortId.toUpperCase(),
            'status': newStatus.toString().split('.').last,
            'screen': 'order_details',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'userType': 'customer',
          }
        );
      
      case OrderStatus.delivered:
        return _NotificationConfig(
          order.userId,
          'customer',
          'Order Delivered! 🎊',
          'Your order #$orderShortId has been delivered. Enjoy your meal!',
          'order_delivered',
          {
            'orderId': order.id,
            'orderNumber': orderShortId.toUpperCase(),
            'status': newStatus.toString().split('.').last,
            'screen': 'order_details',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'userType': 'customer',
          }
        );
      
      case OrderStatus.cancelled:
        final isCancelledByCustomer = order.cancelledBy == order.userId;
        if (isCancelledByCustomer) {
          return _getRestaurantCancellationConfig(order);
        } else {
          return _NotificationConfig(
            order.userId,
            'customer',
            'Order Cancelled ❌',
            'Your order #$orderShortId has been cancelled.',
            'order_cancelled',
            {
              'orderId': order.id,
              'orderNumber': orderShortId.toUpperCase(),
              'status': newStatus.toString().split('.').last,
              'screen': 'order_details',
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              'userType': 'customer',
            }
          );
        }
      
      default:
        return null;
    }
  }

  _NotificationConfig _getRestaurantCancellationConfig(OrderModel order) {
    final orderShortId = _getOrderShortId(order.id);
    
    return _NotificationConfig(
      _getRestaurantOwnerId(order.restaurantId),
      'restaurant_owner',
      'Order Cancelled by Customer ❌',
      'Order #$orderShortId from ${order.customerName} has been cancelled.',
      'order_cancelled_restaurant',
      {
        'orderId': order.id,
        'orderNumber': orderShortId.toUpperCase(),
        'customerName': order.customerName,
        'screen': 'restaurant_orders',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'userType': 'restaurant_owner',
      }
    );
  }

  String _getRestaurantOwnerId(String restaurantId) {
    return '';
  }

  void dispose() {
    _autoCancelTimer?.cancel();
    _sentNotifications.clear();
  }

  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await _firestore.collection('orders').add(order.toFirestore());
      final orderId = docRef.id;
      
      await _firestore.collection('orders').doc(orderId).update({'id': orderId});
      
      final createdOrder = order.copyWith(id: orderId);

      _sendNewOrderNotification(createdOrder);
      
      return orderId;
    } catch (e) {
      print('Order creation error: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status, {int retryCount = 0}) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      };

      if (status == OrderStatus.confirmed) {
        updates['estimatedDeliveryTime'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 30)),
        );
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
      
      await _sendStatusUpdateNotification(orderId, status);
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return updateOrderStatus(orderId, status, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> _sendStatusUpdateNotification(String orderId, OrderStatus status) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final order = OrderModel.fromFirestore(orderDoc);
        await _sendOrderStatusUpdateNotification(order, status);
      }
    } catch (e) {
      print('Status update notification error: $e');
    }
  }

  bool _shouldRetry(dynamic error, int retryCount) {
    return error is FirebaseException && 
           FirestoreErrorHandler.isIndexError(error) && 
           retryCount < _maxRetries;
  }

  Future<void> cancelOrder(String orderId, String reason, {String? cancelledBy, int retryCount = 0}) async {
    try {
      final updateData = {
        'status': OrderStatus.cancelled.toString().split('.').last,
        'cancellationReason': reason,
        'updatedAt': Timestamp.now(),
        'cancelledAt': Timestamp.now(),
      };
      
      if (cancelledBy != null) {
        updateData['cancelledBy'] = cancelledBy;
      }
      
      await _firestore.collection('orders').doc(orderId).update(updateData);
      await _sendStatusUpdateNotification(orderId, OrderStatus.cancelled);
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return cancelOrder(orderId, reason, cancelledBy: cancelledBy, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> assignDriver(String orderId, String driverId, {int retryCount = 0}) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'driverId': driverId,
        'status': OrderStatus.outForDelivery.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });

      await _sendStatusUpdateNotification(orderId, OrderStatus.outForDelivery);
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return assignDriver(orderId, driverId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> markAsDelivered(String orderId, {int retryCount = 0}) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.delivered.toString().split('.').last,
        'deliveredAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await _sendStatusUpdateNotification(orderId, OrderStatus.delivered);
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return markAsDelivered(orderId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderAnalytics(String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    int retryCount = 0,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      var orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      
      if (startDate != null) {
        orders = orders.where((order) => order.createdAt.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        orders = orders.where((order) => order.createdAt.isBefore(endDate)).toList();
      }

      return _calculateOrderAnalytics(orders);
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return getOrderAnalytics(restaurantId, 
          startDate: startDate, 
          endDate: endDate, 
          retryCount: retryCount + 1
        );
      }
      rethrow;
    }
  }

  Map<String, dynamic> _calculateOrderAnalytics(List<OrderModel> orders) {
    double totalRevenue = 0;
    int totalOrders = orders.length;
    int completedOrders = 0;
    int cancelledOrders = 0;
    final itemCounts = <String, int>{};

    for (final order in orders) {
      if (order.status == OrderStatus.delivered) {
        totalRevenue += order.total;
        completedOrders++;
      } else if (order.status == OrderStatus.cancelled) {
        cancelledOrders++;
      }

      for (final item in order.items) {
        itemCounts[item.name] = (itemCounts[item.name] ?? 0) + item.quantity;
      }
    }

    final topItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'averageOrderValue': completedOrders > 0 ? totalRevenue / completedOrders : 0,
      'completionRate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
      'cancellationRate': totalOrders > 0 ? (cancelledOrders / totalOrders) * 100 : 0,
      'topSellingItems': topItems.take(5).map((e) => {
        'name': e.key,
        'count': e.value,
      }).toList(),
    };
  }

  Future<List<OrderModel>> getOrdersByStatus(String restaurantId, OrderStatus status, {int retryCount = 0}) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: _statusToString(status))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return getOrdersByStatus(restaurantId, status, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  String _statusToString(OrderStatus status) {
    return status.toString().split('.').last;
  }

  Future<List<OrderModel>> getRestaurantOrders(String restaurantId, {int retryCount = 0}) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return getRestaurantOrders(restaurantId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> updateOrderStatusWithReason(String orderId, OrderStatus newStatus, String reason, {String? cancelledBy}) async {
    try {
      final updates = <String, dynamic>{
        'status': _statusToString(newStatus),
        'updatedAt': Timestamp.now(),
      };

      if (reason.isNotEmpty) {
        updates['cancellationReason'] = reason;
      }

      if (newStatus == OrderStatus.cancelled) {
        updates['cancelledAt'] = Timestamp.now();
        if (cancelledBy != null) {
          updates['cancelledBy'] = cancelledBy;
        }
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
      await _sendStatusUpdateNotification(orderId, newStatus);
    } catch (e) {
      rethrow;
    }
  }
}

class _NotificationConfig {
  final String userId;
  final String userType;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> data;

  _NotificationConfig(
    this.userId,
    this.userType,
    this.title,
    this.message,
    this.type,
    this.data
  );
}