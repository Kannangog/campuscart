// ignore_for_file: use_build_context_synchronously

import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/providers/cart_provider.dart';
import 'package:campuscart/providers/order_provider.dart';
import 'package:campuscart/screens/user/checkout_screen/location_service.dart';
import 'package:campuscart/screens/user/checkout_screen/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _phoneNumberRequired = false;
  bool _showPhoneInput = false;
  bool _useCurrentLocation = true;
  bool _useHostelLocation = false;
  GoogleMapController? _mapController;

  final LocationService _locationService = LocationService();
  final OrderService _orderService = OrderService();

  // Hostel data with names and Google Maps links
  final List<Map<String, dynamic>> _hostels = [
    {
      'name': 'Select Hostel', 
      'location': null,
      'mapLink': null,
    },
    {
      'name': 'Kaveri Hostel', 
      'location': const LatLng(17.4279024,76.6699088), // Approximate coordinates for map display
      'mapLink': 'https://maps.app.goo.gl/ahGTt23Nkakxp1vX7',
    },
    {
      'name': 'Godavari Hostel', 
      'location': const LatLng(17.42552270611511, 76.67230570239624),
      'mapLink': 'https://maps.app.goo.gl/aLYqv5uXz99awBCy6',
    },
    {
      'name': 'Ganga Hostel', 
      'location': const LatLng(17.425876522584524, 76.67224775490773),
      'mapLink': 'https://maps.app.goo.gl/g4GMg6a9iQjqv77v7',
    },
    {
      'name': 'Tungabhadra Hostel', 
      'location': const LatLng(117.437957710758997, 76.67310340549614),
      'mapLink': 'https://maps.app.goo.gl/deHYYMhDs8ssUBCv5',
    },
    {
      'name': 'Amarja Hostel', 
      'location': const LatLng(17.439203287065812, 76.67453505962531),
      'mapLink': 'https://maps.app.goo.gl/W6MWSt2L4RVsQKnj8',
    },
    {
      'name': 'Manjira Hostel', 
      'location': const LatLng(17.438118300676955, 76.67487301794795),
      'mapLink': 'https://maps.app.goo.gl/WsdQf5FbnNZ2uvQ8A',
    },
    {
      'name': 'Krishna Hostel', 
      'location': const LatLng(17.438343487061985, 76.67545237507244),
      'mapLink': 'https://maps.app.goo.gl/uSu7GLoXtCr5dNLf9',
    },
    {
      'name': 'Malaprabha Hostel', 
      'location': const LatLng(17.440273578556045, 76.674615229487),
      'mapLink': 'https://maps.app.goo.gl/tM2LX6CHTmBo3odz6',
    },
    {
      'name': 'Bheema Hostel', 
      'location': const LatLng(17.43871859659864, 76.67435545767128),
      'mapLink': 'https://maps.app.goo.gl/QbvhUEV8JBbQDidn8',
    },
    {
      'name': 'Science Block', 
      'location': const LatLng(17.43339452740265, 76.6711574367803),
      'mapLink': 'https://maps.app.goo.gl/5yxp2YHRN6KnE8hX9',
    },
    {
      'name': 'Yamuna Hostel', 
      'location': const LatLng(17.425442557018915, 76.671959),
      'mapLink': 'https://maps.app.goo.gl/bWgMWMm3GLuC99Af8',
    },
    {
      'name': 'Other (Specify in address)', 
      'location': null,
      'mapLink': null,
    },
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
    _mapController?.dispose();
    super.dispose();
  }

  // Load user's phone number
  Future<void> _loadUserPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhoneNumber = prefs.getString('user_phone_number');
      
      if (savedPhoneNumber != null && savedPhoneNumber.isNotEmpty) {
        setState(() {
          _phoneController.text = savedPhoneNumber;
          _phoneNumberRequired = false;
          _showPhoneInput = false;
        });
        return;
      }
      
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      
      if (user != null && user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        await prefs.setString('user_phone_number', user.phoneNumber!);
        
        setState(() {
          _phoneController.text = user.phoneNumber!;
          _phoneNumberRequired = false;
          _showPhoneInput = false;
        });
      } else {
        setState(() {
          _phoneNumberRequired = true;
          _showPhoneInput = true;
        });
      }
    } catch (e) {
      setState(() {
        _phoneNumberRequired = true;
        _showPhoneInput = true;
      });
    }
  }

  // Save phone number
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

    setState(() => _isPlacingOrder = true);

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'phoneNumber': _phoneController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone_number', _phoneController.text);
      
      setState(() {
        _phoneNumberRequired = false;
        _showPhoneInput = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving phone number: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  // Load default address
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
        _getCurrentLocation();
      }
    } catch (e) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final location = await _locationService.getCurrentLocation();
      
      setState(() {
        _selectedLocation = location;
        _useCurrentLocation = true;
        _useHostelLocation = false;
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
      // Set default to first hostel
      _setHostelLocation(_hostels[1]);
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

  // Method to set hostel location
  void _setHostelLocation(Map<String, dynamic> hostel) {
    if (hostel['location'] != null) {
      setState(() {
        _selectedLocation = hostel['location'];
        _selectedAddress = hostel['name'];
        _addressController.text = hostel['name'];
        _selectedHostel = hostel['name'];
      });
      
      // Animate map to the new location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(hostel['location'], 17.0),
      );
    }
  }

  // Method to handle hostel selection
  void _onHostelSelected(String? hostelName) {
    if (hostelName == null) return;
    
    final selectedHostel = _hostels.firstWhere(
      (hostel) => hostel['name'] == hostelName,
      orElse: () => _hostels[0],
    );
    
    if (hostelName == 'Select Hostel') {
      setState(() {
        _selectedHostel = hostelName;
        _addressController.text = '';
        _selectedAddress = '';
      });
    } else if (hostelName == 'Other (Specify in address)') {
      setState(() {
        _selectedHostel = hostelName;
        _addressController.text = '';
        _selectedAddress = '';
      });
    } else {
      _setHostelLocation(selectedHostel);
    }
  }

  // Method to open Google Maps app with hostel location
  Future<void> _openHostelInMaps() async {
    if (_selectedHostel == null || 
        _selectedHostel == 'Select Hostel' || 
        _selectedHostel == 'Other (Specify in address)') {
      return;
    }
    
    final selectedHostel = _hostels.firstWhere(
      (hostel) => hostel['name'] == _selectedHostel,
      orElse: () => _hostels[0],
    );
    
    final mapLink = selectedHostel['mapLink'];
    if (mapLink != null) {
      final uri = Uri.parse(mapLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_phoneNumberRequired) {
      setState(() {
        _showPhoneInput = true;
      });
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

      if (cartState.restaurantId == null || cartState.restaurantName == null) {
        throw Exception('No restaurant selected');
      }

      // Store the map link if it's a hostel
      String? mapLink;
      if (_selectedHostel != null && 
          _selectedHostel != 'Select Hostel' && 
          _selectedHostel != 'Other (Specify in address)') {
        final selectedHostel = _hostels.firstWhere(
          (hostel) => hostel['name'] == _selectedHostel,
          orElse: () => _hostels[0],
        );
        mapLink = selectedHostel['mapLink'];
      }

      final orderId = await _orderService.createOrder(
        user: user,
        cartState: cartState,
        cartNotifier: cartNotifier,
        deliveryAddress: _addressController.text,
        deliveryLocation: _selectedLocation!,
        paymentMethod: _selectedPaymentMethod,
        orderService: orderService,
        phoneNumber: _phoneController.text,
        mapLink: mapLink, // Pass the Google Maps link to the order
      );

      cartNotifier.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${orderId.substring(0, 8).toUpperCase()} placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

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
    const convenienceFee = 0.0;
    const deliveryFee = 0.0;
    final total = subtotal + deliveryFee + convenienceFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.lightGreen.shade50,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone Number Section
                    if (_showPhoneInput)
                      _buildPhoneNumberSection(),
                    
                    if (_showPhoneInput) const SizedBox(height: 16),
                    
                    if (!_showPhoneInput && !_phoneNumberRequired && _phoneController.text.isNotEmpty)
                      _buildSavedPhoneNumberSection(),
                    
                    if (!_showPhoneInput && !_phoneNumberRequired && _phoneController.text.isNotEmpty) 
                      const SizedBox(height: 16),
                    
                    // Delivery Location Section
                    _buildDeliveryLocationSection(),
                    
                    const SizedBox(height: 16),
                    
                    // Payment Method
                    _buildPaymentMethodSection(),
                    
                    const SizedBox(height: 16),
                    
                    // Order Summary
                    _buildOrderSummarySection(subtotal, deliveryFee, convenienceFee, total),
                    
                    const SizedBox(height: 24),
                    
                    // Place Order Button
                    _buildPlaceOrderButton(total),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savePhoneNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Phone Number'),
                  ),
                ),
                const SizedBox(width: 8),
                if (!_phoneNumberRequired)
                  IconButton(
                    onPressed: () => setState(() => _showPhoneInput = false),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  Widget _buildSavedPhoneNumberSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone Number',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _phoneController.text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () => setState(() => _showPhoneInput = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit phone number',
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  Widget _buildDeliveryLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade100, width: 1),
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
            
            // Location selection options
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Current Location'),
                    selected: _useCurrentLocation,
                    selectedColor: Colors.lightGreen,
                    labelStyle: TextStyle(
                      color: _useCurrentLocation ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _useCurrentLocation = true;
                          _useHostelLocation = false;
                        });
                        _getCurrentLocation();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Select Hostel'),
                    selected: _useHostelLocation,
                    selectedColor: Colors.lightGreen,
                    labelStyle: TextStyle(
                      color: _useHostelLocation ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _useHostelLocation = selected;
                        _useCurrentLocation = !selected;
                        if (selected) {
                          _selectedHostel = _hostels[0]['name'];
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Map or Hostel selection based on choice
            if (_useCurrentLocation)
              _buildCurrentLocationMap(),
            
            if (_useHostelLocation) ...[
              _buildHostelSelection(),
              
              if (_selectedHostel == 'Other (Specify in address)') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Delivery Address',
                    prefixIcon: const Icon(Icons.home),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 2,
                ),
              ],
            ],
            
            const SizedBox(height: 16),
            
            // Address display with map link button
            if (_selectedAddress.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.lightGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedAddress,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_selectedHostel != null && 
                        _selectedHostel != 'Select Hostel' && 
                        _selectedHostel != 'Other (Specify in address)')
                      IconButton(
                        onPressed: _openHostelInMaps,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        tooltip: 'Open in Google Maps',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3);
  }

  Widget _buildCurrentLocationMap() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isLoadingLocation
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen),
                    ),
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
                          zoom: 17.0, // Higher zoom for better precision
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        onTap: (location) async {
                          setState(() => _selectedLocation = location);
                          await _getAddressFromLatLng(location);
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId('delivery'),
                            position: _selectedLocation!,
                            infoWindow: InfoWindow(title: _selectedAddress),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          ),
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: FloatingActionButton.small(
                          onPressed: _getCurrentLocation,
                          backgroundColor: Colors.lightGreen,
                          child: const Icon(Icons.my_location, color: Colors.white),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildHostelSelection() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedHostel ?? _hostels[0]['name'],
          items: _hostels.map((Map<String, dynamic> hostel) {
            return DropdownMenuItem<String>(
              value: hostel['name'],
              child: Text(hostel['name']),
            );
          }).toList(),
          onChanged: _onHostelSelected,
          decoration: InputDecoration(
            labelText: 'Select Hostel',
            prefixIcon: const Icon(Icons.apartment),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        
        if (_selectedHostel != null && 
            _selectedHostel != 'Select Hostel' && 
            _selectedHostel != 'Other (Specify in address)') ...[
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation ?? const LatLng(12.9239, 77.4987),
                  zoom: 17.0,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _selectedLocation != null
                    ? {
                        Marker(
                          markerId: const MarkerId('hostel'),
                          position: _selectedLocation!,
                          infoWindow: InfoWindow(title: _selectedHostel),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                      }
                    : {},
                myLocationEnabled: true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade100, width: 1),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: RadioListTile<String>(
                  title: Text(
                    method,
                    style: TextStyle(color: isEnabled ? null : Colors.grey.shade600),
                  ),
                  value: method,
                  groupValue: _selectedPaymentMethod,
                  onChanged: isEnabled
                      ? (value) => setState(() => _selectedPaymentMethod = value!)
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  activeColor: Colors.lightGreen,
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3);
  }

  Widget _buildOrderSummarySection(double subtotal, double deliveryFee, double convenienceFee, double total) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200, width: 1),
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
                  const Text('Free', style: TextStyle(
                    color: Colors.lightGreen,
                    fontWeight: FontWeight.bold,
                  )),
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
                    color: Colors.lightGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildPlaceOrderButton(double total) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
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
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3);
  }
  
  Widget _buildOrderRow(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        if (value is String) Text(value, style: const TextStyle(fontWeight: FontWeight.w500)) else value,
      ],
    );
  }
}