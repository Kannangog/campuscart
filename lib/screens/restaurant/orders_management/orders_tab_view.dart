// ignore_for_file: unused_result


import 'package:campuscart/providers/order_location_provider.dart';
import 'package:campuscart/screens/restaurant/orders_management/orders_management_screen.dart' hide restaurantOrdersProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscart/models/order_model.dart';
import 'order_card.dart';

class OrdersTabView extends ConsumerWidget {
  final List<OrderModel> orders;
  final List<OrderStatus> statuses;
  
  const OrdersTabView({
    super.key,
    required this.orders,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredOrders = orders
        .where((order) => statuses.contains(order.status))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
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
        return OrderCard(
          order: order,
          index: index,
          onStatusUpdated: () {
            // Refresh the orders list when status changes
            final restaurant = ref.read(selectedRestaurantProvider);
            if (restaurant != null) {
              ref.refresh(restaurantOrdersProvider(restaurant.id));
            }
          },
        );
      },
    );
  }
}