import 'package:campuscart/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class OrderCardWidget extends StatelessWidget {
  final OrderModel order;
  final int index;
  final VoidCallback onViewDetails;
  final VoidCallback onCancelOrder;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.index,
    required this.onViewDetails,
    required this.onCancelOrder,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel = order.status.index < OrderStatus.preparing.index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(16),
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
                              fontSize: 18,
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
                
                const SizedBox(height: 16),
                
                // Divider
                Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                
                const SizedBox(height: 16),
                
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.quantity}x ',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
                
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
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
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                        if (canCancel)
                          OutlinedButton(
                            onPressed: onCancelOrder,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: onViewDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Details'),
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
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData? icon;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        text = 'Pending';
        icon = Icons.access_time;
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        text = 'Confirmed';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade800;
        text = 'Preparing';
        icon = Icons.restaurant;
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.teal.shade50;
        textColor = Colors.teal.shade800;
        text = 'Ready';
        icon = Icons.emoji_food_beverage;
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade800;
        text = 'On the way';
        icon = Icons.delivery_dining;
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        text = 'Delivered';
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        text = 'Cancelled';
        icon = Icons.cancel;
        break;
      case OrderStatus.readyForDelivery:
        backgroundColor = Colors.cyan.shade50;
        textColor = Colors.cyan.shade800;
        text = 'Ready for Delivery';
        icon = Icons.local_shipping;
        break;
      case OrderStatus.delerved:
        throw UnimplementedError();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}