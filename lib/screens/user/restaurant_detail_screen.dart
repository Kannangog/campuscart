// ignore_for_file: deprecated_member_use

import 'package:campuscart/screens/user/food_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_item_model.dart';

// Restaurant Detail Screen
class RestaurantDetailScreen extends ConsumerWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant, required String restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(menuProvider);
    final restaurantMenu = menuItems.maybeWhen(
      data: (items) => items.where((item) => item.restaurantId == restaurant.id).toList(),
      orElse: () => <MenuItemModel>[],
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                restaurant.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'restaurant-${restaurant.id}',
                    child: CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant info row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: Icons.star,
                        color: Colors.amber,
                        value: restaurant.rating.toStringAsFixed(1),
                        label: 'Rating',
                      ),
                      _buildInfoItem(
                        icon: Icons.access_time,
                        color: Colors.blue,
                        value: '${restaurant.preparationTime} min',
                        label: 'Prep Time',
                      ),
                      _buildInfoItem(
                        icon: Icons.delivery_dining,
                        color: Colors.green,
                        value: '₹${restaurant.deliveryFee}',
                        label: 'Delivery',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Today's Special
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange[100]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_offer, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Special',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '20% off on all main courses',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Menu header
                  Row(
                    children: [
                      Text(
                        'Menu',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      const SizedBox(width: 8),
                      Badge(
                        label: Text(restaurantMenu.length.toString()),
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (restaurantMenu.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = restaurantMenu[index];
                  return _buildMenuItem(context, item, ref);
                },
                childCount: restaurantMenu.length,
              ),
            )
          else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.menu_book, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No menu items available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required Color color, required String value, required String label}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItemModel item, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodDetailScreen(menuItem: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Food details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description.isNotEmpty ? item.description : 'Delicious food item',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Add to cart button
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem(item, restaurant.id, restaurant.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added to cart'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
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