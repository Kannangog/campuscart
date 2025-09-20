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

// Enhanced user orders provider with better error handling
final userOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  final streamController = StreamController<List<OrderModel>>();
  bool hasShownIndexError = false;
  bool isIndexBuilding = false;
  
  final subscription = FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((error, stackTrace) {
        if (error is FirebaseException && FirestoreErrorHandler.isIndexError(error)) {
          if (!hasShownIndexError) {
            hasShownIndexError = true;
            isIndexBuilding = true;
            // Use fallback query when index is being built
            FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: userId)
                .get()
                .then((snapshot) {
                  final orders = snapshot.docs
                      .map((doc) => OrderModel.fromFirestore(doc))
                      .toList();
                  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  streamController.add(orders);
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
        }
        
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        streamController.add(orders);
      });

  ref.onDispose(() {
    subscription.cancel();
    streamController.close();
  });

  return streamController.stream;
});

// Enhanced restaurant orders provider
final restaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final streamController = StreamController<List<OrderModel>>();
  bool hasShownIndexError = false;
  bool isIndexBuilding = false;
  
  final subscription = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((error, stackTrace) {
        if (error is FirebaseException && FirestoreErrorHandler.isIndexError(error)) {
          if (!hasShownIndexError) {
            hasShownIndexError = true;
            isIndexBuilding = true;
            // Use fallback query when index is being built
            FirebaseFirestore.instance
                .collection('orders')
                .where('restaurantId', isEqualTo: restaurantId)
                .get()
                .then((snapshot) {
                  final orders = snapshot.docs
                      .map((doc) => OrderModel.fromFirestore(doc))
                      .toList();
                  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  streamController.add(orders);
                }).catchError((fallbackError) {
                  streamController.addError(fallbackError, stackTrace);
                });
          }
        } else {
          streamController.addError(error, stackTrace);
        }
      })
      .listen((snapshot) {
        if (isIndexBuilding) {
          isIndexBuilding = false;
          hasShownIndexError = false;
        }
        
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        streamController.add(orders);
      });

  ref.onDispose(() {
    subscription.cancel();
    streamController.close();
  });

  return streamController.stream;
});

// All orders provider with error handling
final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final streamController = StreamController<List<OrderModel>>();
  bool hasShownIndexError = false;
  bool isIndexBuilding = false;
  
  final subscription = FirebaseFirestore.instance
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((error, stackTrace) {
        if (error is FirebaseException && FirestoreErrorHandler.isIndexError(error)) {
          if (!hasShownIndexError) {
            hasShownIndexError = true;
            isIndexBuilding = true;
            // Use fallback query when index is being built
            FirebaseFirestore.instance
                .collection('orders')
                .get()
                .then((snapshot) {
                  final orders = snapshot.docs
                      .map((doc) => OrderModel.fromFirestore(doc))
                      .toList();
                  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  streamController.add(orders);
                }).catchError((fallbackError) {
                  streamController.addError(fallbackError, stackTrace);
                });
          }
        } else {
          streamController.addError(error, stackTrace);
        }
      })
      .listen((snapshot) {
        if (isIndexBuilding) {
          isIndexBuilding = false;
          hasShownIndexError = false;
        }
        
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        streamController.add(orders);
      });

  ref.onDispose(() {
    subscription.cancel();
    streamController.close();
  });

  return streamController.stream;
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

// Active orders provider for restaurant (pending, confirmed, preparing, ready)
final activeRestaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  final streamController = StreamController<List<OrderModel>>();
  bool hasShownIndexError = false;
  bool isIndexBuilding = false;
  
  final subscription = FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('status', whereIn: [
        'pending',
        'confirmed', 
        'preparing',
        'ready'
      ])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((error, stackTrace) {
        if (error is FirebaseException && FirestoreErrorHandler.isIndexError(error)) {
          if (!hasShownIndexError) {
            hasShownIndexError = true;
            isIndexBuilding = true;
            // Use fallback query when index is being built
            FirebaseFirestore.instance
                .collection('orders')
                .where('restaurantId', isEqualTo: restaurantId)
                .where('status', whereIn: [
                  'pending',
                  'confirmed', 
                  'preparing',
                  'ready'
                ])
                .get()
                .then((snapshot) {
                  final orders = snapshot.docs
                      .map((doc) => OrderModel.fromFirestore(doc))
                      .toList();
                  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  streamController.add(orders);
                }).catchError((fallbackError) {
                  streamController.addError(fallbackError, stackTrace);
                });
          }
        } else {
          streamController.addError(error, stackTrace);
        }
      })
      .listen((snapshot) {
        if (isIndexBuilding) {
          isIndexBuilding = false;
          hasShownIndexError = false;
        }
        
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        streamController.add(orders);
      });

  ref.onDispose(() {
    subscription.cancel();
    streamController.close();
  });

  return streamController.stream;
});

// Order management provider - Changed from StateNotifierProvider to a simple Provider
final orderManagementProvider = Provider<OrderManagementService>((ref) {
  return OrderManagementService();
});

class OrderManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _maxRetries = 3;

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

  Future<void> cancelOrder(String orderId, String text, {int retryCount = 0}) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return cancelOrder(orderId, text, retryCount: retryCount + 1);
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

  // Similar enhancement for platform analytics
  Future<Map<String, dynamic>> getPlatformAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    int retryCount = 0,
  }) async {
    try {
      Query query = _firestore.collection('orders');

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      return _calculatePlatformAnalytics(orders);
    } catch (e) {
      if (e is FirebaseException && FirestoreErrorHandler.isIndexError(e) && retryCount < _maxRetries) {
        // Fallback without ordering
        try {
          Query query = _firestore.collection('orders');

          if (startDate != null) {
            query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
          }
          if (endDate != null) {
            query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
          }

          final snapshot = await query.get();
          final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return _calculatePlatformAnalytics(orders);
        } catch (fallbackError) {
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return getPlatformAnalytics(
            startDate: startDate, 
            endDate: endDate, 
            retryCount: retryCount + 1
          );
        }
      }
      rethrow;
    }
  }

  Map<String, dynamic> _calculatePlatformAnalytics(List<OrderModel> orders) {
    double totalRevenue = 0;
    int totalOrders = orders.length;
    int completedOrders = 0;
    int cancelledOrders = 0;
    Map<String, double> restaurantRevenue = {};
    Map<String, int> restaurantOrders = {};

    for (final order in orders) {
      if (order.status == OrderStatus.delivered) {
        totalRevenue += order.total;
        completedOrders++;
        
        restaurantRevenue[order.restaurantName] = 
            (restaurantRevenue[order.restaurantName] ?? 0) + order.total;
      } else if (order.status == OrderStatus.cancelled) {
        cancelledOrders++;
      }
      
      restaurantOrders[order.restaurantName] = 
          (restaurantOrders[order.restaurantName] ?? 0) + 1;
    }

    final topRestaurants = restaurantRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'averageOrderValue': completedOrders > 0 ? totalRevenue / completedOrders : 0,
      'completionRate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
      'cancellationRate': totalOrders > 0 ? (cancelledOrders / totalOrders) * 100 : 0,
      'topRestaurants': topRestaurants.take(5).map((e) => {
        'name': e.key,
        'revenue': e.value,
        'orders': restaurantOrders[e.key] ?? 0,
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
}