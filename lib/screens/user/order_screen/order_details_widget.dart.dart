import 'package:campuscart/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsWidget extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
            
            // Show cancellation reason if order was cancelled
            if (order.status == OrderStatus.cancelled && order.cancellationReason != null) ...[
              const SizedBox(height: 24),
              Text(
                'Cancellation Reason',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.cancellationReason!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData? icon;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = 'Pending';
        icon = Icons.access_time;
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        text = 'Confirmed';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        text = 'Preparing';
        icon = Icons.restaurant;
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade800;
        text = 'Ready';
        icon = Icons.emoji_food_beverage;
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade800;
        text = 'On the way';
        icon = Icons.delivery_dining;
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = 'Delivered';
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = 'Cancelled';
        icon = Icons.cancel;
        break;
      case OrderStatus.readyForDelivery:
        backgroundColor = Colors.cyan.shade100;
        textColor = Colors.cyan.shade800;
        text = 'Ready for Delivery';
        icon = Icons.local_shipping;
        break;
      case OrderStatus.delerved:
        throw UnimplementedError();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
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
      case OrderStatus.delerved:
        throw UnimplementedError();
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
      case OrderStatus.delerved:
        throw UnimplementedError();
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
}