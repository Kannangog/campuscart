import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// Provider for all order locations
final orderLocationsProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: UserRole.restaurant.index)
      .where('isApproved', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList());
});

// Provider for specific restaurant location
final restaurantLocationProvider = StreamProvider.family<UserModel?, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(restaurantId)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

// Provider for nearby restaurants based on location
final nearbyRestaurantsProvider = StreamProvider.family<List<UserModel>, Map<String, double>>((ref, locationData) {
  final double latitude = locationData['latitude']!;
  final double longitude = locationData['longitude']!;
  final double radius = locationData['radius'] ?? 10.0; // Default 10km radius

  // Note: This requires geospatial indexing in Firestore
  // You'll need to set up geohashes for your restaurant locations
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: UserRole.restaurant.index)
      .where('isApproved', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((restaurant) {
              // Add your distance calculation logic here
              // This is a simplified example - you'd need actual location data
              return restaurantHasLocation(restaurant) && 
                     isWithinRadius(restaurant, latitude, longitude, radius);
            })
            .toList();
      });
});

bool restaurantHasLocation(UserModel restaurant) {
  // Implement your logic to check if restaurant has location data
  return restaurant.location != null;
}

// Provider for restaurant location management
final locationManagementProvider = StateNotifierProvider<LocationManagementNotifier, AsyncValue<void>>((ref) {
  return LocationManagementNotifier();
});

class LocationManagementNotifier extends StateNotifier<AsyncValue<void>> {
  LocationManagementNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateRestaurantLocation(
    String restaurantId, 
    double latitude, 
    double longitude,
    String? address
  ) async {
    try {
      state = const AsyncValue.loading();
      
      final updates = {
        'location': GeoPoint(latitude, longitude),
        'address': address,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      await _firestore
          .collection('users')
          .doc(restaurantId)
          .update(updates);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateRestaurantAddress(
    String restaurantId,
    String address,
    String? city,
    String? state,
    String? zipCode
  ) async {
    try {
      state = const AsyncValue.loading() as String?;
      
      final updates = {
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      await _firestore
          .collection('users')
          .doc(restaurantId)
          .update(updates);
      
      state = const AsyncValue.data(null) as String?;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current) as String?;
      rethrow;
    }
  }

  Future<List<UserModel>> getRestaurantsWithinRadius(
    double userLatitude,
    double userLongitude,
    double radiusKm
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.restaurant.index)
          .where('isApproved', isEqualTo: true)
          .get();

      final restaurants = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((restaurant) =>
            restaurantHasLocation(restaurant) &&
            calculateDistance(
              userLatitude,
              userLongitude,
              getRestaurantLatitude(restaurant),
              getRestaurantLongitude(restaurant)
            ) <= radiusKm
          )
          .toList();

      return restaurants;
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods for location calculations
  double getRestaurantLatitude(UserModel restaurant) {
    return restaurant.location?.latitude ?? 0.0;
  }

  double getRestaurantLongitude(UserModel restaurant) {
    return restaurant.location?.longitude ?? 0.0;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat/2) * sin(dLat/2) +
              cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
              sin(dLon/2) * sin(dLon/2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

// Helper function to check if restaurant is within radius
bool isWithinRadius(UserModel restaurant, double userLat, double userLon, double radiusKm) {
  // This would use actual location data from the restaurant
  // For now, it's a placeholder that returns true
  return true;
}