import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

final menuItemsProvider = StreamProvider.family<List<MenuItemModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final allMenuItemsProvider = StreamProvider.family<List<MenuItemModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final todaysSpecialItemsProvider = StreamProvider.family<List<MenuItemModel>, String>((ref, restaurantId) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('isTodaysSpecial', isEqualTo: true)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final menuItemProvider = StreamProvider.family<MenuItemModel?, String>((ref, menuItemId) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .doc(menuItemId)
      .snapshots()
      .map((doc) => doc.exists ? MenuItemModel.fromFirestore(doc) : null);
});

final topSellingItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('isAvailable', isEqualTo: true)
      .orderBy('orderCount', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final menuItemsByCategoryProvider = StreamProvider.family<List<MenuItemModel>, Map<String, String>>((ref, params) {
  final restaurantId = params['restaurantId']!;
  final category = params['category']!;
  
  return FirebaseFirestore.instance
      .collection('menuItems')
      .where('restaurantId', isEqualTo: restaurantId)
      .where('category', isEqualTo: category)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList());
});

final menuManagementProvider = StateNotifierProvider<MenuManagementNotifier, AsyncValue<void>>((ref) {
  return MenuManagementNotifier();
});

class MenuManagementNotifier extends StateNotifier<AsyncValue<void>> {
  MenuManagementNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMenuItem(MenuItemModel menuItem) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('menuItems')
          .add(menuItem.toFirestore());
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateMenuItem(String menuItemId, Map<String, dynamic> updates) async {
    try {
      state = const AsyncValue.loading();
      
      // Convert DateTime to Timestamp for Firestore
      final updatedUpdates = Map<String, dynamic>.from(updates);
      if (updatedUpdates.containsKey('updatedAt') && updatedUpdates['updatedAt'] is DateTime) {
        updatedUpdates['updatedAt'] = Timestamp.fromDate(updatedUpdates['updatedAt']);
      }
      
      await _firestore
          .collection('menuItems')
          .doc(menuItemId)
          .update(updatedUpdates);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore
          .collection('menuItems')
          .doc(menuItemId)
          .delete();
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> toggleItemAvailability(String menuItemId, bool isAvailable) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore.collection('menuItems').doc(menuItemId).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> toggleTodaysSpecial(String menuItemId, bool isTodaysSpecial) async {
    try {
      state = const AsyncValue.loading();
      
      await _firestore.collection('menuItems').doc(menuItemId).update({
        'isTodaysSpecial': isTodaysSpecial,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> incrementOrderCount(String menuItemId) async {
    try {
      await _firestore.collection('menuItems').doc(menuItemId).update({
        'orderCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Don't throw error for analytics updates
    }
  }

  Future<List<MenuItemModel>> searchMenuItems(String restaurantId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('menuItems')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              item.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getMenuCategories(String restaurantId) async {
    try {
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