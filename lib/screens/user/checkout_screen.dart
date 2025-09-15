// ignore_for_file: empty_catches

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isLoadingLocation = false;
  bool _isPlacingOrder = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Credit Card',
    'Debit Card',
    'UPI',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = location;
      });

      await _getAddressFromLatLng(location);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Set default location (you can change this to your city's coordinates)
      setState(() {
        _selectedLocation = const LatLng(28.6139, 77.2090); // New Delhi
        _selectedAddress = 'New Delhi, India';
        _addressController.text = _selectedAddress;
      });
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.postalCode ?? ''}';
        
        setState(() {
          _selectedAddress = address;
          _addressController.text = address;
        });
      }
    } catch (e) {
      // Handle address lookup error silently
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      if (user == null) throw Exception('User not authenticated');

      final cartState = ref.read(cartProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final orderService = ref.read(orderManagementProvider); // Fixed: Direct access

      // Get restaurant info from cart
      if (cartState.restaurantId == null || cartState.restaurantName == null) {
        throw Exception('No restaurant selected');
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
      final deliveryFee = cartNotifier.calculateDeliveryFee();
      final tax = cartNotifier.calculateTax();
      final total = cartNotifier.calculateTotal();

      // Create order
      final order = OrderModel(
        id: '', // Will be generated by Firestore
        userId: user.uid,
        userName: user.displayName ?? 'Customer',
        userEmail: user.email ?? '',
        userPhone: user.phoneNumber ?? '',
        restaurantId: cartState.restaurantId!, // This is a String
        restaurantName: cartState.restaurantName!, // This is a String
        restaurantImage: cartState.restaurantImage ?? '', // This is a String or null
        items: orderItems,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        tax: tax,
        discount: 0.0, // You can add discount logic here
        total: total,
        status: OrderStatus.pending,
        deliveryAddress: _addressController.text,
        deliveryLatitude: _selectedLocation!.latitude,
        deliveryLongitude: _selectedLocation!.longitude,
        specialInstructions: _instructionsController.text.isNotEmpty 
            ? _instructionsController.text 
            : null,
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: _selectedPaymentMethod == 'Cash on Delivery' 
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

      // Place order - Fixed: Use orderService directly
      final orderId = await orderService.createOrder(order);

      // Clear cart
      cartNotifier.clearCart();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${orderId.substring(0, 8).toUpperCase()} placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (cartState.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
        ),
        body: const Center(
          child: Text('Your cart is empty'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Location Section
            Text(
              'Delivery Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().slideX(begin: -0.3),
            
            const SizedBox(height: 16),
            
            // Map
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isLoadingLocation
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedLocation != null
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation!,
                              zoom: 15,
                            ),
                            onTap: (location) async {
                              setState(() {
                                _selectedLocation = location;
                              });
                              await _getAddressFromLatLng(location);
                            },
                            markers: {
                              Marker(
                                markerId: const MarkerId('delivery'),
                                position: _selectedLocation!,
                                infoWindow: const InfoWindow(title: 'Delivery Location'),
                              ),
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Text('Unable to load map'),
                            ),
                          ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 16),
            
            // Address Input
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
            
            const SizedBox(height: 16),
            
            // Get Current Location Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoadingLocation ? 'Getting Location...' : 'Use Current Location'),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 32),
            
            // Special Instructions
            Text(
              'Special Instructions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                hintText: 'Any special instructions for the delivery...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3),
            
            const SizedBox(height: 32),
            
            // Payment Method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 1200.ms).slideX(begin: -0.3),
            
            const SizedBox(height: 16),
            
            ...List.generate(_paymentMethods.length, (index) {
              final method = _paymentMethods[index];
              return RadioListTile<String>(
                title: Text(method),
                value: method,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ).animate().fadeIn(delay: (1400 + index * 100).ms).slideX(begin: -0.3);
            }),
            
            const SizedBox(height: 32),
            
            // Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('₹${cartNotifier.calculateSubtotal().toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        Text('₹${cartNotifier.calculateDeliveryFee().toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax (5%)'),
                        Text('₹${cartNotifier.calculateTax().toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${cartNotifier.calculateTotal().toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 1800.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 32),
            
            // Place Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isPlacingOrder
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Placing Order...'),
                        ],
                      )
                    : Text(
                        'Place Order - ₹${cartNotifier.calculateTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ).animate().fadeIn(delay: 2000.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}