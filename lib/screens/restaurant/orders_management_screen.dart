// ignore_for_file: deprecated_member_use, unused_result

import 'package:campuscart/models/order_model.dart';
import 'package:campuscart/providers/order_provider.dart';
import 'package:campuscart/screens/restaurant/orders_management/orders_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campuscart/models/restaurant_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/restaurant_provider.dart';

class OrdersManagementScreen extends ConsumerStatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  ConsumerState<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends ConsumerState<OrdersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = ref.watch(selectedRestaurantProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        bottom: restaurant != null ? TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'New Orders'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'Completed'),
          ],
        ) : null,
      ),
      body: restaurant == null 
          ? _buildNoRestaurant(context) 
          : _buildOrdersContent(restaurant),
    );
  }

  Widget _buildOrdersContent(RestaurantModel restaurant) {
    final ordersAsync = ref.watch(restaurantOrdersProvider(restaurant.id));
    
    return ordersAsync.when(
      data: (orderList) {
        return TabBarView(
          controller: _tabController,
          children: [
            OrdersTabView(
              orders: orderList,
              statuses: const [OrderStatus.pending, OrderStatus.confirmed],
            ),
            OrdersTabView(
              orders: orderList,
              statuses: const [OrderStatus.preparing],
            ),
            OrdersTabView(
              orders: orderList,
              statuses: const [OrderStatus.ready, OrderStatus.outForDelivery],
            ),
            OrdersTabView(
              orders: orderList,
              statuses: const [OrderStatus.delivered, OrderStatus.cancelled],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Error loading orders: ${error.toString()}',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(restaurantOrdersProvider(restaurant.id)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRestaurant(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 120,
              color: Colors.grey.shade400,
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            Text(
              'No Restaurant Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 12),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Please create a restaurant first to manage orders',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to restaurant creation screen
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Create Restaurant'),
            ),
          ],
        ),
      ),
    );
  }
}