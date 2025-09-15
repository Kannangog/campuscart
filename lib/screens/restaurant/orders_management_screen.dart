// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

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
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to manage orders')),
      );
    }

    final restaurants = ref.watch(restaurantsByOwnerProvider(user.uid));
    
    return restaurants.when(
      data: (restaurantList) {
        if (restaurantList.isEmpty) {
          return _buildNoRestaurant(context);
        }
        
        final restaurant = restaurantList.first;
        final ordersAsync = ref.watch(restaurantOrdersProvider(restaurant.id));
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Orders Management'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 1,
            bottom: TabBar(
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
          ),
          body: ordersAsync.when(
            data: (orderList) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(orderList, [OrderStatus.pending, OrderStatus.confirmed]),
                  _buildOrdersList(orderList, [OrderStatus.preparing]),
                  _buildOrdersList(orderList, [OrderStatus.ready, OrderStatus.outForDelivery]),
                  _buildOrdersList(orderList, [OrderStatus.delivered, OrderStatus.cancelled]),
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
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${error.toString()}'),
          ),
        ),
      ),
    );
  }

  Widget _buildNoRestaurant(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: Center(
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
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> allOrders, List<OrderStatus> statuses) {
    final filteredOrders = allOrders.where((order) => statuses.contains(order.status)).toList();
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (filteredOrders.isEmpty) {
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
              'No orders found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New orders will appear here',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(context, order, index);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: _getStatusColor(order.status),
              size: 20,
            ),
          ),
          title: Text(
            'Order #${order.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${order.totalItems} items • ₹${order.total.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: _buildStatusChip(order.status),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info
                  Text(
                    'CUSTOMER INFORMATION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        order.userName,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        order.userPhone,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Order Items
                  Text(
                    'ORDER ITEMS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              item.quantity.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Order Summary
                  Text(
                    'ORDER SUMMARY',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _buildSummaryRow('Delivery Fee', '₹${order.deliveryFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _buildSummaryRow('Tax', '₹${order.tax.toStringAsFixed(2)}'),
                  if (order.discount > 0) ...[
                    const SizedBox(height: 4),
                    _buildSummaryRow('Discount', '-₹${order.discount.toStringAsFixed(2)}', 
                      isDiscount: true),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                      Text(
                        '₹${order.total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Delivery Address
                  Text(
                    'DELIVERY ADDRESS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                  
                  if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'SPECIAL INSTRUCTIONS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.specialInstructions!,
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Payment Info
                  Text(
                    'PAYMENT INFORMATION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.payment_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '${order.paymentMethod.toUpperCase()} • ${order.paymentStatus.toUpperCase()}',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  if (_shouldShowActions(order.status)) _buildActionButtons(context, order),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.3);
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        )),
        Text(value, style: TextStyle(
          color: isDiscount ? Colors.green : Colors.grey.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        )),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    return Chip(
      label: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getStatusColor(status),
        ),
      ),
      backgroundColor: _getStatusColor(status).withOpacity(0.1),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel order) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        
        switch (order.status) {
          case OrderStatus.pending:
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    onPressed: () => _updateOrderStatus(order.id, OrderStatus.cancelled),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: isSmallScreen 
                          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                          : null,
                    ),
                    label: Text(isSmallScreen ? 'Reject' : 'Reject Order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    onPressed: () => _updateOrderStatus(order.id, OrderStatus.confirmed),
                    style: ElevatedButton.styleFrom(
                      padding: isSmallScreen 
                          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                          : null,
                    ),
                    label: Text(isSmallScreen ? 'Accept' : 'Accept Order'),
                  ),
                ),
              ],
            );
          
          case OrderStatus.confirmed:
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.restaurant_menu_outlined, size: 18),
                onPressed: () => _updateOrderStatus(order.id, OrderStatus.preparing),
                label: const Text('Start Preparing'),
              ),
            );
          
          case OrderStatus.preparing:
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.done_all_outlined, size: 18),
                onPressed: () => _updateOrderStatus(order.id, OrderStatus.ready),
                label: const Text('Mark as Ready'),
              ),
            );
          
          case OrderStatus.ready:
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delivery_dining_outlined, size: 18),
                onPressed: () => _updateOrderStatus(order.id, OrderStatus.outForDelivery),
                label: const Text('Out for Delivery'),
              ),
            );
          
          case OrderStatus.outForDelivery:
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                onPressed: () => _updateOrderStatus(order.id, OrderStatus.delivered),
                label: const Text('Mark as Delivered'),
              ),
            );
          
          default:
            return const SizedBox();
        }
      },
    );
  }

  bool _shouldShowActions(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready ||
        status == OrderStatus.outForDelivery;
  }

void _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      // Remove .notifier and access the service directly
      await ref.read(orderManagementProvider).updateOrderStatus(orderId, newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${_getStatusText(newStatus)}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.delerved:
        return Colors.green.shade300;
      case OrderStatus.readyForDelivery:
        return Colors.blue.shade300;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant_menu;
      case OrderStatus.ready:
        return Icons.emoji_food_beverage_outlined;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.delerved:
        return Icons.check_circle_outline;
      case OrderStatus.readyForDelivery:
        return Icons.directions_bike;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.delerved:
        return 'Delivered';
      case OrderStatus.readyForDelivery:
        return 'Ready for Delivery';
    }
  }
}