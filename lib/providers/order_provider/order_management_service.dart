// ignore_for_file: avoid_print

import 'dart:async';
import 'package:campuscart/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_error_handler.dart';
import 'notification_service.dart';

// Constants
const _orderAcceptanceTimeout = Duration(hours: 3);
const _autoCancelCheckInterval = Duration(minutes: 5);
const _maxRetries = 3;

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
      print('Error in auto-cancellation check: $e');
    }
  }

  bool _isProcessing(OrderStatus status) {
    return status == OrderStatus.confirmed || 
           status == OrderStatus.preparing || 
           status == OrderStatus.ready || 
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
        
        print('Automatically cancelled order ${order.id}: $reason');
        await _sendAutoCancellationNotification(order, reason);
      }
    } catch (e) {
      print('Error auto-cancelling order ${order.id}: $e');
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
      print('Error sending auto-cancellation notification: $e');
    }
  }

  String _getOrderShortId(String orderId) => orderId.substring(0, 8);

  // ✅ FIXED: Properly placed _sendNewOrderNotification method
  Future<void> _sendNewOrderNotification(OrderModel order) async {
    try {
      final restaurantDoc = await _firestore
          .collection('restaurants')
          .doc(order.restaurantId)
          .get();
      
      if (restaurantDoc.exists) {
        final restaurantName = restaurantDoc.data()?['name'] ?? 'Restaurant';
        final notificationService = ref.read(notificationServiceProvider);
        final orderShortId = _getOrderShortId(order.id);
        
        print('📤 Preparing to send notifications for order: ${order.id}');
        
        // ✅ FIXED: Check and save tokens with error handling
        try {
          final customerTokens = await notificationService.getUserFCMTokens(order.userId);
          if (customerTokens.isEmpty) {
            print('🚨 No tokens found for customer, saving token...');
            await notificationService.saveFCMToken(order.userId, userType: 'customer');
          } else {
            print('✅ Customer has ${customerTokens.length} tokens');
          }
        } catch (e) {
          print('⚠️ Error checking customer tokens: $e');
        }
        
        try {
          final restaurantTokens = await notificationService.getUserFCMTokens(order.restaurantId);
          if (restaurantTokens.isEmpty) {
            print('🚨 No tokens found for restaurant, attempting to save...');
            // Use the regular save method first
            bool success = await notificationService.saveFCMToken(order.restaurantId, userType: 'restaurant_owner');
            if (!success) {
              print('🔄 Trying alternative save method for restaurant...');
              // Fallback: Save only to users collection
              await _saveRestaurantTokenFallback(order.restaurantId);
            }
          } else {
            print('✅ Restaurant has ${restaurantTokens.length} tokens');
          }
        } catch (e) {
          print('⚠️ Error checking restaurant tokens: $e');
        }
        
        // Send customer notification
        bool customerSuccess = false;
        try {
          customerSuccess = await notificationService.sendNotificationToUser(
            userId: order.userId,
            title: 'Order Placed Successfully! 🎉',
            message: 'Your order has been placed at $restaurantName. Order ID: #$orderShortId',
            type: 'order_placed',
            data: {
              'orderId': order.id,
              'orderNumber': orderShortId.toUpperCase(),
              'restaurantName': restaurantName,
              'screen': 'order_details',
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              'userType': 'customer',
            },
          );
        } catch (e) {
          print('❌ Error sending customer notification: $e');
        }

        // Send restaurant notification
        bool restaurantSuccess = false;
        try {
          restaurantSuccess = await notificationService.sendNotificationToUser(
            userId: order.restaurantId,
            title: 'New Order Received! 📦',
            message: 'You have a new order #$orderShortId from ${order.customerName}',
            type: 'new_order_restaurant',
            data: {
              'orderId': order.id,
              'orderNumber': orderShortId.toUpperCase(),
              'customerName': order.customerName,
              'itemCount': order.items.length,
              'total': order.total,
              'screen': 'restaurant_orders',
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              'userType': 'restaurant',
            },
          );
        } catch (e) {
          print('❌ Error sending restaurant notification: $e');
        }

        print('🎯 Order notification results:');
        print('   Customer: ${customerSuccess ? 'SUCCESS' : 'FAILED'}');
        print('   Restaurant: ${restaurantSuccess ? 'SUCCESS' : 'FAILED'}');
        
        // ✅ FIXED: Always create notification documents even if push fails
        await _createNotificationDocuments(order, restaurantName, orderShortId, customerSuccess, restaurantSuccess);
      }
    } catch (e) {
      print('❌ Error in _sendNewOrderNotification: $e');
    }
  }

  // ✅ NEW: Fallback method for restaurant token saving
  Future<void> _saveRestaurantTokenFallback(String restaurantId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('🔄 Fallback: Saving restaurant token to users collection only');
        await _firestore.collection('users').doc(restaurantId).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'userType': 'restaurant_owner',
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
        print('✅ Fallback save completed for restaurant');
      }
    } catch (e) {
      print('❌ Fallback save also failed: $e');
    }
  }

  // ✅ NEW: Create notification documents in Firestore
  Future<void> _createNotificationDocuments(OrderModel order, String restaurantName, String orderShortId, bool customerSuccess, bool restaurantSuccess) async {
    try {
      // Customer notification document
      await _firestore.collection('notifications').add({
        'userId': order.userId,
        'title': 'Order Placed Successfully! 🎉',
        'message': 'Your order has been placed at $restaurantName. Order ID: #$orderShortId',
        'type': 'order_placed',
        'data': {
          'orderId': order.id,
          'orderNumber': orderShortId.toUpperCase(),
          'restaurantName': restaurantName,
          'screen': 'order_details',
        },
        'read': false,
        'createdAt': Timestamp.now(),
        'userType': 'customer',
        'pushSent': customerSuccess,
      });

      // Restaurant notification document
      await _firestore.collection('notifications').add({
        'userId': order.restaurantId,
        'title': 'New Order Received! 📦',
        'message': 'You have a new order #$orderShortId from ${order.customerName}',
        'type': 'new_order_restaurant',
        'data': {
          'orderId': order.id,
          'orderNumber': orderShortId.toUpperCase(),
          'customerName': order.customerName,
          'itemCount': order.items.length,
          'total': order.total,
          'screen': 'restaurant_orders',
        },
        'read': false,
        'createdAt': Timestamp.now(),
        'userType': 'restaurant_owner',
        'pushSent': restaurantSuccess,
      });

      print('✅ Notification documents created in Firestore');
    } catch (e) {
      print('❌ Error creating notification documents: $e');
    }
  }

  // Send order status update notifications
  Future<void> _sendOrderStatusUpdateNotification(OrderModel order, OrderStatus newStatus) async {
    try {
      final notificationConfig = _getNotificationConfig(order, newStatus);
      if (notificationConfig == null) return;

      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.sendNotificationToUser(
        userId: order.userId,
        title: notificationConfig.title,
        message: notificationConfig.message,
        type: notificationConfig.type,
        data: {
          'orderId': order.id,
          'orderNumber': _getOrderShortId(order.id).toUpperCase(),
          'status': newStatus.toString().split('.').last,
          'screen': 'order_details',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'userType': 'customer',
        },
      );

      print('Sent order status update notification for order ${order.id}');
    } catch (e) {
      print('Error sending order status update notification: $e');
    }
  }

  _NotificationConfig? _getNotificationConfig(OrderModel order, OrderStatus newStatus) {
    final orderShortId = _getOrderShortId(order.id);
    switch (newStatus) {
      case OrderStatus.confirmed:
        return _NotificationConfig(
          'Order Confirmed! ✅',
          'Your order #$orderShortId has been confirmed by the restaurant.',
          'order_status_update'
        );
      case OrderStatus.preparing:
        return _NotificationConfig(
          'Cooking Started! 👨‍🍳',
          'Your order #$orderShortId is now being prepared.',
          'order_status_update'
        );
      case OrderStatus.ready:
        return _NotificationConfig(
          'Order Ready! 🎉',
          'Your order #$orderShortId is ready for pickup/delivery.',
          'order_status_update'
        );
      case OrderStatus.outForDelivery:
        return _NotificationConfig(
          'Order Out for Delivery! 🚚',
          'Your order #$orderShortId is on its way to you.',
          'order_status_update'
        );
      case OrderStatus.delivered:
        return _NotificationConfig(
          'Order Delivered! 🎊',
          'Your order #$orderShortId has been delivered. Enjoy your meal!',
          'order_status_update'
        );
      case OrderStatus.cancelled:
        return _NotificationConfig(
          'Order Cancelled ❌',
          'Your order #$orderShortId has been cancelled.',
          'order_cancelled'
        );
      default:
        return null;
    }
  }

  void dispose() {
    _autoCancelTimer?.cancel();
  }

  // ✅ FIXED: Core order operations with better error handling
  Future<String> createOrder(OrderModel order) async {
    try {
      print('🛒 Creating new order...');
      
      // Create the order document
      final docRef = await _firestore.collection('orders').add(order.toFirestore());
      final orderId = docRef.id;
      
      // Update with the ID
      await _firestore.collection('orders').doc(orderId).update({'id': orderId});
      
      final createdOrder = order.copyWith(id: orderId);
      print('✅ Order created successfully: $orderId');

      // Send notifications (non-blocking)
      _sendNewOrderNotification(createdOrder);
      
      return orderId;
    } catch (e) {
      print('❌ Error creating order: $e');
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
      print('Error sending status update notification: $e');
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
      await _sendDriverAssignmentNotification(orderId, driverId);
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return assignDriver(orderId, driverId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> _sendDriverAssignmentNotification(String orderId, String driverId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final order = OrderModel.fromFirestore(orderDoc);
        final notificationService = ref.read(notificationServiceProvider);
        
        await notificationService.sendNotificationToUser(
          userId: driverId,
          title: 'New Delivery Assignment 📦',
          message: 'You have been assigned to deliver order #${_getOrderShortId(order.id)}',
          type: 'driver_assignment',
          data: {
            'orderId': order.id,
            'orderNumber': _getOrderShortId(order.id).toUpperCase(),
            'customerName': order.customerName,
            'deliveryAddress': order.deliveryAddress,
            'screen': 'driver_orders',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'userType': 'driver',
          },
        );
      }
    } catch (e) {
      print('Error sending driver assignment notification: $e');
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

  // Analytics and reporting
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
      
      // Filter by date range if provided
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
          .get();

      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      final filteredOrders = orders.where((order) => order.status == status).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return filteredOrders;
    } catch (e) {
      if (_shouldRetry(e, retryCount)) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return getOrdersByStatus(restaurantId, status, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> updateOrderStatusWithReason(String orderId, OrderStatus newStatus, String reason, {String? cancelledBy}) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.toString().split('.').last,
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
  final String title;
  final String message;
  final String type;

  _NotificationConfig(this.title, this.message, this.type);
}