import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';

final restaurantsProvider = StreamProvider<List<RestaurantModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .where('isApproved', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList());
});

final restaurantProvider = StreamProvider.family<RestaurantModel?, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .doc(restaurantId)
      .snapshots()
      .map((doc) => doc.exists ? RestaurantModel.fromFirestore(doc) : null);
});

final pendingRestaurantsProvider = StreamProvider<List<RestaurantModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .where('isApproved', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList());
});

final restaurantsByOwnerProvider = StreamProvider.family<List<RestaurantModel>, String>((ref, ownerId) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList());
});

final restaurantManagementProvider = StateNotifierProvider<RestaurantManagementNotifier, AsyncValue<void>>((ref) {
  return RestaurantManagementNotifier();
});

class RestaurantManagementNotifier extends StateNotifier<AsyncValue<void>> {
  RestaurantManagementNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRestaurant(RestaurantModel restaurant) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('restaurants')
          .doc(restaurant.id)
          .set(restaurant.toFirestore());
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> updates) async {
    try {
      state = const AsyncValue.loading();
      
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .update(updates);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> approveRestaurant(String restaurantId) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'isApproved': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> rejectRestaurant(String restaurantId) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'isApproved': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> toggleRestaurantStatus(String restaurantId, bool isOpen) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'isOpen': isOpen,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<RestaurantModel>> searchRestaurants(String query) async {
    try {
      final snapshot = await _firestore
          .collection('restaurants')
          .where('isApproved', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .where((restaurant) =>
              restaurant.name.toLowerCase().contains(query.toLowerCase()) ||
              restaurant.categories.any((category) =>
                  category.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RestaurantModel>> getRestaurantsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('restaurants')
          .where('isApproved', isEqualTo: true)
          .where('categories', arrayContains: category)
          .get();

      return snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}