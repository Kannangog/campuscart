import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';

class CartItem {
  final MenuItemModel menuItem;
  int quantity;
  final String? specialInstructions;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => (menuItem.specialOfferPrice ?? menuItem.price) * quantity;

  CartItem copyWith({
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItem(
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.menuItem.id == menuItem.id &&
        other.specialInstructions == specialInstructions;
  }

  @override
  int get hashCode => Object.hash(menuItem.id, specialInstructions);
}

class CartState {
  final List<CartItem> items;
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantImage;

  CartState({
    this.items = const [],
    this.restaurantId,
    this.restaurantName,
    this.restaurantImage,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get hasItems => items.isNotEmpty;
  int get length => items.length; // Fixed: Return actual length
  bool get isNotEmpty => items.isNotEmpty; // Fixed: Return actual boolean value

  CartState copyWith({
    List<CartItem>? items,
    String? restaurantId,
    String? restaurantName,
    String? restaurantImage,
  }) {
    return CartState(
      items: items ?? this.items,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantImage: restaurantImage ?? this.restaurantImage,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(MenuItemModel menuItem, String restaurantName, String s, {String? specialInstructions}) {
    // If cart has items from different restaurant, clear it first
    if (state.restaurantId != null && state.restaurantId != menuItem.restaurantId) {
      clearCart();
    }

    final existingIndex = state.items.indexWhere(
      (item) => item.menuItem.id == menuItem.id && item.specialInstructions == specialInstructions,
    );

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
    } else {
      updatedItems = [
        ...state.items, 
        CartItem(
          menuItem: menuItem, 
          specialInstructions: specialInstructions,
        )
      ];
    }

    state = state.copyWith(
      items: updatedItems,
      restaurantId: menuItem.restaurantId,
      restaurantName: menuItem.restaurantName, // Added restaurant name
      restaurantImage: menuItem.restaurantImage, // Added restaurant image
    );
  }

  void removeItem(String menuItemId, {String? specialInstructions}) {
    final updatedItems = state.items.where(
      (item) => !(item.menuItem.id == menuItemId && item.specialInstructions == specialInstructions),
    ).toList();

    if (updatedItems.isEmpty) {
      state = CartState();
    } else {
      state = state.copyWith(items: updatedItems);
    }
  }

  void updateQuantity(String menuItemId, int quantity, {String? specialInstructions}) {
    if (quantity <= 0) {
      removeItem(menuItemId, specialInstructions: specialInstructions);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.menuItem.id == menuItemId && item.specialInstructions == specialInstructions) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void updateSpecialInstructions(String menuItemId, String specialInstructions) {
    final updatedItems = state.items.map((item) {
      if (item.menuItem.id == menuItemId) {
        return item.copyWith(specialInstructions: specialInstructions);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void incrementQuantity(String menuItemId, {String? specialInstructions}) {
    final updatedItems = state.items.map((item) {
      if (item.menuItem.id == menuItemId && item.specialInstructions == specialInstructions) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void decrementQuantity(String menuItemId, {String? specialInstructions}) {
    final updatedItems = state.items.map((item) {
      if (item.menuItem.id == menuItemId && item.specialInstructions == specialInstructions) {
        final newQuantity = item.quantity - 1;
        if (newQuantity <= 0) {
          return null; // Remove item if quantity becomes 0
        }
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).where((item) => item != null).cast<CartItem>().toList();

    if (updatedItems.isEmpty) {
      state = CartState();
    } else {
      state = state.copyWith(items: updatedItems);
    }
  }

  void clearCart() {
    state = CartState();
  }

  double calculateDeliveryFee() {
    if (state.isEmpty) return 0.0;
    
    // Example: Free delivery for orders above ₹300, otherwise ₹40
    return state.subtotal > 300 ? 0.0 : 40.0;
  }

  double calculateTax() {
    // 5% GST on food items
    return state.subtotal * 0.05;
  }

  double calculateSubtotal() {
    return state.subtotal;
  }

  double calculateTotal() {
    return calculateSubtotal() + calculateDeliveryFee() + calculateTax();
  }

  double calculateDiscount() {
    double discount = 0.0;
    for (final item in state.items) {
      if (item.menuItem.specialOfferPrice != null) {
        final regularPrice = item.menuItem.price;
        final offerPrice = item.menuItem.specialOfferPrice!;
        discount += (regularPrice - offerPrice) * item.quantity;
      }
    }
    return discount;
  }

  bool isFromSameRestaurant(String restaurantId) {
    return state.restaurantId == restaurantId;
  }

  void mergeCart(CartState newCart) {
    state = newCart;
  }

  CartItem? getCartItem(String menuItemId, {String? specialInstructions}) {
    try {
      return state.items.firstWhere(
        (item) => item.menuItem.id == menuItemId && item.specialInstructions == specialInstructions,
      );
    } catch (e) {
      return null;
    }
  }

  bool hasItemWithSameInstructions(String menuItemId, String specialInstructions) {
    return state.items.any(
      (item) => item.menuItem.id == menuItemId && item.specialInstructions == specialInstructions,
    );
  }
}

// Helper function to show restaurant change dialog
Future<bool?> showRestaurantChangeDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Change Restaurant?'),
      content: const Text(
        'Your cart contains items from another restaurant. '
        'Adding this item will clear your current cart.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Clear Cart'),
        ),
      ],
    ),
  );
}