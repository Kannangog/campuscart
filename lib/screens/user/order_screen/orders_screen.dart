import 'package:campuscart/models/order_model.dart';
import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/providers/order_location_provider.dart';
import 'package:campuscart/providers/order_provider/order_management_service.dart';

import 'package:campuscart/screens/user/order_screen/order_card_widget.dart.dart';
import 'package:campuscart/screens/user/order_screen/order_details_widget.dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _selectedTimeFilter = 'All';
  String? _selectedStatusFilter;
  
  final List<String> _timeFilterOptions = [
    'All',
    'Today',
    'Yesterday',
    'Last 7 days',
    'This month'
  ];
  
  final List<String> _statusFilterOptions = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Ready',
    'Out for Delivery',
    'Delivered',
    'Cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view orders')),
      );
    }

    final orders = ref.watch(userOrdersProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.lightGreen,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        // Only show filter button when there are orders
        actions: [
          orders.when(
            data: (orderList) {
              if (orderList.isEmpty) return const SizedBox.shrink();
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded, size: 28),
                    onPressed: () => _showFilterDialog(context),
                    color: Colors.white,
                  ),
                  if (_selectedTimeFilter != 'All' || _selectedStatusFilter != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // Very light green
              Color(0xFFF1F8E9), // Even lighter green
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.7],
          ),
        ),
        child: orders.when(
          data: (orderList) {
            // Sort orders by most recent first
            orderList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            // Filter orders based on selected filters
            final filteredOrders = _filterOrders(orderList.cast<OrderModel>(), _selectedTimeFilter, _selectedStatusFilter);
            
            if (filteredOrders.isEmpty) {
              // Show empty state with filter info if filters are active
              if (_selectedTimeFilter != 'All' || _selectedStatusFilter != null) {
                return _buildEmptyFilteredOrders(context);
              }
              return _buildEmptyOrders(context);
            }

            return Column(
              children: [
                // Active filters indicator
                if (_selectedTimeFilter != 'All' || _selectedStatusFilter != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen.shade50,
                      border: const Border(bottom: BorderSide(color: Colors.green, width: 1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Active filters:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_selectedTimeFilter != 'All')
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Chip(
                                      label: Text(
                                        _selectedTimeFilter,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Colors.lightGreen.shade100,
                                      deleteIcon: const Icon(Icons.close, size: 16),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedTimeFilter = 'All';
                                        });
                                      },
                                    ),
                                  ),
                                if (_selectedStatusFilter != null)
                                  Chip(
                                    label: Text(
                                      _selectedStatusFilter!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.lightGreen.shade100,
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedStatusFilter = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedTimeFilter = 'All';
                              _selectedStatusFilter = null;
                            });
                          },
                          child: const Text(
                            'Clear all',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Filter chip bar with improved design
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.lightGreen.shade50,
                  child: Column(
                    children: [
                      // Time filters
                      SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _timeFilterOptions.map((filter) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _selectedTimeFilter == filter 
                                        ? Colors.white 
                                        : Colors.green,
                                    ),
                                  ),
                                  selected: _selectedTimeFilter == filter,
                                  selectedColor: Colors.lightGreen,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: _selectedTimeFilter == filter 
                                        ? Colors.lightGreen 
                                        : Colors.green.shade200,
                                    ),
                                  ),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      _selectedTimeFilter = selected ? filter : 'All';
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status filters
                      SizedBox(
                        height: 40,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _statusFilterOptions.map((filter) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _selectedStatusFilter == filter 
                                        ? Colors.white 
                                        : Colors.green,
                                    ),
                                  ),
                                  selected: _selectedStatusFilter == filter,
                                  selectedColor: Colors.lightGreen,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: _selectedStatusFilter == filter 
                                        ? Colors.lightGreen 
                                        : Colors.green.shade200,
                                    ),
                                  ),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      _selectedStatusFilter = selected ? filter : null;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return OrderCardWidget(
                        order: order,
                        index: index,
                        onViewDetails: () => _showOrderDetails(context, order),
                        onCancelOrder: () => _showCancelOrderDialog(context, ref, order),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.lightGreen),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    error.toString(),
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(userOrdersProvider(user.uid)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, String timeFilter, String? statusFilter) {
    // First apply time filter
    List<OrderModel> filtered = _applyTimeFilter(orders, timeFilter);
    
    // Then apply status filter if selected
    if (statusFilter != null) {
      filtered = _applyStatusFilter(filtered, statusFilter);
    }
    
    return filtered;
  }

  List<OrderModel> _applyTimeFilter(List<OrderModel> orders, String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    switch (filter) {
      case 'Today':
        return orders.where((order) {
          final orderDate = DateTime(
            order.createdAt.year,
            order.createdAt.month,
            order.createdAt.day,
          );
          return orderDate == today;
        }).toList();
      case 'Yesterday':
        return orders.where((order) {
          final orderDate = DateTime(
            order.createdAt.year,
            order.createdAt.month,
            order.createdAt.day,
          );
          return orderDate == yesterday;
        }).toList();
      case 'Last 7 days':
        return orders.where((order) => order.createdAt.isAfter(weekAgo)).toList();
      case 'This month':
        return orders.where((order) => order.createdAt.isAfter(monthStart)).toList();
      default:
        return orders;
    }
  }

  List<OrderModel> _applyStatusFilter(List<OrderModel> orders, String statusFilter) {
    OrderStatus status;
    
    switch (statusFilter) {
      case 'Pending':
        status = OrderStatus.pending;
        break;
      case 'Confirmed':
        status = OrderStatus.confirmed;
        break;
      case 'Preparing':
        status = OrderStatus.preparing;
        break;
      case 'Ready':
        status = OrderStatus.ready;
        break;
      case 'Out for Delivery':
        status = OrderStatus.outForDelivery;
        break;
      case 'Delivered':
        status = OrderStatus.delivered;
        break;
      case 'Cancelled':
        status = OrderStatus.cancelled;
        break;
      default:
        return orders;
    }
    
    return orders.where((order) => order.status == status).toList();
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 120,
            color: Colors.lightGreen.shade300,
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),
          
          Text(
            'No orders yet',
            style: TextStyle(
              color: Colors.lightGreen.shade700,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'When you place orders, they\'ll appear here',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to restaurants screen
              DefaultTabController.of(context).animateTo(1);
            },
            icon: const Icon(Icons.restaurant),
            label: const Text('Start Ordering'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildEmptyFilteredOrders(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Active filters indicator (for empty filtered state)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.lightGreen.shade50,
            border: const Border(bottom: BorderSide(color: Colors.green, width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_alt, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Active filters:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedTimeFilter != 'All')
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              _selectedTimeFilter,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.lightGreen.shade100,
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedTimeFilter = 'All';
                              });
                            },
                          ),
                        ),
                      if (_selectedStatusFilter != null)
                        Chip(
                          label: Text(
                            _selectedStatusFilter!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.lightGreen.shade100,
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedStatusFilter = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTimeFilter = 'All';
                    _selectedStatusFilter = null;
                  });
                },
                child: const Text(
                  'Clear all',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        
        // Empty state content
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 100,
                  color: Colors.lightGreen.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'No orders found',
                  style: TextStyle(
                    color: Colors.lightGreen.shade700,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'No orders match your current filters',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTimeFilter = 'All';
                      _selectedStatusFilter = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OrderDetailsWidget(order: order),
    );
  }

  void _showCancelOrderDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for cancellation'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              // Cancel order logic using orderManagementProvider
              ref.read(orderManagementProvider).cancelOrder(order.id, reasonController.text);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancellation requested'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Time Period',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeFilterOptions.map((filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: _selectedTimeFilter == filter,
                    selectedColor: Colors.lightGreen,
                    checkmarkColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedTimeFilter = selected ? filter : 'All';
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusFilterOptions.map((filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: _selectedStatusFilter == filter,
                    selectedColor: Colors.lightGreen,
                    checkmarkColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedStatusFilter = selected ? filter : null;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTimeFilter = 'All';
                        _selectedStatusFilter = null;
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear All'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}