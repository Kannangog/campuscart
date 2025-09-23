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

// Add this provider to check if user has a restaurant
final userHasRestaurantProvider = StreamProvider<bool>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(false);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) => snapshot.data()?['hasRestaurant'] as bool? ?? false);
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
      // Create a unique filename with proper extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'restaurants/$timestamp.$extension';
      
      final ref = _storage.ref().child(fileName);
      
      // Set metadata for the upload
      final metadata = SettableMetadata(
        contentType: 'image/${extension == 'png' ? 'png' : 'jpeg'}',
        cacheControl: 'public, max-age=31536000',
      );
      
      // Upload the file with metadata
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask.whenComplete(() {});
      
      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('Image uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } on FirebaseException catch (e) {
      print('Firebase error uploading image: ${e.code} - ${e.message}');
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      print('Unexpected error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> createRestaurant(String uid, {
    required String name,
    required String description,
    required String phoneNumber,
    required List<String> categories,
    required String address,
    required double latitude,
    required double longitude,
    required String email,
    File? imageFile,
    Map<String, String>? openingHours,
    required String openingTime,
    required String closingTime,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Validate that the current user matches the provided uid
      if (user.uid != uid) {
        throw Exception('User ID mismatch');
      }
      
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        print('Starting image upload...');
        imageUrl = await uploadImage(imageFile);
        print('Image upload completed: $imageUrl');
      }
      
      final restaurantId = generateRestaurantId();
      
      // Create restaurant model
      final restaurant = RestaurantModel(
        id: restaurantId,
        ownerId: user.uid,
        name: name,
        description: description,
        phoneNumber: phoneNumber,
        imageUrl: imageUrl ?? '',
        categories: categories,
        address: address,
        latitude: latitude,
        longitude: longitude,
        email: email,
        isOpen: true,
        isApproved: false,
        openingHours: openingHours ?? {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rating: 0.0,
        totalReviews: 0,
      );
      
      print('Creating restaurant document: $restaurantId');
      
      // Create restaurant document
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .set(restaurant.toFirestore());
      
      print('Restaurant document created successfully');
      
      // Update user document with restaurantId - use set with merge to ensure fields exist
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
            'restaurantId': restaurantId,
            'hasRestaurant': true,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          }, SetOptions(merge: true));
      
      print('User document updated successfully');
      
      state = const AsyncValue.data(null);
      return restaurantId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      print('Error creating restaurant: $e');
      rethrow;
    }
  }

  Future<void> updateRestaurant(
    String restaurantId, 
    Map<String, dynamic> updates,
    {File? imageFile}
  ) async {
    try {
      state = const AsyncValue.loading();
      
      // Upload new image if provided
      if (imageFile != null) {
        final imageUrl = await uploadImage(imageFile);
        updates['imageUrl'] = imageUrl;
      }
      
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .update(updates);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      print('Error updating restaurant: $e');
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
      
      // Get restaurant data BEFORE deleting anything
      final restaurantDoc = _firestore.collection('restaurants').doc(restaurantId);
      final restaurantSnapshot = await restaurantDoc.get();
      
      if (!restaurantSnapshot.exists) {
        throw Exception('Restaurant not found');
      }
      
      // Get the owner ID from the restaurant document (important!)
      final restaurantData = restaurantSnapshot.data();
      final ownerId = restaurantData != null ? restaurantData['ownerId'] as String? : null;
      
      // Verify the current user owns this restaurant
      if (ownerId != user.uid) {
        throw Exception('You do not have permission to delete this restaurant');
      }
      
      // Get image URL before deletion for cleanup
      final imageUrl = restaurantData != null ? restaurantData['imageUrl'] as String? : null;
      
      // Get all menu items for this restaurant
      final menuItemsRef = _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems');
      
      final menuItemsSnapshot = await menuItemsRef.get();
      
      // Start batch operations for Firestore deletions
      final batch = _firestore.batch();
      
      // Delete all menu items
      for (final doc in menuItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the restaurant document
      batch.delete(restaurantDoc);
      
      // Commit the batch deletion
      await batch.commit();
      
      // Force update user document to remove restaurant reference
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
            'restaurantId': FieldValue.delete(),
            'hasRestaurant': false,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
      print('User ${user.uid} document updated after restaurant deletion');
      
      // Clean up storage images (optional - can be removed if not needed)
      await _cleanupStorageImages(imageUrl, menuItemsSnapshot);
      
      // Clean up related data (reviews, orders, etc.)
      await _cleanupRelatedData(restaurantId);
      
      // Force refresh the state to ensure UI updates
      state = const AsyncValue.data(null);
      
      print('Restaurant $restaurantId and associated data deleted successfully');
      
    } on FirebaseException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      print('Firebase error deleting restaurant: ${e.code} - ${e.message}');
      throw Exception('Failed to delete restaurant: ${e.message}');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      print('Unexpected error deleting restaurant: $e');
      throw Exception('Failed to delete restaurant: $e');
    }
  }

  // Helper method to cleanup storage images
  Future<void> _cleanupStorageImages(String? restaurantImageUrl, QuerySnapshot menuItemsSnapshot) async {
    try {
      // Delete restaurant image if exists
      if (restaurantImageUrl != null && restaurantImageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(restaurantImageUrl);
        await ref.delete().catchError((e) {
          print('Error deleting restaurant image: $e');
          // Continue even if image deletion fails
        });
      }
      
      // Delete menu item images
      for (final doc in menuItemsSnapshot.docs) {
        final docData = doc.data() as Map<String, dynamic>?;
        final imageUrl = docData != null ? docData['imageUrl'] as String? : null;
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Error deleting menu item image: $e');
            // Continue even if image deletion fails
          }
        }
      }
    } catch (e) {
      print('Error in storage cleanup: $e');
      // Don't throw error - image cleanup is optional
    }
  }

  // Helper method to cleanup related data
  Future<void> _cleanupRelatedData(String restaurantId) async {
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
      
      if (reviewsSnapshot.docs.isNotEmpty) {
        await reviewsBatch.commit();
        print('Deleted ${reviewsSnapshot.docs.length} reviews');
      }
      
      // Cleanup orders - update orders to mark as cancelled instead of deleting
      final ordersRef = _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', whereIn: ['pending', 'confirmed', 'preparing']);
      
      final ordersSnapshot = await ordersRef.get();
      final ordersBatch = _firestore.batch();
      
      for (final doc in ordersSnapshot.docs) {
        ordersBatch.update(doc.reference, {
          'status': 'cancelled',
          'cancellationReason': 'Restaurant deleted',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      if (ordersSnapshot.docs.isNotEmpty) {
        await ordersBatch.commit();
        print('Updated ${ordersSnapshot.docs.length} orders to cancelled status');
      }
      
    } catch (e) {
      print('Error cleaning up related data: $e');
      // Don't throw error - related data cleanup is optional
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

  // Check if user has a restaurant
  Future<bool> checkUserHasRestaurant(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final hasRestaurant = userDoc.data()?['hasRestaurant'] as bool? ?? false;
      final restaurantId = userDoc.data()?['restaurantId'] as String?;
      
      // Double-check by verifying the restaurant exists
      if (hasRestaurant && restaurantId != null) {
        final restaurantDoc = await _firestore.collection('restaurants').doc(restaurantId).get();
        if (!restaurantDoc.exists) {
          // Restaurant doesn't exist but user document says it does - fix it
          await _firestore.collection('users').doc(userId).update({
            'hasRestaurant': false,
            'restaurantId': FieldValue.delete(),
          });
          return false;
        }
        return true;
      }
      
      return hasRestaurant;
    } catch (e) {
      print('Error checking user restaurant: $e');
      return false;
    }
  }

  // Force refresh user restaurant status
  Future<void> refreshUserRestaurantStatus(String userId) async {
    try {
      final hasRestaurant = await checkUserHasRestaurant(userId);
      
      // Force update the user document to ensure consistency
      await _firestore.collection('users').doc(userId).update({
        'hasRestaurant': hasRestaurant,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      print('Refreshed restaurant status for user $userId: $hasRestaurant');
    } catch (e) {
      print('Error refreshing user restaurant status: $e');
    }
  }
}