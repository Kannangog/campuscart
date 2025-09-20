import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isLoadingLocation = false;
  bool _isPlacingOrder = false;
  bool _isSettingDefault = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Credit Card (Coming Soon)',
    'Debit Card (Coming Soon)',
    'UPI (Coming Soon)',
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Load default address from shared preferences
  Future<void> _loadDefaultAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultAddress = prefs.getString('defaultAddress');
      final defaultLat = prefs.getDouble('defaultLat');
      final defaultLng = prefs.getDouble('defaultLng');
      
      if (defaultAddress != null && defaultLat != null && defaultLng != null) {
        setState(() {
          _selectedAddress = defaultAddress;
          _addressController.text = defaultAddress;
          _selectedLocation = LatLng(defaultLat, defaultLng);
        });
      } else {
        // If no default address, get current location
        _getCurrentLocation();
      }
    } catch (e) {
      // If error loading default, get current location
      _getCurrentLocation();
    }
  }

  // Save address as default
  Future<void> _setDefaultAddress() async {
    if (_selectedLocation == null || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSettingDefault = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('defaultAddress', _addressController.text);
      await prefs.setDouble('defaultLat', _selectedLocation!.latitude);
      await prefs.setDouble('defaultLng', _selectedLocation!.longitude);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address set as default'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving default address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSettingDefault = false);
    }
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
      // Set default location
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
      final orderService = ref.read(orderManagementProvider);

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
      const deliveryFee = 0.0; // Free delivery
      const convenienceFee = 5.0;
      // Removed tax calculation
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
        deliveryAddress: _addressController.text,
        deliveryLatitude: _selectedLocation!.latitude,
        deliveryLongitude: _selectedLocation!.longitude,
        specialInstructions: null,
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

      // Place order
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Your cart is empty'),
        ),
      );
    }

    final subtotal = cartNotifier.calculateSubtotal();
    const convenienceFee = 5.0;
    const deliveryFee = 0.0; // Free delivery for all orders
    final total = subtotal + deliveryFee + convenienceFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Checkout title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_checkout, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Checkout',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Location Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Delivery Location',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Map with improved UI
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _isLoadingLocation
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 8),
                                          Text('Getting your location...'),
                                        ],
                                      ),
                                    )
                                  : _selectedLocation != null
                                      ? Stack(
                                          children: [
                                            GoogleMap(
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
                                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                                ),
                                              },
                                            ),
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: FloatingActionButton.small(
                                                onPressed: _getCurrentLocation,
                                                child: const Icon(Icons.my_location),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          color: Colors.grey.shade100,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.location_off, size: 40, color: Colors.grey),
                                                const SizedBox(height: 8),
                                                const Text('Location not available'),
                                                const SizedBox(height: 16),
                                                ElevatedButton(
                                                  onPressed: _getCurrentLocation,
                                                  child: const Text('Try Again'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Address Input with improved UI
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Delivery Address',
                              prefixIcon: const Icon(Icons.home),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 2,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Location buttons row
                          Row(
                            children: [
                              // Get Current Location Button
                              Expanded(
                                child: FilledButton.tonalIcon(
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
                              ),
                              const SizedBox(width: 12),
                              // Set as Default Button
                              ElevatedButton(
                                onPressed: _isSettingDefault ? null : _setDefaultAddress,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.grey.shade800,
                                ),
                                child: _isSettingDefault
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.star_border),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.3),
                  
                  const SizedBox(height: 24),
                  
                  // Payment Method
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Payment Method',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          ...List.generate(_paymentMethods.length, (index) {
                            final method = _paymentMethods[index];
                            final isEnabled = method == 'Cash on Delivery';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isEnabled ? null : Colors.grey.shade100,
                              child: RadioListTile<String>(
                                title: Text(
                                  method,
                                  style: TextStyle(
                                    color: isEnabled ? null : Colors.grey.shade600,
                                  ),
                                ),
                                value: method,
                                groupValue: _selectedPaymentMethod,
                                onChanged: isEnabled
                                    ? (value) {
                                        setState(() {
                                          _selectedPaymentMethod = value!;
                                        });
                                      }
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 24),
                  
                  // Order Summary
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Order Summary',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildOrderRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
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
                                Text('Free', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildOrderRow('Convenience Fee', '₹${convenienceFee.toStringAsFixed(2)}'),
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
                                '₹${total.toStringAsFixed(2)}',
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
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 24),
                  
                  // Place Order Button (now positioned higher up)
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
                              'Place Order - ₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 24), // Extra space at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderRow(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        if (value is String) Text(value) else value,
      ],
    );
  }
}