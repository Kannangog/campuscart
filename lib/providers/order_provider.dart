import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

final userOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList());
});

final restaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList());
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList());
});

final orderProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
});

final orderManagementProvider = StateNotifierProvider<OrderManagementNotifier, AsyncValue<void>>((ref) {
  return OrderManagementNotifier();
});

class OrderManagementNotifier extends StateNotifier<AsyncValue<void>> {
  OrderManagementNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createOrder(OrderModel order) async {
    try {
      state = const AsyncValue.loading();
      
      final docRef = await _firestore
          .collection('orders')
          .add(order.toFirestore());
      
      state = const AsyncValue.data(null);
      return docRef.id;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      state = const AsyncValue.loading();
      
      final updates = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Set estimated delivery time for certain statuses
      if (status == OrderStatus.confirmed) {
        updates['estimatedDeliveryTime'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 30)),
        );
      }

      await _firestore
          .collection('orders')
          .doc(orderId)
          .update(updates);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderAnalytics(String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
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

      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

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

        // Count items
        for (final item in order.items) {
          itemCounts[item.name] = (itemCounts[item.name] ?? 0) + item.quantity;
        }
      }

      // Get top selling items
      final topItems = itemCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / completedOrders : 0,
        'topSellingItems': topItems.take(5).map((e) => {
          'name': e.key,
          'count': e.value,
        }).toList(),
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPlatformAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

      double totalRevenue = 0;
      int totalOrders = orders.length;
      int completedOrders = 0;
      Map<String, double> restaurantRevenue = {};
      Map<String, int> restaurantOrders = {};

      for (final order in orders) {
        if (order.status == OrderStatus.delivered) {
          totalRevenue += order.total;
          completedOrders++;
          
          restaurantRevenue[order.restaurantName] = 
              (restaurantRevenue[order.restaurantName] ?? 0) + order.total;
        }
        
        restaurantOrders[order.restaurantName] = 
            (restaurantOrders[order.restaurantName] ?? 0) + 1;
      }

      // Get top restaurants by revenue
      final topRestaurants = restaurantRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'averageOrderValue': completedOrders > 0 ? totalRevenue / completedOrders : 0,
        'topRestaurants': topRestaurants.take(5).map((e) => {
          'name': e.key,
          'revenue': e.value,
          'orders': restaurantOrders[e.key] ?? 0,
        }).toList(),
      };
    } catch (e) {
      rethrow;
    }
  }
}