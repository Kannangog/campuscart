// ignore_for_file: deprecated_member_use

import 'package:campuscart/models/menu_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../providers/cart_provider.dart';
import 'checkout_screen/checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load cart from storage when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCartFromStorage();
    });
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      // Check if cart is already loaded
      final currentCart = ref.read(cartProvider);
      if (currentCart.isEmpty) {
        // Load from storage only if current cart is empty
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString('cart');
        
        if (cartJson != null) {
          final cartData = jsonDecode(cartJson);
          final items = (cartData['items'] as List).map((itemData) {
            final menuItemData = itemData['menuItem'];
            
            return CartItem(
              menuItem: MenuItemModel(
                id: menuItemData['id'] ?? '',
                restaurantId: menuItemData['restaurantId'] ?? '',
                name: menuItemData['name'] ?? '',
                description: menuItemData['description'] ?? '',
                price: (menuItemData['price'] ?? 0.0).toDouble(),
                specialOfferPrice: menuItemData['specialOfferPrice']?.toDouble(),
                imageUrl: menuItemData['imageUrl'] ?? '',
                category: menuItemData['category'] ?? 'Main Course',
                isAvailable: menuItemData['isAvailable'] ?? true,
                isVegetarian: menuItemData['isVegetarian'] ?? false,
                isVegan: menuItemData['isVegan'] ?? false,
                isSpicy: menuItemData['isSpicy'] ?? false,
                isTodaysSpecial: menuItemData['isTodaysSpecial'] ?? false,
                allergens: List<String>.from(menuItemData['allergens'] ?? []),
                preparationTime: menuItemData['preparationTime'] ?? 15,
                rating: (menuItemData['rating'] ?? 0.0).toDouble(),
                reviewCount: menuItemData['reviewCount'] ?? 0,
                orderCount: menuItemData['orderCount'] ?? 0,
                createdAt: DateTime.fromMillisecondsSinceEpoch(menuItemData['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(menuItemData['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
                restaurantImage: menuItemData['restaurantImage'] ?? '',
                restaurantName: menuItemData['restaurantName'] ?? '',
              ),
              quantity: itemData['quantity'] ?? 1,
              specialInstructions: itemData['specialInstructions'],
            );
          }).toList();
          
          cartNotifier.loadCart(items);
        }
      }
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Cart'),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () {
                _showClearCartDialog(context, ref);
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: cartState.isEmpty
            ? _buildEmptyCart(context)
            : Column(
                children: [
                  // Cart Items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      itemCount: cartState.items.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartState.items[index];
                        final menuItem = cartItem.menuItem;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Item Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: menuItem.imageUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Item Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        menuItem.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '₹${menuItem.discountedPrice.toStringAsFixed(2)} each',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (menuItem.isOnSale)
                                        Text(
                                          '₹${menuItem.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '₹${cartItem.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity Controls
                                Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              cartNotifier.decrementQuantity(
                                                menuItem.id,
                                                specialInstructions: cartItem.specialInstructions,
                                              );
                                            },
                                            icon: const Icon(Icons.remove, size: 16, color: Colors.black),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                          Text(
                                            '${cartItem.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              cartNotifier.incrementQuantity(
                                                menuItem.id,
                                                specialInstructions: cartItem.specialInstructions,
                                              );
                                            },
                                            icon: const Icon(Icons.add, size: 16, color: Colors.black),
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        cartNotifier.removeItem(
                                          menuItem.id,
                                          specialInstructions: cartItem.specialInstructions,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${menuItem.name} removed from cart'),
                                            duration: const Duration(seconds: 1),
                                            backgroundColor: const Color(0xFF4CAF50), // Light green
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.3);
                      },
                    ),
                  ),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildOrderRow('Subtotal', '₹${cartState.subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildOrderRow(
                          'Delivery Fee',
                          Row(
                            children: [
                              Text(
                                '₹25.00',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Free', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildOrderRow('Convenience Fee', 'Free'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${(cartState.subtotal).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CheckoutScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50), // Light green
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Place Order (${cartState.totalItems} ${cartState.totalItems == 1 ? 'item' : 'items'})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Container(
      color: Colors.white, // This ensures no white space on sides
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),
          
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          
          const SizedBox(height: 12),
          
          Text(
            'Add some delicious items to get started!',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.restaurant, color: Colors.white),
            label: const Text('Browse Restaurants', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50), // Light green
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildOrderRow(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 16,
          ),
        ),
        if (value is String) 
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ) 
        else 
          value,
      ],
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart', style: TextStyle(color: Colors.black)),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF4CAF50), // Light green
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}