// ignore_for_file: deprecated_member_use

import 'package:campuscart/providers/order_provider/order_management_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:campuscart/models/order_model.dart';

class OrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final int index;
  final VoidCallback onStatusUpdated;

  const OrderCard({
    super.key,
    required this.order,
    required this.index,
    required this.onStatusUpdated,
  });

  @override
  ConsumerState<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<OrderCard> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
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
              color: _getStatusColor(widget.order.status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(widget.order.status),
              color: _getStatusColor(widget.order.status),
              size: 20,
            ),
          ),
          title: Text(
            'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${widget.order.totalItems} items • ₹${widget.order.total.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(widget.order.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: _buildStatusChip(widget.order.status),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show cancellation reason if order was cancelled
                  if (widget.order.status == OrderStatus.cancelled && widget.order.cancellationReason != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.cancel, size: 16, color: Colors.red.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ORDER CANCELLED',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.order.cancellationReason!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                ),
                              ),
                              if (widget.order.cancelledBy != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Cancelled by: ${widget.order.cancelledBy!}',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

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
                        widget.order.userName,
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
                        widget.order.userPhone,
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
                  ...widget.order.items.map((item) => Padding(
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
                  _buildSummaryRow('Subtotal', '₹${widget.order.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _buildSummaryRow('Delivery Fee', '₹${widget.order.deliveryFee.toStringAsFixed(2)}'),
                  if (widget.order.discount > 0) ...[
                    const SizedBox(height: 4),
                    _buildSummaryRow('Discount', '-₹${widget.order.discount.toStringAsFixed(2)}', 
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
                        '₹${widget.order.total.toStringAsFixed(2)}',
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
                          widget.order.deliveryAddress,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                  
                  if (widget.order.specialInstructions != null && widget.order.specialInstructions!.isNotEmpty) ...[
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
                        border: Border.all(color: Colors.amber.shade100),
                      ),
                      child: Text(
                        widget.order.specialInstructions!,
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
                        '${widget.order.paymentMethod.toUpperCase()} • ${widget.order.paymentStatus.toUpperCase()}',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  if (_shouldShowActions(widget.order.status)) 
                    _buildActionButtons(context, widget.order),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (widget.index * 100).ms).slideY(begin: 0.3);
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
    if (_isUpdating) {
      return const Center(child: CircularProgressIndicator());
    }
    
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
                    onPressed: () => _showRejectOrderDialog(order),
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
                    onPressed: () => _showAcceptOrderConfirmation(order),
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
                onPressed: () => _showOutForDeliveryConfirmation(order),
                label: const Text('Out for Delivery'),
              ),
            );
          
          case OrderStatus.outForDelivery:
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                onPressed: () => _showDeliveredConfirmation(order),
                label: const Text('Mark as Delivered'),
              ),
            );
          
          default:
            return const SizedBox();
        }
      },
    );
  }

  void _showAcceptOrderConfirmation(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Order'),
        content: const Text('Are you sure you want to accept this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateOrderStatus(order.id, OrderStatus.confirmed);
            },
            child: const Text('Accept Order'),
          ),
        ],
      ),
    );
  }

  void _showOutForDeliveryConfirmation(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Out for Delivery'),
        content: const Text('Mark this order as out for delivery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateOrderStatus(order.id, OrderStatus.outForDelivery);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDeliveredConfirmation(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Delivered'),
        content: const Text('Confirm that this order has been delivered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateOrderStatus(order.id, OrderStatus.delivered);
            },
            child: const Text('Confirm Delivery'),
          ),
        ],
      ),
    );
  }

  void _showRejectOrderDialog(OrderModel order) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejecting this order:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
                hintText: 'E.g., Out of stock, Restaurant closed, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              // Reject order with reason
              _updateOrderStatusWithReason(
                order.id, 
                OrderStatus.cancelled, 
                reasonController.text,
                cancelledBy: 'Restaurant'
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject Order'),
          ),
        ],
      ),
    );
  }

  bool _shouldShowActions(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready ||
        status == OrderStatus.outForDelivery;
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    setState(() {
      _isUpdating = true;
    });
    
    try {
      await ref.read(orderManagementProvider).updateOrderStatus(orderId, newStatus);
      
      // Refresh the orders list to get the updated data
      widget.onStatusUpdated();
      
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
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatusWithReason(
    String orderId, 
    OrderStatus newStatus, 
    String reason,
    {String? cancelledBy}
  ) async {
    setState(() {
      _isUpdating = true;
    });
    
    try {
      await ref.read(orderManagementProvider).updateOrderStatusWithReason(
        orderId, 
        newStatus, 
        reason,
        cancelledBy: cancelledBy
      );
      
      // Refresh the orders list to get the updated data
      widget.onStatusUpdated();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${_getStatusText(newStatus).toLowerCase()}!'),
            backgroundColor: newStatus == OrderStatus.cancelled ? Colors.orange : Colors.green,
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
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
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