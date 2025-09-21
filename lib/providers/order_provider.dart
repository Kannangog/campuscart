// ignore_for_file: prefer_typing_uninitialized_variables, avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

// Error handling utility
class FirestoreErrorHandler {
  static bool isIndexError(FirebaseException e) {
    return e.code == 'failed-precondition' && 
           e.message?.contains('index') == true;
  }
  
  static String getIndexErrorMessage(FirebaseException e) {
    final message = e.message ?? '';
    final regex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    final match = regex.firstMatch(message);
    
    if (match != null) {
      return 'We\'re setting up your orders view. Please try again in a few moments.';
    }
    
    return 'Database configuration in progress. Please wait a moment.';
  }
}

// Constants for order timeout
const _orderAcceptanceTimeout = Duration(hours: 3);
const _autoCancelCheckInterval = Duration(minutes: 5);

// Base stream provider with error handling and index fallback
Stream<List<OrderModel>> _createOrderStreamWithFallback(
  Query query, {
  required void Function() onIndexBuilding,
  required void Function() onIndexBuilt,
  required Ref ref,
}) {
  final streamController = StreamController<List<OrderModel>>();
  bool hasShownIndexError = false;
  bool isIndexBuilding = false;
  Timer? retryTimer;

  final subscription = query
      .snapshots()
      .handleError((error, stackTrace) {
        if (error is FirebaseException && FirestoreErrorHandler.isIndexError(error)) {
          if (!hasShownIndexError) {
            hasShownIndexError = true;
            isIndexBuilding = true;
            onIndexBuilding();
            
            // Use fallback query when index is being built
            query
                .get()
                .then((snapshot) {
                  final orders = snapshot.docs
                      .map((doc) => OrderModel.fromFirestore(doc))
                      .toList();
                  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  streamController.add(orders);
                  
                  // Set up automatic retry with the original query
                  retryTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
                    query.snapshots().first.then((snapshot) {
                      // If we get a successful response, cancel the timer
                      timer.cancel();
                      isIndexBuilding = false;
                      hasShownIndexError = false;
                      onIndexBuilt();
                      
                      final orders = snapshot.docs
                          .map((doc) => OrderModel.fromFirestore(doc))
                          .toList();
                      streamController.add(orders);
                    }).catchError((_) {
                      // Continue retrying if still failing
                    });
                  });
                }).catchError((fallbackError) {
                  streamController.addError(fallbackError, stackTrace);
                });
          }
        } else {
          // Re-throw other errors
          streamController.addError(error, stackTrace);
        }
      })
      .listen((snapshot) {
        // Reset index building flag when we get a successful response
        if (isIndexBuilding) {
          isIndexBuilding = false;
          hasShownIndexError = false;
          retryTimer?.cancel();
          onIndexBuilt();
        }
        
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        streamController.add(orders);
      });

  ref.onDispose(() {
    subscription.cancel();
    retryTimer?.cancel();
    streamController.close();
  });

  return streamController.stream;
}

// Simple user orders provider without complex queries
final userOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: userId);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for user orders'),
    onIndexBuilt: () => print('Index built for user orders'),
    ref: ref,
  );
});

// Simple restaurant orders provider
final restaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for restaurant orders'),
    onIndexBuilt: () => print('Index built for restaurant orders'),
    ref: ref,
  );
});

// All orders provider
final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final query = FirebaseFirestore.instance
      .collection('orders');

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for all orders'),
    onIndexBuilt: () => print('Index built for all orders'),
    ref: ref,
  );
});

// Single order provider with error handling
final orderProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final streamController = StreamController<OrderModel?>();
  
  final subscription = FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .handleError((error, stackTrace) {
        streamController.addError(error, stackTrace);
      })
      .listen((doc) {
        if (doc.exists) {
          streamController.add(OrderModel.fromFirestore(doc));
        } else {
          streamController.add(null);
        }
      });

  ref.onDispose(() {
    subscription.cancel();
    streamController.close();
  });

  return streamController.stream;
});

// Simplified active restaurant orders provider
final activeRestaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for active restaurant orders'),
    onIndexBuilt: () => print('Index built for active restaurant orders'),
    ref: ref,
  );
});

// Order status specific providers - simplified
final newOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for new orders'),
    onIndexBuilt: () => print('Index built for new orders'),
    ref: ref,
  );
});

// Order management provider
final orderManagementProvider = Provider<OrderManagementService>((ref) {
  return OrderManagementService(ref);
});

class OrderManagementService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _maxRetries = 3;
  Timer? _autoCancelTimer;

  OrderManagementService(this.ref) {
    _startAutoCancelTimer();
  }

  void _startAutoCancelTimer() {
    // Check for orders to cancel every 5 minutes
    _autoCancelTimer = Timer.periodic(_autoCancelCheckInterval, (_) {
      _checkAndCancelExpiredOrders();
    });
  }

  Future<void> _checkAndCancelExpiredOrders() async {
    try {
      final threeHoursAgo = DateTime.now().subtract(_orderAcceptanceTimeout);

      // Get all orders and filter manually to avoid complex queries
      final allOrdersQuery = _firestore.collection('orders');
      final allOrdersSnapshot = await allOrdersQuery.get();
      
      for (final doc in allOrdersSnapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        final orderCreatedAt = order.createdAt;
        
        // Check if order is older than 3 hours and still pending
        if (orderCreatedAt.isBefore(threeHoursAgo) && 
            order.status == OrderStatus.pending) {
          await _autoCancelOrder(order, 'Order was not accepted within 3 hours');
        }
        
        // Check if order is in process but not delivered for more than 3 hours
        final isProcessing = order.status == OrderStatus.confirmed || 
                            order.status == OrderStatus.preparing || 
                            order.status == OrderStatus.ready || 
                            order.status == OrderStatus.outForDelivery;
        
        if (orderCreatedAt.isBefore(threeHoursAgo) && isProcessing) {
          await _autoCancelOrder(order, 'Order was not delivered within 3 hours');
        }
      }
    } catch (e) {
      print('Error in auto-cancellation check: $e');
    }
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
        
        // Send notification to user about auto-cancellation
        await _sendAutoCancellationNotification(order, reason);
      }
    } catch (e) {
      print('Error auto-cancelling order ${order.id}: $e');
    }
  }

  Future<void> _sendAutoCancellationNotification(OrderModel order, String reason) async {
    try {
      // Add a notification to the user's notifications collection
      await _firestore.collection('notifications').add({
        'userId': order.userId,
        'title': 'Order Auto-Cancelled',
        'message': 'Your order #${order.id} was automatically cancelled: $reason',
        'type': 'order_cancelled',
        'orderId': order.id,
        'read': false,
        'createdAt': Timestamp.now(),
      });
      
      print('Sent auto-cancellation notification for order ${order.id}');
    } catch (e) {
      print('Error sending auto-cancellation notification: $e');
    }
  }

  void dispose() {
    _autoCancelTimer?.cancel();
  }

  Future<String> createOrder(OrderModel order) async {
    final docRef = await _firestore
        .collection('orders')
        .add(order.toFirestore());
    
    return docRef.id;
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

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update(updates);
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
        // Wait and retry for index errors
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return updateOrderStatus(orderId, status, retryCount: retryCount + 1);
      }
      rethrow;
    }
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
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
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
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
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
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return markAsDelivered(orderId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  // Analytics methods with error handling
  Future<Map<String, dynamic>> getOrderAnalytics(String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    int retryCount = 0,
  }) async {
    try {
      Query query = _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId);

      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      // Filter by date manually if needed
      List<OrderModel> filteredOrders = orders;
      if (startDate != null) {
        filteredOrders = filteredOrders.where((order) => 
          order.createdAt.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        filteredOrders = filteredOrders.where((order) => 
          order.createdAt.isBefore(endDate)).toList();
      }

      return _calculateOrderAnalytics(filteredOrders);
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
        // Wait and retry
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
    Map<String, int> itemCounts = {};

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

  // Get orders by status for a restaurant
  Future<List<OrderModel>> getOrdersByStatus(String restaurantId, OrderStatus status, {int retryCount = 0}) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      
      // Filter by status manually
      final filteredOrders = orders.where((order) => order.status == status).toList();
      filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return filteredOrders;
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
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

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update(updates);
    } catch (e) {
      rethrow;
    }
  }
}