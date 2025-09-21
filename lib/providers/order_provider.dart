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

final userOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for user orders'),
    onIndexBuilt: () => print('Index built for user orders'),
    ref: ref,
  );
});

final restaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for restaurant orders'),
    onIndexBuilt: () => print('Index built for restaurant orders'),
    ref: ref,
  );
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .orderBy('createdAt', descending: true);

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

final activeRestaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('status', whereIn: [
        'pending',
        'confirmed', 
        'preparing',
        'ready',
        'outForDelivery'
      ])
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for active restaurant orders'),
    onIndexBuilt: () => print('Index built for active restaurant orders'),
    ref: ref,
  );
});

// Order status specific providers
final newOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for new orders'),
    onIndexBuilt: () => print('Index built for new orders'),
    ref: ref,
  );
});

final preparingOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('status', whereIn: ['confirmed', 'preparing'])
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for preparing orders'),
    onIndexBuilt: () => print('Index built for preparing orders'),
    ref: ref,
  );
});

final readyOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('status', isEqualTo: 'ready')
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for ready orders'),
    onIndexBuilt: () => print('Index built for ready orders'),
    ref: ref,
  );
});

final completedOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('status', whereIn: ['delivered', 'completed'])
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for completed orders'),
    onIndexBuilt: () => print('Index built for completed orders'),
    ref: ref,
  );
});

// Time-based order providers
final todayOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for today orders'),
    onIndexBuilt: () => print('Index built for today orders'),
    ref: ref,
  );
});

final yesterdayOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final now = DateTime.now();
  final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
  final endOfYesterday = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
  
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYesterday))
      .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfYesterday))
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for yesterday orders'),
    onIndexBuilt: () => print('Index built for yesterday orders'),
    ref: ref,
  );
});

final last7DaysOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final now = DateTime.now();
  final sevenDaysAgo = DateTime(now.year, now.month, now.day - 7);
  
  final query = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
      .orderBy('createdAt', descending: true);

  return _createOrderStreamWithFallback(
    query,
    onIndexBuilding: () => print('Index building for last 7 days orders'),
    onIndexBuilt: () => print('Index built for last 7 days orders'),
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
      final timestampThreeHoursAgo = Timestamp.fromDate(threeHoursAgo);

      // Get orders that are still in pending state for more than 3 hours
      final pendingOrdersQuery = _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isLessThanOrEqualTo: timestampThreeHoursAgo);

      final pendingOrdersSnapshot = await pendingOrdersQuery.get();
      
      for (final doc in pendingOrdersSnapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        await _autoCancelOrder(order, 'Order was not accepted within 3 hours');
      }

      // Get orders that are in process but not delivered for more than 3 hours
      final processingOrdersQuery = _firestore
          .collection('orders')
          .where('status', whereIn: ['confirmed', 'preparing', 'ready', 'outForDelivery'])
          .where('createdAt', isLessThanOrEqualTo: timestampThreeHoursAgo);

      final processingOrdersSnapshot = await processingOrdersQuery.get();
      
      for (final doc in processingOrdersSnapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        await _autoCancelOrder(order, 'Order was not delivered within 3 hours');
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
          'cancellationReason': reason,
          'updatedAt': Timestamp.now(),
          'cancelledAt': Timestamp.now(),
        });
        
        print('Automatically cancelled order ${order.id}: $reason');
        
        // You might want to send a notification to the user here
      }
    } catch (e) {
      print('Error auto-cancelling order ${order.id}: $e');
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

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Try with ordering first
      final snapshot = await query.orderBy('createdAt', descending: true).get();
      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      return _calculateOrderAnalytics(orders);
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
        // Fallback: try without ordering
        try {
          Query query = _firestore
              .collection('orders')
              .where('restaurantId', isEqualTo: restaurantId);

          if (startDate != null) {
            query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
          }
          if (endDate != null) {
            query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
          }

          final snapshot = await query.get();
          final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          // Manual sorting
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return _calculateOrderAnalytics(orders);
        } catch (fallbackError) {
          // If fallback also fails, wait and retry
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return getOrderAnalytics(restaurantId, 
            startDate: startDate, 
            endDate: endDate, 
            retryCount: retryCount + 1
          );
        }
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
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
        // Fallback without ordering
        try {
          final snapshot = await _firestore
              .collection('orders')
              .where('restaurantId', isEqualTo: restaurantId)
              .where('status', isEqualTo: status.toString().split('.').last)
              .get();

          final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        } catch (fallbackError) {
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return getOrdersByStatus(restaurantId, status, retryCount: retryCount + 1);
        }
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