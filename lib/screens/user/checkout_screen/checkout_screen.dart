// ignore_for_file: use_build_context_synchronously

import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/providers/cart_provider.dart';
import 'package:campuscart/providers/order_provider.dart';
import 'package:campuscart/screens/user/checkout_screen/location_service.dart';
import 'package:campuscart/screens/user/checkout_screen/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedPaymentMethod = 'Cash on Delivery';
  String? _selectedHostel;
  bool _isLoadingLocation = false;
  bool _isPlacingOrder = false;
  bool _isExpanded = false;
  bool _phoneNumberRequired = false;

  final LocationService _locationService = LocationService();
  final OrderService _orderService = OrderService();

  // List of hostels (customize with your campus hostels)
  final List<String> _hostels = [
    'Select Hostel',
    'Hostel A',
    'Hostel B',
    'Hostel C',
    'Hostel D',
    'Hostel E',
    'Other (Specify in address)'
  ];

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
    _loadUserPhoneNumber();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Load user's phone number
  Future<void> _loadUserPhoneNumber() async {
    final authState = ref.read(authStateProvider);
    final user = authState.value;
    
    if (user != null && user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      setState(() {
        _phoneController.text = user.phoneNumber!;
      });
    } else {
      setState(() {
        _phoneNumberRequired = true;
      });
    }
  }

  // Save phone number to profile
  Future<void> _savePhoneNumber() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      
      if (user != null) {
        // Update user profile with phone number
        // This would typically call your user profile update method
        // For now, we'll just mark it as saved
        setState(() {
          _phoneNumberRequired = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving phone number: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load default address from shared preferences
  Future<void> _loadDefaultAddress() async {
    try {
      final locationData = await _locationService.loadDefaultAddress();
      
      if (locationData['address'] != null && 
          locationData['lat'] != null && 
          locationData['lng'] != null) {
        setState(() {
          _selectedAddress = locationData['address']!;
          _addressController.text = _selectedAddress;
          _selectedLocation = LatLng(locationData['lat']!, locationData['lng']!);
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final location = await _locationService.getCurrentLocation();
      
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
      final address = await _locationService.getAddressFromLatLng(location);
      
      setState(() {
        _selectedAddress = address;
        _addressController.text = address;
      });
    } catch (e) {
      // Handle address lookup error silently
    }
  }

  Future<void> _placeOrder() async {
    // Check if phone number is required
    if (_phoneNumberRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your phone number first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

      // Create order
      final orderId = await _orderService.createOrder(
        user: user,
        cartState: cartState,
        cartNotifier: cartNotifier,
        deliveryAddress: _addressController.text,
        deliveryLocation: _selectedLocation!,
        paymentMethod: _selectedPaymentMethod,
        orderService: orderService,
      );

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
    const convenienceFee = 0.0; // Changed to 0 as requested
    const deliveryFee = 0.0; // Free delivery for all orders
    final total = subtotal + deliveryFee + convenienceFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.lightGreen, // Light green background
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.lightGreen.shade50, // Light green background for entire screen
        child: Column(
          children: [
            // Checkout title
            Container(
              color: Colors.lightGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_checkout, size: 28, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Checkout',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone Number Section (if required)
                    if (_phoneNumberRequired)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Phone Number Required',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'We need your phone number for delivery updates',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _savePhoneNumber,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Save Phone Number'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.3),
                    
                    if (_phoneNumberRequired) const SizedBox(height: 16),
                    
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
                                const Spacer(),
                                IconButton(
                                  icon: Icon(
                                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                ),
                              ],
                            ),
                            
                            if (_isExpanded) ...[
                              const SizedBox(height: 16),
                              
                              // Map with improved UI
                              Container(
                                height: 200,
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
                            ],
                            
                            // Hostel dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedHostel ?? _hostels[0],
                              items: _hostels.map((String hostel) {
                                return DropdownMenuItem<String>(
                                  value: hostel,
                                  child: Text(hostel),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedHostel = newValue;
                                  if (newValue != null && newValue != 'Select Hostel' && newValue != 'Other (Specify in address)') {
                                    _addressController.text = newValue;
                                  } else if (newValue == 'Select Hostel') {
                                    _addressController.text = '';
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Select Hostel',
                                prefixIcon: const Icon(Icons.apartment),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            
                            if (_selectedHostel == 'Other (Specify in address)' || 
                                (_selectedHostel != null && _selectedHostel != 'Select Hostel' && _isExpanded)) ...[
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
                            ],
                            
                            const SizedBox(height: 16),
                            
                            // Use Current Location Button only
                            SizedBox(
                              width: double.infinity,
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
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.3),
                    
                    const SizedBox(height: 16),
                    
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
                    
                    const SizedBox(height: 16),
                    
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
                    
                    // Place Order Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder || _phoneNumberRequired ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          foregroundColor: Colors.white,
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
                    
                    const SizedBox(height: 16), // Extra space at the bottom
                  ],
                ),
              ),
            ),
          ],
        ),
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