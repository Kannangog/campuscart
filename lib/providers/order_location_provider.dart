import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/order_location_model.dart'; // Import your OrderLocationModel

// Provider for all active orders (not delivered or cancelled)
final activeOrdersProvider = StreamProvider<List<OrderLocationModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('status', whereIn: [
        'pending',
        'confirmed',
        'preparing',
        'ready',
        'outForDelivery'
      ])
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderLocationModel.fromFirestore(doc))
          .where((order) => order.deliveryLatitude != 0.0 && order.deliveryLongitude != 0.0)
          .toList())
      .handleError((error, stackTrace) {
        throw AsyncError(error, stackTrace);
      });
});

// Provider for specific order location
final orderLocationProvider = StreamProvider.family<OrderLocationModel?, String>((ref, orderId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        final order = OrderLocationModel.fromFirestore(snapshot);
        return (order.deliveryLatitude != 0.0 && order.deliveryLongitude != 0.0) ? order : null;
      })
      .handleError((error, stackTrace) {
        throw AsyncError(error, stackTrace);
      });
});

// Provider for user's orders
final userOrdersProvider = StreamProvider.family<List<OrderLocationModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderLocationModel.fromFirestore(doc))
          .toList())
      .handleError((error, stackTrace) {
        throw AsyncError(error, stackTrace);
      });
});

// Provider for restaurant's orders
final restaurantOrdersProvider = StreamProvider.family<List<OrderLocationModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderLocationModel.fromFirestore(doc))
          .toList())
      .handleError((error, stackTrace) {
        throw AsyncError(error, stackTrace);
      });
});

// Provider for driver's assigned orders
final driverOrdersProvider = StreamProvider.family<List<OrderLocationModel>, String>((ref, driverId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('driverId', isEqualTo: driverId)
      .where('status', whereIn: ['outForDelivery', 'ready'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderLocationModel.fromFirestore(doc))
          .toList())
      .handleError((error, stackTrace) {
        throw AsyncError(error, stackTrace);
      });
});

// Provider for nearby orders based on driver location
final nearbyOrdersProvider = StreamProvider.family<List<OrderLocationModel>, Map<String, double>>((ref, locationData) {
  final double latitude = locationData['latitude']!;
  final double longitude = locationData['longitude']!;
  final double radius = locationData['radius'] ?? 5.0; // Default 5km radius

  return FirebaseFirestore.instance
      .collection('orders')
      .where('status', whereIn: ['ready', 'preparing']) // Orders ready for pickup
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => OrderLocationModel.fromFirestore(doc))
            .where((order) => order.deliveryLatitude != 0.0 && order.deliveryLongitude != 0.0)
            .where((order) => isWithinRadius(
                  order.deliveryLatitude,
                  order.deliveryLongitude,
                  latitude,
                  longitude,
                  radius,
                ))
            .toList();
      })
      .handleError((error, stackTrace) {
        throw AsyncError(error, stackTrace);
      });
});

// Provider for order location management
final orderLocationManagementProvider = StateNotifierProvider<OrderLocationManagementNotifier, AsyncValue<void>>((ref) {
  return OrderLocationManagementNotifier();
});

class OrderLocationManagementNotifier extends StateNotifier<AsyncValue<void>> {
  OrderLocationManagementNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new order
  Future<String> createOrder(OrderLocationModel order) async {
    try {
      state = const AsyncValue.loading();
      
      final docRef = await _firestore.collection('orders').add(order.toFirestore());
      
      state = const AsyncValue.data(null);
      return docRef.id;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
            'status': status.toString().split('.').last,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Assign driver to order
  Future<void> assignDriverToOrder(String orderId, String driverId) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
            'driverId': driverId,
            'status': 'outForDelivery',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Update driver's current location for an order
  Future<void> updateDriverLocation(String orderId, LatLng location) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
            'driverLocation': GeoPoint(location.latitude, location.longitude),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Update estimated delivery time
  Future<void> updateEstimatedDeliveryTime(String orderId, DateTime estimatedTime) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
            'estimatedDeliveryTime': Timestamp.fromDate(estimatedTime),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Get orders within radius for a driver
  Future<List<OrderLocationModel>> getOrdersWithinRadius(
    double driverLatitude,
    double driverLongitude,
    double radiusKm,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['ready', 'preparing'])
          .get();

      return snapshot.docs
          .map((doc) => OrderLocationModel.fromFirestore(doc))
          .where((order) => order.deliveryLatitude != 0.0 && order.deliveryLongitude != 0.0)
          .where((order) {
            final distance = calculateDistance(
              driverLatitude,
              driverLongitude,
              order.deliveryLatitude,
              order.deliveryLongitude,
            );
            return distance <= radiusKm;
          })
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Haversine formula for distance calculation
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

// Helper function to check if order is within radius
bool isWithinRadius(
  double orderLat,
  double orderLon,
  double userLat,
  double userLon,
  double radiusKm,
) {
  const double earthRadius = 6371; // Earth's radius in kilometers
  
  double dLat = _degreesToRadians(orderLat - userLat);
  double dLon = _degreesToRadians(orderLon - userLon);
  
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(userLat)) *
          cos(_degreesToRadians(orderLat)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  double distance = earthRadius * c;
  
  return distance <= radiusKm;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}