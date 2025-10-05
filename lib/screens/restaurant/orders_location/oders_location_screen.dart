// ignore_for_file: deprecated_member_use, unrelated_type_equality_checks


import 'package:campuscart/providers/order_location_provider.dart';
import 'package:campuscart/screens/restaurant/orders_location/order_location_map.dart';
import 'package:campuscart/screens/restaurant/orders_location/orders_location_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/restaurant_provider.dart';
import '../../../models/order_model.dart';

class OrdersLocation extends ConsumerStatefulWidget {
  const OrdersLocation({super.key});

  @override
  ConsumerState<OrdersLocation> createState() => _OrdersLocationState();
}

class _OrdersLocationState extends ConsumerState<OrdersLocation> {
  GoogleMapController? _mapController;
  OrderModel? _selectedOrder;
  final ScrollController _panelScrollController = ScrollController();
  double _panelSize = 0.15;

  @override
  void dispose() {
    _mapController?.dispose();
    _panelScrollController.dispose();
    super.dispose();
  }

  void _expandPanel() {
    setState(() => _panelSize = 0.7);
  }


  void _togglePanel() {
    setState(() => _panelSize = _panelSize == 0.15 ? 0.7 : 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return _buildLoginRequired(context);
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
            
            return orders.when(
              data: (orderList) {
                final deliveryOrders = orderList.where((order) => 
                  order.status == OrderStatus.preparing || 
                  order.status == OrderStatus.readyForDelivery ||
                  order.status == OrderStatus.outForDelivery
                ).toList();
                
                return Scaffold(
                  body: Stack(
                    children: [
                      OrdersLocationMap(
                        orders: deliveryOrders.cast<OrderModel>(),
                        restaurantLocation: const LatLng(37.422, -122.084),
                        onMapCreated: (controller) => _mapController = controller,
                        onOrderSelected: (order) {
                          setState(() => _selectedOrder = order);
                          _expandPanel();
                        },
                      ),
                      
                      // Draggable panel
                      _buildDraggablePanel(deliveryOrders.cast<OrderModel>(), context),
                    ],
                  ),
                );
              },
              loading: () => _buildLoading(),
              error: (error, stack) => _buildError(context, error, () => ref.refresh(restaurantOrdersProvider(restaurant.id))),
            );
          },
          loading: () => _buildLoading(),
          error: (error, stack) => _buildError(context, error, () {}),
        );
      },
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(context, error, () {}),
    );
  }

  Widget _buildDraggablePanel(List<OrderModel> orders, BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: MediaQuery.of(context).size.height * _panelSize,
        child: Material(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          elevation: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Drag handle and header
                _buildPanelHeader(orders, context),
                
                const Divider(height: 1),
                
                // Orders list with flexible space
                Expanded(
                  child: _buildOrdersContent(orders, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader(List<OrderModel> orders, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Drag handle
          GestureDetector(
            onTap: _togglePanel,
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          
          // Title and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Orders (${orders.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  _selectedOrder != null ? Icons.clear : Icons.expand,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                onPressed: () {
                  if (_selectedOrder != null) {
                    setState(() => _selectedOrder = null);
                  } else {
                    _togglePanel();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersContent(List<OrderModel> orders, BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No active deliveries',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return OrdersLocationPanel(
      orders: orders,
      selectedOrder: _selectedOrder,
      scrollController: _panelScrollController,
      onOrderSelected: (order) {
        setState(() => _selectedOrder = order);
        _expandPanel();
      },
      onOrderDeselected: () => setState(() => _selectedOrder = null),
      ref: ref,
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Please login to view orders',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRestaurant(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu_outlined,
                  size: 120,
                  color: Theme.of(context).colorScheme.outline,
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 24),
                
                Text(
                  'No Restaurant Found',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 12),
                
                Text(
                  'Please create a restaurant first to receive orders',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 24),
                
                FilledButton(
                  onPressed: () {
                    // Navigate to restaurant creation
                  },
                  child: const Text('Create Restaurant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error, VoidCallback onRetry) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading data', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ).animate().fadeIn().scale(),
        ),
      ),
    );
  }
}