import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: const Text('My Orders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: orders.when(
        data: (orderList) {
          if (orderList.isEmpty) {
            return _buildEmptyOrders(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              final order = orderList[index];
              return _buildOrderCard(context, order, index, ref);
            },
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
                onPressed: () => ref.refresh(userOrdersProvider(user.uid)),
                child: const Text('Retry'),
              ),
            ],
          ),
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
            Icons.receipt_long_outlined,
            size: 120,
            color: Colors.grey.shade400,
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),
          
          Text(
            'No orders yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          
          const SizedBox(height: 12),
          
          Text(
            'When you place orders, they\'ll appear here',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildOrderCard(BuildContext context, OrderModel order, int index, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            _showOrderDetails(context, order);
          },
          borderRadius: BorderRadius.circular(12),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.restaurantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Order Items Summary
                Text(
                  '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // First few items
                ...order.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '${item.quantity}x ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
                
                if (order.items.length > 2)
                  Text(
                    '... and ${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Order Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${order.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (order.status == OrderStatus.pending)
                          TextButton(
                            onPressed: () {
                              _showCancelOrderDialog(context, ref, order);
                            },
                            child: const Text('Cancel'),
                          ),
                        TextButton(
                          onPressed: () {
                            _showOrderDetails(context, order);
                          },
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.3);
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        text = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        text = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade700;
        text = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade700;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        text = 'Cancelled';
        break;
      case OrderStatus.readyForDelivery:
        backgroundColor = Colors.cyan.shade100;
        textColor = Colors.cyan.shade700;
        text = 'Ready for Delivery';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        text = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.restaurantName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Order Timeline
              Text(
                'Order Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              _buildOrderTimeline(order),
              
              const SizedBox(height: 24),
              
              // Order Items
              Text(
                'Items Ordered',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              ...order.items.map((item) => Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fastfood, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${item.quantity}x ₹${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
              
              const Divider(height: 32),
              
              // Order Summary
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              _buildSummaryRow('Subtotal', '₹${order.subtotal.toStringAsFixed(2)}'),
              _buildSummaryRow('Delivery Fee', '₹${order.deliveryFee.toStringAsFixed(2)}'),
              _buildSummaryRow('Tax', '₹${order.tax.toStringAsFixed(2)}'),
              
              const Divider(height: 24),
              
              _buildSummaryRow(
                'Total',
                '₹${order.total.toStringAsFixed(2)}',
                isTotal: true,
              ),
              
              const SizedBox(height: 24),
              
              // Delivery Info
              Text(
                'Delivery Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              
              if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.specialInstructions!,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Order Timeline
              Text(
                'Order Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ordered on ${DateFormat('MMM dd, yyyy at hh:mm a').format(order.createdAt)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              
              if (order.estimatedDeliveryTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Estimated delivery: ${DateFormat('hh:mm a').format(order.estimatedDeliveryTime!)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTimeline(OrderModel order) {
    final statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.readyForDelivery,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    
    final currentStatusIndex = statuses.indexOf(order.status);
    
    return Column(
      children: [
        for (int i = 0; i < statuses.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= currentStatusIndex 
                          ? _getStatusColor(statuses[i]) 
                          : Colors.grey.shade300,
                    ),
                    child: i <= currentStatusIndex
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  if (i < statuses.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: i < currentStatusIndex 
                          ? _getStatusColor(statuses[i])
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Status text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Text(
                    _getStatusText(statuses[i]),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: i <= currentStatusIndex 
                          ? Colors.black 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
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
      case OrderStatus.readyForDelivery:
        return Colors.cyan;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order placed';
      case OrderStatus.confirmed:
        return 'Order confirmed';
      case OrderStatus.preparing:
        return 'Preparing your order';
      case OrderStatus.ready:
        return 'Order is ready';
      case OrderStatus.readyForDelivery:
        return 'Ready for delivery';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown status';
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              // Cancel order logic using orderManagementProvider
              ref.read(orderManagementProvider).cancelOrder(order.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancelled successfully'),
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
}