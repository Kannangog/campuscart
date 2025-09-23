import 'dart:math';

import 'package:campuscart/models/order_model.dart';
import 'package:campuscart/providers/cart_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  // Create a new order
  Future<String> createOrder({
    required User user,
    required CartState cartState,
    required CartNotifier cartNotifier,
    required String deliveryAddress,
    required LatLng deliveryLocation,
    required String paymentMethod,
    required dynamic orderService,
    required String phoneNumber, String? mapLink,
  }) async {
    // Validate required fields
    if (cartState.restaurantId == null || cartState.restaurantName == null) {
      throw Exception('Restaurant information is missing');
    }

    if (cartState.items.isEmpty) {
      throw Exception('Cart is empty');
    }

    // Create order items
    final orderItems = cartState.items.map((cartItem) {
      return OrderItem(
        id: cartItem.menuItem.id,
        name: cartItem.menuItem.name,
        description: cartItem.menuItem.description,
        price: cartItem.menuItem.price,
        quantity: cartItem.quantity,
        imageUrl: cartItem.menuItem.imageUrl,
        specialInstructions: cartItem.specialInstructions,
      );
    }).toList();

    // Calculate order totals
    final subtotal = cartNotifier.calculateSubtotal();
    const deliveryFee = 0.0; // Free delivery
    const convenienceFee = 5.0;
    const taxRate = 0.08; // 8% tax rate
    final tax = subtotal * taxRate;
    final total = subtotal + deliveryFee + convenienceFee + tax;

    // Create order
    final order = OrderModel(
      id: '',
      userId: user.uid,
      userName: user.displayName ?? 'Customer',
      userEmail: user.email ?? '',
      userPhone: phoneNumber.isNotEmpty ? phoneNumber : (user.phoneNumber ?? ''),
      restaurantId: cartState.restaurantId!,
      restaurantName: cartState.restaurantName!,
      restaurantImage: cartState.restaurantImage ?? '',
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      convenienceFee: convenienceFee,
      tax: tax,
      discount: 0.0,
      total: total,
      status: OrderStatus.pending,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLocation.latitude,
      deliveryLongitude: deliveryLocation.longitude, // Use cart-level special instructions
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod.toLowerCase().contains('cash') 
          ? 'pending' 
          : 'completed',
      transactionId: _generateTransactionId(paymentMethod),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      estimatedDeliveryTime: _calculateEstimatedDeliveryTime(),
      deliveredAt: null,
      driverId: null,
      driverName: null,
      cancellationReason: null,
    );

    try {
      // Place order and return order ID
      final orderId = await orderService.createOrder(order);
      
      // Clear cart after successful order creation
      cartNotifier.clearCart();
      
      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  // Generate a transaction ID for non-cash payments
  String? _generateTransactionId(String paymentMethod) {
    if (paymentMethod.toLowerCase().contains('cash')) {
      return null;
    }
    return 'txn_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  // Generate random string for transaction ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Calculate estimated delivery time (30-45 minutes from now)
  DateTime _calculateEstimatedDeliveryTime() {
    return DateTime.now().add(Duration(minutes: 30 + Random().nextInt(16)));
  }
}