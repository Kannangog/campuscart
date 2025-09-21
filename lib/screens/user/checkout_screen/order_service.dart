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
    required dynamic orderService, // Changed from OrderManagement to dynamic
  }) async {
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
    final total = subtotal + deliveryFee + convenienceFee;

    // Create order
    final order = OrderModel(
      id: '',
      userId: user.uid,
      userName: user.displayName ?? 'Customer',
      userEmail: user.email ?? '',
      userPhone: user.phoneNumber ?? '',
      restaurantId: cartState.restaurantId!,
      restaurantName: cartState.restaurantName!,
      restaurantImage: cartState.restaurantImage ?? '',
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      convenienceFee: convenienceFee,
      tax: 0.0, // Set tax to 0
      discount: 0.0,
      total: total,
      status: OrderStatus.pending,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLocation.latitude,
      deliveryLongitude: deliveryLocation.longitude,
      specialInstructions: null,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'Cash on Delivery' 
          ? 'pending' 
          : 'completed',
      transactionId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      estimatedDeliveryTime: null,
      deliveredAt: null,
      driverId: null,
      driverName: null,
      cancellationReason: null,
    );

    // Place order and return order ID
    // Assuming orderService has a createOrder method that returns Future<String>
    return await orderService.createOrder(order);
  }
}