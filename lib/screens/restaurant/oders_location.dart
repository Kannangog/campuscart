// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

// Define your light green color scheme
const Color lightGreenPrimary = Color(0xFF4CAF50);
const Color lightGreenLight = Color(0xFF80E27E);
const Color lightGreenDark = Color(0xFF087F23);

class OrdersLocation extends ConsumerStatefulWidget {
  const OrdersLocation({super.key});

  @override
  ConsumerState<OrdersLocation> createState() => _OrdersLocationState();
}

class _OrdersLocationState extends ConsumerState<OrdersLocation> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  OrderModel? _selectedOrder;
  LatLng? _restaurantLocation;

  @override
  void initState() {
    super.initState();
    // Set a default restaurant location (in a real app, this would come from your data)
    _restaurantLocation = const LatLng(37.422, -122.084);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view orders')),
      );
    }

    final userAsync = ref.watch(userProvider(user));
    
    return userAsync.when(
      data: (userModel) {
        if (userModel == null) return const SizedBox();
        
        final restaurants = ref.watch(restaurantsByOwnerProvider(userModel.id));
        
        return restaurants.when(
          data: (restaurantList) {
            if (restaurantList.isEmpty) {
              return _buildNoRestaurant(context);
            }
            
            final restaurant = restaurantList.first;
            final orders = ref.watch(restaurantOrdersProvider(restaurant.id));
            
            return Scaffold(
              body: orders.when(
                data: (orderList) {
                  // Filter orders to show only those that need delivery
                  final deliveryOrders = orderList.where((order) => 
                    order.status == OrderStatus.preparing || 
                    order.status == OrderStatus.readyForDelivery ||
                    order.status == OrderStatus.outForDelivery
                  ).toList();
                  
                  if (deliveryOrders.isEmpty) {
                    return _buildEmptyOrders(context);
                  }
                  
                  // Update markers when orders data is available
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateMarkers(deliveryOrders);
                  });
                  
                  return Column(
                    children: [
                      // Map section - show all delivery locations
                      Expanded(
                        flex: 3,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _restaurantLocation ?? const LatLng(0, 0),
                            zoom: 12,
                          ),
                          markers: _markers,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          onTap: (LatLng position) {
                            // Clear selection when tapping on the map
                            setState(() {
                              _selectedOrder = null;
                            });
                          },
                        ),
                      ),
                      
                      // Selected order details or list of orders
                      Expanded(
                        flex: 2,
                        child: _selectedOrder != null 
                          ? _buildOrderDetails(context, ref, _selectedOrder!)
                          : _buildOrdersList(context, ref, deliveryOrders),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading orders: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(restaurantOrdersProvider(restaurant.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightGreenPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(child: Text('Error: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  void _updateMarkers(List<OrderModel> orders) {
    if (_mapController == null) return;
    
    // Clear existing markers
    _markers.clear();
    
    // Add restaurant marker
    if (_restaurantLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: _restaurantLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Your Restaurant',
            snippet: 'Order pickup location',
          ),
        ),
      );
    }
    
    // Add markers for each order
    for (var order in orders) {
      // Use the actual coordinates from the order
      final double lat = order.deliveryLatitude;
      final double lng = order.deliveryLongitude;
      
      final marker = Marker(
        markerId: MarkerId(order.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: 'Order #${order.id.substring(0, 8)}',
          snippet: '${order.userName} - ${_getStatusText(order.status)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          order.status == OrderStatus.outForDelivery 
            ? BitmapDescriptor.hueBlue 
            : BitmapDescriptor.hueOrange,
        ),
        onTap: () {
          setState(() {
            _selectedOrder = order;
          });
          
          // Move camera to the selected marker
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat, lng)),
          );
        },
      );
      
      _markers.add(marker);
    }
    
    setState(() {});
  }

  Widget _buildOrdersList(BuildContext context, WidgetRef ref, List<OrderModel> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, ref, order, index);
      },
    );
  }

  Widget _buildOrderDetails(BuildContext context, WidgetRef ref, OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedOrder = null;
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(order.status),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Customer Info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: lightGreenLight,
                child: Icon(
                  Icons.person,
                  color: lightGreenDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.userPhone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Delivery Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryAddress,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (order.specialInstructions?.isNotEmpty ?? false)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Special Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.specialInstructions ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Order Items
          const Text(
            'Order Items',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.name}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 12),
          
          // Order Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: lightGreenPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Order Actions
          if (order.status == OrderStatus.preparing || order.status == OrderStatus.ready)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: lightGreenPrimary,
                      side: BorderSide(color: lightGreenPrimary),
                    ),
                    onPressed: () {
                      final orderManagementService = ref.read(orderManagementProvider);
                      if (order.status == OrderStatus.preparing) {
                        orderManagementService.updateOrderStatus(order.id, OrderStatus.ready);
                      } else {
                        orderManagementService.updateOrderStatus(order.id, OrderStatus.outForDelivery);
                      }
                    },
                    child: Text(
                      order.status == OrderStatus.preparing ? 'Mark as Ready' : 'Start Delivery',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (order.status == OrderStatus.ready)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _openMapsForNavigation(order.deliveryAddress);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightGreenPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.navigation, size: 18),
                          SizedBox(width: 4),
                          Text('Navigate'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          
          if (order.status == OrderStatus.outForDelivery)
            ElevatedButton(
              onPressed: () {
                final orderManagementService = ref.read(orderManagementProvider);
                orderManagementService.updateOrderStatus(order.id, OrderStatus.delivered);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lightGreenPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Mark as Delivered'),
            ),
        ],
      ),
    );
  }

  Widget _buildNoRestaurant(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 120,
              color: Colors.grey.shade400,
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            Text(
              'No Restaurant Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 12),
            
            Text(
              'Please create a restaurant first to receive orders',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delivery_dining,
            size: 120,
            color: Colors.grey.shade400,
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),
          
          Text(
            'No Delivery Orders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          
          const SizedBox(height: 12),
          
          Text(
            'When customers place orders, they will appear here for delivery',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, OrderModel order, int index) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Customer Info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: lightGreenLight,
                    child: Icon(
                      Icons.person,
                      color: lightGreenDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.userPhone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedOrder = order;
                      });
                    },
                    icon: Icon(Icons.visibility, color: lightGreenPrimary),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Order Items Preview
              const Text(
                'Order Items',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.name}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${order.items.length - 2} more items',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Order Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lightGreenPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.3);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return lightGreenPrimary;
      case OrderStatus.outForDelivery:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.assignment_turned_in;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      default:
        return Icons.question_mark;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Delivery';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }

  void _openMapsForNavigation(String address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening navigation to: $address'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // In a real app, you would use:
    // final url = 'https://www.google.com/maps/dir/?api=1&destination=$address';
    // launchUrl(Uri.parse(url));
  }
}