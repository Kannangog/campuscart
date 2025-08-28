import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';

class CartItem {
  final MenuItemModel menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.price * quantity;
}

class CartState {
  final List<CartItem> items;
  final String? restaurantId;
  final String? restaurantName;

  CartState({
    this.items = const [],
    this.restaurantId,
    this.restaurantName,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    String? restaurantId,
    String? restaurantName,
  }) {
    return CartState(
      items: items ?? this.items,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(MenuItemModel menuItem, String restaurantName) {
    // If cart has items from different restaurant, clear it
    if (state.restaurantId != null && state.restaurantId != menuItem.restaurantId) {
      _showRestaurantChangeDialog();
      return;
    }

    final existingIndex = state.items.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = [...state.items];
      updatedItems[existingIndex].quantity++;
    } else {
      updatedItems = [...state.items, CartItem(menuItem: menuItem)];
    }

    state = state.copyWith(
      items: updatedItems,
      restaurantId: menuItem.restaurantId,
      restaurantName: restaurantName,
    );
  }

  void removeItem(String menuItemId) {
    final updatedItems = state.items.where(
      (item) => item.menuItem.id != menuItemId,
    ).toList();

    if (updatedItems.isEmpty) {
      state = CartState();
    } else {
      state = state.copyWith(items: updatedItems);
    }
  }

  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.menuItem.id == menuItemId) {
        item.quantity = quantity;
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = CartState();
  }

  void _showRestaurantChangeDialog() {
    // This would typically show a dialog to confirm restaurant change
    // For now, we'll just clear the cart and add the new item
    clearCart();
  }

  double calculateDeliveryFee() {
    // This could be dynamic based on distance, restaurant, etc.
    return state.isEmpty ? 0.0 : 2.99;
  }

  double calculateTax() {
    return state.subtotal * 0.08; // 8% tax
  }

  double calculateTotal() {
    return state.subtotal + calculateDeliveryFee() + calculateTax();
  }
}