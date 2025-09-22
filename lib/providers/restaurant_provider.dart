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
      
      // Update user document with restaurantId
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
            'restaurantId': restaurantId,
            'hasRestaurant': true,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
      
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