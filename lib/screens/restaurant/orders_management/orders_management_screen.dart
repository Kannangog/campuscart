// ignore_for_file: deprecated_member_use, unused_result

import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/providers/order_provider/order_management_service.dart';
import 'package:campuscart/providers/restaurant_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campuscart/models/restaurant_model.dart';
import 'package:campuscart/models/order_model.dart';
import 'orders_tab_view.dart';

// Create a provider for the selected restaurant
final selectedRestaurantProvider = Provider<RestaurantModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;
  
  final restaurants = ref.watch(restaurantsByOwnerProvider(user.uid));
  return restaurants.maybeWhen(
    data: (restaurantList) => restaurantList.isNotEmpty ? restaurantList.first : null,
    orElse: () => null,
  );
});

// Provider for restaurant orders
final restaurantOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  ref.watch(orderManagementProvider);
  
  return FirebaseFirestore.instance
      .collection('orders')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList());
});

// Provider for date filter selection
enum DateFilter { today, yesterday, last7Days, thisMonth, all }

final dateFilterProvider = StateProvider<DateFilter>((ref) => DateFilter.today);

// Provider to get filtered orders based on date selection
final filteredOrdersProvider = Provider<List<OrderModel>>((ref) {
  final restaurant = ref.watch(selectedRestaurantProvider);
  if (restaurant == null) return [];
  
  final ordersAsync = ref.watch(restaurantOrdersProvider(restaurant.id));
  final dateFilter = ref.watch(dateFilterProvider);
  
  return ordersAsync.maybeWhen(
    data: (orders) {
      final now = DateTime.now();
      
      switch (dateFilter) {
        case DateFilter.today:
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));
          return orders.where((order) => 
            order.createdAt.isAfter(today) && order.createdAt.isBefore(tomorrow)
          ).toList();
          
        case DateFilter.yesterday:
          final yesterday = DateTime(now.year, now.month, now.day - 1);
          final today = DateTime(now.year, now.month, now.day);
          return orders.where((order) => 
            order.createdAt.isAfter(yesterday) && order.createdAt.isBefore(today)
          ).toList();
          
        case DateFilter.last7Days:
          final weekAgo = now.subtract(const Duration(days: 7));
          return orders.where((order) => order.createdAt.isAfter(weekAgo)).toList();
          
        case DateFilter.thisMonth:
          final monthStart = DateTime(now.year, now.month, 1);
          return orders.where((order) => order.createdAt.isAfter(monthStart)).toList();
          
        case DateFilter.all:
          return orders;
      }
    },
    loading: () => [],
    error: (error, stack) {
      print('Error loading orders: $error');
      return [];
    }, 
    orElse: () { 
      return [];
    },
  );
});

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
        bottom: restaurant != null 
            ? PreferredSize(
                preferredSize: const Size.fromHeight(88.0),
                child: Column(
                  children: [
                    _buildDateFilterRow(),
                    TabBar(
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
                    ),
                  ],
                ),
              )
            : null,
      ),
      body: restaurant == null 
          ? _buildNoRestaurant(context) 
          : _buildOrdersContent(restaurant),
    );
  }

  Widget _buildDateFilterRow() {
    final currentFilter = ref.watch(dateFilterProvider);
    
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Today',
              isSelected: currentFilter == DateFilter.today,
              onSelected: () => ref.read(dateFilterProvider.notifier).state = DateFilter.today,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Yesterday',
              isSelected: currentFilter == DateFilter.yesterday,
              onSelected: () => ref.read(dateFilterProvider.notifier).state = DateFilter.yesterday,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Last 7 Days',
              isSelected: currentFilter == DateFilter.last7Days,
              onSelected: () => ref.read(dateFilterProvider.notifier).state = DateFilter.last7Days,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'This Month',
              isSelected: currentFilter == DateFilter.thisMonth,
              onSelected: () => ref.read(dateFilterProvider.notifier).state = DateFilter.thisMonth,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'All',
              isSelected: currentFilter == DateFilter.all,
              onSelected: () => ref.read(dateFilterProvider.notifier).state = DateFilter.all,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildOrdersContent(RestaurantModel restaurant) {
    final filteredOrders = ref.watch(filteredOrdersProvider);
    final ordersAsync = ref.watch(restaurantOrdersProvider(restaurant.id));
    
    return ordersAsync.when(
      data: (orders) {
        print('📦 Total orders loaded: ${orders.length}');
        print('🔍 Filtered orders: ${filteredOrders.length}');
        
        if (filteredOrders.isEmpty) {
          return _buildEmptyOrdersState();
        }
        
        return TabBarView(
          controller: _tabController,
          children: [
            OrdersTabView(
              orders: _filterOrdersByStatus(filteredOrders, [OrderStatus.pending, OrderStatus.confirmed]),
              statuses: const [OrderStatus.pending, OrderStatus.confirmed],
            ),
            OrdersTabView(
              orders: _filterOrdersByStatus(filteredOrders, [OrderStatus.preparing]),
              statuses: const [OrderStatus.preparing],
            ),
            OrdersTabView(
              orders: _filterOrdersByStatus(filteredOrders, [OrderStatus.ready, OrderStatus.outForDelivery]),
              statuses: const [OrderStatus.ready, OrderStatus.outForDelivery],
            ),
            OrdersTabView(
              orders: _filterOrdersByStatus(filteredOrders, [OrderStatus.delivered, OrderStatus.cancelled]),
              statuses: const [OrderStatus.delivered, OrderStatus.cancelled],
            ),
          ],
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error, restaurant.id),
    );
  }

  List<OrderModel> _filterOrdersByStatus(List<OrderModel> orders, List<OrderStatus> statuses) {
    return orders.where((order) => statuses.contains(order.status)).toList();
  }

  Widget _buildEmptyOrdersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here when customers place them',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.refresh(restaurantOrdersProvider(ref.read(selectedRestaurantProvider)!.id));
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(dynamic error, String restaurantId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error Loading Orders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.refresh(restaurantOrdersProvider(restaurantId));
            },
            child: const Text('Retry'),
          ),
        ],
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}