import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/menu_item_model.dart';

// Provider that fetches ALL menu items (used in home screen search)
final menuProvider = StreamProvider<List<MenuItemModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .handleError((error) {
        if (error is FirebaseException && 
            (error.code == 'failed-precondition' || error.code == 'unavailable')) {
          return Stream.value([]);
        }
        throw error;
      })
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final menuItemsProvider = StreamProvider.autoDispose.family<List<MenuItemModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .handleError((error) {
        if (error is FirebaseException && 
            (error.code == 'failed-precondition' || error.code == 'unavailable')) {
          return Stream.value([]);
        }
        throw error;
      })
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final allMenuItemsProvider = StreamProvider.autoDispose.family<List<MenuItemModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .snapshots()
      .handleError((error) {
        if (error is FirebaseException && 
            (error.code == 'failed-precondition' || error.code == 'unavailable')) {
          return Stream.value([]);
        }
        throw error;
      })
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final todaysSpecialItemsProvider = StreamProvider.autoDispose.family<List<MenuItemModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('isTodaysSpecial', isEqualTo: true)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .handleError((error) {
        if (error is FirebaseException && 
            (error.code == 'failed-precondition' || error.code == 'unavailable')) {
          return Stream.value([]);
        }
        throw error;
      })
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final menuItemProvider = StreamProvider.autoDispose.family<MenuItemModel?, String>((ref, menuItemId) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .doc(menuItemId)
      .snapshots()
      .handleError((error) {
        if (error is FirebaseException && error.code == 'unavailable') {
          return Stream.value(null);
        }
        throw error;
      })
      .map((doc) => doc.exists ? MenuItemModel.fromFirestore(doc) : null);
});

final topSellingItemsProvider = StreamProvider.autoDispose<List<MenuItemModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('isAvailable', isEqualTo: true)
      .orderBy('orderCount', descending: true)
      .limit(10)
      .snapshots()
      .handleError((error) {
        if (error is FirebaseException && 
            (error.code == 'failed-precondition' || error.code == 'unavailable')) {
          return Stream.value([]);
        }
        throw error;
      })
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final menuItemsByCategoryProvider = StreamProvider.autoDispose.family<List<MenuItemModel>, Map<String, String>>((ref, params) {
  final restaurantId = params['restaurantId']!;
  final category = params['category']!;
  
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('category', isEqualTo: category)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .handleError((error) {
        if (error is FirebaseException && 
            (error.code == 'failed-precondition' || error.code == 'unavailable')) {
          return Stream.value([]);
        }
        throw error;
      })
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

// Fixed menu management provider with proper image handling
final menuManagementProvider = StateNotifierProvider.autoDispose<MenuManagementNotifier, AsyncValue<void>>((ref) {
  return MenuManagementNotifier(ref);
});

class MenuManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  MenuManagementNotifier(this.ref) : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _checkIfDisposed() {
    if (_isDisposed) {
      throw StateError('MenuManagementNotifier has been disposed');
    }
  }

Future<String> _uploadImage(File imageFile) async {
  try {
    _checkIfDisposed();
    
    // Create unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${timestamp}_${imageFile.path.split('/').last}';
    
    // FIXED: Use restaurants path to match your rules
    final storageRef = _storage.ref().child('restaurants/menu_images/$fileName');
    
    final uploadTask = storageRef.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    final snapshot = await uploadTask;
    
    if (snapshot.state == TaskState.success) {
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } else {
      throw Exception('Failed to upload image: ${snapshot.state}');
    }
  } on FirebaseException catch (e) {
    throw Exception('Firebase storage error: ${e.code} - ${e.message}');
  } catch (e) {
    throw Exception('Image upload failed: $e');
  }
}

Future<void> addMenuItem(MenuItemModel menuItem, {File? imageFile}) async {
  try {
    _checkIfDisposed();
    state = const AsyncValue.loading();
    
    String imageUrl = menuItem.imageUrl;
    
    // Upload image if provided
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile);
    }
    
    // Use default image if no image is provided
    if (imageUrl.isEmpty) {
      imageUrl = 'https://via.placeholder.com/300x200?text=Food+Image';
    }
    
    // FIXED: Create menu item with updated image URL - only update necessary fields
    final menuItemWithImage = menuItem.copyWith(
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // Don't set id here - let Firestore generate it
    );
    
    // Let Firestore generate the ID automatically
    final docRef = await _firestore
        .collection('menuItems')
        .add(menuItemWithImage.toFirestore());
    
    // Update the document with the generated ID
    await docRef.update({'id': docRef.id});
    
    if (!_isDisposed) {
      state = const AsyncValue.data(null);
    }
  } on FirebaseException catch (e, stackTrace) {
    if (!_isDisposed) {
      state = AsyncValue.error(e, stackTrace);
    }
    throw Exception('Firestore error: ${e.code} - ${e.message}');
  } catch (e, stackTrace) {
    if (!_isDisposed) {
      state = AsyncValue.error(e, stackTrace);
    }
    rethrow;
  }
}

  Future<void> updateMenuItem(
    String menuItemId, 
    Map<String, dynamic> updates, 
    {File? imageFile}
  ) async {
    try {
      _checkIfDisposed();
      state = const AsyncValue.loading();
      
      final updatedUpdates = Map<String, dynamic>.from(updates);
      
      // Upload new image if provided
      if (imageFile != null) {
        final imageUrl = await _uploadImage(imageFile);
        updatedUpdates['imageUrl'] = imageUrl;
      }
      
      // Always update the updatedAt timestamp
      updatedUpdates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      await _firestore
          .collection('menuItems')
          .doc(menuItemId)
          .update(updatedUpdates);
      
      if (!_isDisposed) {
        state = const AsyncValue.data(null);
      }
    } on FirebaseException catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      throw Exception('Firestore error: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    try {
      _checkIfDisposed();
      state = const AsyncValue.loading();
      
      // Optional: Delete associated image from storage
      final doc = await _firestore.collection('menuItems').doc(menuItemId).get();
      if (doc.exists) {
        final menuItem = MenuItemModel.fromFirestore(doc);
        if (menuItem.imageUrl.isNotEmpty && menuItem.imageUrl.contains('firebasestorage')) {
          try {
            final imageRef = _storage.refFromURL(menuItem.imageUrl);
            await imageRef.delete();
          } catch (e) {
            print('Error deleting image from storage: $e');
            // Continue with menu item deletion even if image deletion fails
          }
        }
      }
      
      await _firestore
          .collection('menuItems')
          .doc(menuItemId)
          .delete();
      
      if (!_isDisposed) {
        state = const AsyncValue.data(null);
      }
    } on FirebaseException catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      throw Exception('Firestore error: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> toggleItemAvailability(String menuItemId, bool isAvailable) async {
    try {
      _checkIfDisposed();
      state = const AsyncValue.loading();
      
      await _firestore.collection('menuItems').doc(menuItemId).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (!_isDisposed) {
        state = const AsyncValue.data(null);
      }
    } on FirebaseException catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      throw Exception('Firestore error: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> toggleTodaysSpecial(String menuItemId, bool isTodaysSpecial) async {
    try {
      _checkIfDisposed();
      state = const AsyncValue.loading();
      
      await _firestore.collection('menuItems').doc(menuItemId).update({
        'isTodaysSpecial': isTodaysSpecial,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (!_isDisposed) {
        state = const AsyncValue.data(null);
      }
    } on FirebaseException catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      throw Exception('Firestore error: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> incrementOrderCount(String menuItemId) async {
    try {
      _checkIfDisposed();
      await _firestore.collection('menuItems').doc(menuItemId).update({
        'orderCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error incrementing order count: $e');
    }
  }

  Future<List<MenuItemModel>> searchMenuItems(String restaurantId, String query) async {
    try {
      _checkIfDisposed();
      final snapshot = await _firestore
          .collection('menuItems')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isAvailable', isEqualTo: true)
          .get();

      final queryLower = query.toLowerCase();
      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .where((item) =>
              item.name.toLowerCase().contains(queryLower) ||
              item.description.toLowerCase().contains(queryLower) ||
              item.category.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getMenuCategories(String restaurantId) async {
    try {
      _checkIfDisposed();
      final snapshot = await _firestore
          .collection('menuItems')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isAvailable', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final item = MenuItemModel.fromFirestore(doc);
        categories.add(item.category);
      }

      return categories.toList()..sort();
    } catch (e) {
      rethrow;
    }
  }
}

// Helper extension for MenuItemModel copyWith method
extension MenuItemModelExtension on MenuItemModel {
  MenuItemModel copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    double? specialOfferPrice,
    String? imageUrl,
    String? category,
    bool? isVegetarian,
    bool? isVegan,
    bool? isSpicy,
    bool? isTodaysSpecial,
    bool? isAvailable,
    int? orderCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      specialOfferPrice: specialOfferPrice ?? this.specialOfferPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isSpicy: isSpicy ?? this.isSpicy,
      isTodaysSpecial: isTodaysSpecial ?? this.isTodaysSpecial,
      isAvailable: isAvailable ?? this.isAvailable,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}