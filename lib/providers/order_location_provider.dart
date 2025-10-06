import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_location_model.dart';

// Provider for all active orders (not delivered or cancelled)
final activeOrdersProvider = StreamProvider<List<OrderLocationModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('status', whereIn: [
        'pending',
        'confirmed',
        'preparing',
        'ready',
        'readyForDelivery',
        'outForDelivery'
      ])
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderLocationModel.fromFirestore(doc))
          .where((order) => order.hasLocation)
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
        return order.hasLocation ? order : null;
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

// Provider for restaurant's orders - FIXED: Removed location filter
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
      .where('status', whereIn: ['outForDelivery', 'readyForDelivery'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderLocationModel.fromFirestore(doc))
          .where((order) => order.hasLocation)
          .toList())
      .handleError((error, stackTrace) {
        throw AsyncError(error, stackTrace);
      });
});

// Provider for nearby orders based on driver location
final nearbyOrdersProvider = StreamProvider.family<List<OrderLocationModel>, Map<String, double>>((ref, locationData) {
  final double latitude = locationData['latitude']!;
  final double longitude = locationData['longitude']!;
  final double radius = locationData['radius'] ?? 5.0;

  return FirebaseFirestore.instance
      .collection('orders')
      .where('status', whereIn: ['readyForDelivery', 'preparing'])
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => OrderLocationModel.fromFirestore(doc))
            .where((order) => order.hasLocation)
            .where((order) => isWithinRadius(
                  order.deliveryLatitude!,
                  order.deliveryLongitude!,
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

  // Get orders within radius for a driver
  Future<List<OrderLocationModel>> getOrdersWithinRadius(
    double driverLatitude,
    double driverLongitude,
    double radiusKm,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['readyForDelivery', 'preparing'])
          .get();

      return snapshot.docs
          .map((doc) => OrderLocationModel.fromFirestore(doc))
          .where((order) => order.hasLocation)
          .where((order) {
            final distance = calculateDistance(
              driverLatitude,
              driverLongitude,
              order.deliveryLatitude!,
              order.deliveryLongitude!,
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
    const double earthRadius = 6371;
    
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
  const double earthRadius = 6371;
  
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