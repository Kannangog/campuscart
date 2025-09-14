import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

// Fixed menu management provider with proper disposal handling
final menuManagementProvider = StateNotifierProvider.autoDispose<MenuManagementNotifier, AsyncValue<void>>((ref) {
  return MenuManagementNotifier();
});

class MenuManagementNotifier extends StateNotifier<AsyncValue<void>> {
  MenuManagementNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Helper method to check if notifier is disposed before performing operations
  void _checkIfDisposed() {
    if (_isDisposed) {
      throw StateError('MenuManagementNotifier has been disposed');
    }
  }

  Future<void> addMenuItem(MenuItemModel menuItem) async {
    try {
      _checkIfDisposed();
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('menuItems')
          .add(menuItem.toFirestore());
      
      if (!_isDisposed) {
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> updateMenuItem(String menuItemId, Map<String, dynamic> updates) async {
    try {
      _checkIfDisposed();
      state = const AsyncValue.loading();
      
      final updatedUpdates = Map<String, dynamic>.from(updates);
      if (updatedUpdates.containsKey('updatedAt') && updatedUpdates['updatedAt'] is DateTime) {
        updatedUpdates['updatedAt'] = Timestamp.fromDate(updatedUpdates['updatedAt']);
      }
      
      await _firestore
          .collection('menuItems')
          .doc(menuItemId)
          .update(updatedUpdates);
      
      if (!_isDisposed) {
        state = const AsyncValue.data(null);
      }
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
      
      await _firestore
          .collection('menuItems')
          .doc(menuItemId)
          .delete();
      
      if (!_isDisposed) {
        state = const AsyncValue.data(null);
      }
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