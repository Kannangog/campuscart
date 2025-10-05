// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:campuscart/models/order_model.dart';
import 'package:campuscart/providers/order_provider/order_management_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

// Define Material 3 color scheme
const Color lightGreenPrimary = Color(0xFF4CAF50);
const Color lightGreenPrimaryContainer = Color(0xFFA5D6A7);
const Color lightGreenOnPrimaryContainer = Color(0xFF00210B);
const Color lightGreenSurface = Color(0xFFF7FBF7);
const Color lightGreenSurfaceVariant = Color(0xFFDEE5D9);

class OrdersLocationPanel extends StatefulWidget {
  final List<OrderModel> orders;
  final OrderModel? selectedOrder;
  final ScrollController? scrollController;
  final Function(OrderModel) onOrderSelected;
  final Function() onOrderDeselected;
  final WidgetRef ref;

  const OrdersLocationPanel({
    super.key,
    required this.orders,
    required this.selectedOrder,
    this.scrollController,
    required this.onOrderSelected,
    required this.onOrderDeselected,
    required this.ref,
  });

  @override
  State<OrdersLocationPanel> createState() => _OrdersLocationPanelState();
}

class _OrdersLocationPanelState extends State<OrdersLocationPanel> {
  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) {
      return _buildEmptyOrders(context);
    }

    return widget.selectedOrder != null 
      ? _buildOrderDetails(context, widget.selectedOrder!)
      : _buildOrdersList(context, widget.orders);
  }

  Widget _buildOrdersList(BuildContext context, List<OrderModel> orders) {
    return Column(
      children: [
        // Header with order count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Active Orders (${orders.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(BuildContext context, OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    
    return Column(
      children: [
        // Header with order ID and close button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: widget.onOrderDeselected,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status chip
                Row(
                  children: [
                    Icon(_getStatusIcon(order.status), size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_getStatusText(order.status)),
                      backgroundColor: statusColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Customer Info
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: lightGreenPrimaryContainer,
                          child: Icon(
                            Icons.person,
                            color: lightGreenOnPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.userName.isNotEmpty ? order.userName : 'Unknown Customer',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.userPhone.isNotEmpty ? order.userPhone : 'No phone number',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Delivery Location
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Address',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.deliveryAddress.isNotEmpty 
                                      ? order.deliveryAddress 
                                      : 'Address not specified',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (order.specialInstructions?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.note,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Special Instructions',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.specialInstructions!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Order Items
                Text(
                  'Order Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                if (order.items.isEmpty) 
                  Text(
                    'No items in this order',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.name}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
                
                const SizedBox(height: 16),
                
                // Order Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${order.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: lightGreenPrimary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Order Actions
                if (order.userPhone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FilledButton.tonal(
                      onPressed: () => _callCustomer(order.userPhone),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 18),
                          SizedBox(width: 8),
                          Text('Call Customer'),
                        ],
                      ),
                    ),
                  ),
                
                if (order.status == OrderStatus.preparing || order.status == OrderStatus.ready)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => _confirmMarkAsReady(context, order),
                          child: Text(
                            order.status == OrderStatus.preparing 
                              ? 'Mark as Ready' 
                              : 'Start Delivery',
                          ),
                        ),
                      ),
                    ],
                  ),
                
                if (order.status == OrderStatus.outForDelivery)
                  FilledButton(
                    onPressed: () => _confirmDelivery(context, order),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: lightGreenPrimary,
                    ),
                    child: const Text('Mark as Delivered'),
                  ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.outline,
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            Text(
              'No Delivery Orders',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 12),
            
            Text(
              'When customers place orders, they will appear here for delivery',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, int index) {
    final statusColor = _getStatusColor(order.status);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onOrderSelected(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(_getStatusText(order.status)),
                    backgroundColor: statusColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide.none,
                    avatar: Icon(_getStatusIcon(order.status), size: 16, color: statusColor),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Customer Info
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: lightGreenPrimaryContainer,
                    radius: 20,
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: lightGreenOnPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.userName.isNotEmpty ? order.userName : 'Unknown Customer',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.userPhone.isNotEmpty ? order.userPhone : 'No phone number',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Order Items Preview
              Text(
                'Order Items',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              if (order.items.isEmpty)
                Text(
                  'No items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...order.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Special Instructions Preview (if available)
              if (order.specialInstructions?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Special Instructions',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.specialInstructions!.length > 50
                          ? '${order.specialInstructions!.substring(0, 50)}...'
                          : order.specialInstructions!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              
              // Order Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  void _confirmDelivery(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to mark order #${order.id.substring(0, 8)} as delivered?'),
              if (order.specialInstructions?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text(
                  'Special Instructions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.specialInstructions!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final orderManagementService = widget.ref.read(orderManagementProvider);
                orderManagementService.updateOrderStatus(order.id, OrderStatus.delivered);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order #${order.id.substring(0, 8)} marked as delivered'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Confirm Delivery'),
            ),
          ],
        );
      },
    );
  }

  void _confirmMarkAsReady(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(order.status == OrderStatus.preparing 
            ? 'Mark as Ready?' 
            : 'Start Delivery?'),
          content: Text(order.status == OrderStatus.preparing 
            ? 'Are you sure you want to mark order #${order.id.substring(0, 8)} as ready for delivery?'
            : 'Are you sure you want to start delivery for order #${order.id.substring(0, 8)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final orderManagementService = widget.ref.read(orderManagementProvider);
                if (order.status == OrderStatus.preparing) {
                  orderManagementService.updateOrderStatus(order.id, OrderStatus.ready);
                } else {
                  orderManagementService.updateOrderStatus(order.id, OrderStatus.outForDelivery);
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(order.status == OrderStatus.preparing
                      ? 'Order #${order.id.substring(0, 8)} marked as ready'
                      : 'Delivery started for order #${order.id.substring(0, 8)}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(order.status == OrderStatus.preparing 
                ? 'Mark as Ready' 
                : 'Start Delivery'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callCustomer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone app'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making call: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}