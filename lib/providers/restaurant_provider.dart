// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique restaurant ID
  String generateRestaurantId() {
    return _firestore.collection('restaurants').doc().id;
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = 'restaurants/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> createRestaurant(RestaurantModel restaurant, {required String name, required String description, required String phoneNumber}) async {
    try {
      state = const AsyncValue.loading();
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      String restaurantId;
      
      if (restaurant.id.isEmpty) {
        restaurantId = generateRestaurantId();
      } else {
        restaurantId = restaurant.id;
      }
      
      // Create restaurant with the correct ID
      final restaurantWithId = restaurant.copyWith(
        id: restaurantId,
        ownerId: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Create restaurant document
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .set(restaurantWithId.toFirestore());
      
      // Update user document with restaurantId
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
            'restaurantId': restaurantId,
            'hasRestaurant': true,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
      state = const AsyncValue.data(null);
      return restaurantId;
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
              (restaurant.categories.any((category) =>
                  category.toLowerCase().contains(query.toLowerCase()))))
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

  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      state = const AsyncValue.loading();
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Get references to Firestore collections
      final restaurantDoc = _firestore.collection('restaurants').doc(restaurantId);
      final menuItemsRef = _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems');
      
      // First, delete all menu items associated with this restaurant
      final menuItemsSnapshot = await menuItemsRef.get();
      final batch = _firestore.batch();
      
      for (final doc in menuItemsSnapshot.docs) {
        batch.delete(doc.reference);
        
        // Optional: Delete associated images from storage if needed
        try {
          final imageUrl = doc.data()['imageUrl'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          }
        } catch (e) {
          // Continue even if image deletion fails
          print('Error deleting menu item image: $e');
        }
      }
      
      // Commit the batch deletion of menu items
      await batch.commit();
      
      // Delete the restaurant document
      await restaurantDoc.delete();
      
      // Remove restaurantId from user document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
            'restaurantId': FieldValue.delete(),
            'hasRestaurant': false,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
      // Optional: Delete restaurant image from storage if exists
      try {
        final restaurantSnapshot = await restaurantDoc.get();
        if (restaurantSnapshot.exists) {
          final imageUrl = restaurantSnapshot.data()?['imageUrl'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          }
        }
      } catch (e) {
        // Continue even if image deletion fails
        print('Error deleting restaurant image: $e');
      }
      
      // Optional: Delete any other related data (reviews, orders, etc.)
      try {
        // Delete reviews
        final reviewsRef = _firestore
            .collection('reviews')
            .where('restaurantId', isEqualTo: restaurantId);
        
        final reviewsSnapshot = await reviewsRef.get();
        final reviewsBatch = _firestore.batch();
        
        for (final doc in reviewsSnapshot.docs) {
          reviewsBatch.delete(doc.reference);
        }
        
        await reviewsBatch.commit();
      } catch (e) {
        print('Error deleting reviews: $e');
      }
      
      state = const AsyncValue.data(null);
      print('Restaurant $restaurantId and associated data deleted successfully');
      
    } on FirebaseException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      print('Firebase error deleting restaurant: ${e.message}');
      throw Exception('Failed to delete restaurant: ${e.message}');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      print('Unexpected error deleting restaurant: $e');
      throw Exception('Failed to delete restaurant: $e');
    }
  }

  // Get restaurant by owner ID
  Future<RestaurantModel?> getRestaurantByOwner(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      
      return RestaurantModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      rethrow;
    }
  }
}