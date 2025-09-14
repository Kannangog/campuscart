// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../models/menu_item_model.dart';

// Food Detail Screen
class FoodDetailScreen extends ConsumerWidget {
  final MenuItemModel menuItem;

  const FoodDetailScreen({super.key, required this.menuItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                menuItem.name,
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
                    tag: 'food-${menuItem.id}',
                    child: CachedNetworkImage(
                      imageUrl: menuItem.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
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
                  // Rating and Veg/Non-Veg badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: menuItem.isVegan ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          menuItem.isVegan ? 'VEG' : 'NON-VEG',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            menuItem.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${menuItem.reviewCount} reviews)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    menuItem.description.isNotEmpty 
                        ? menuItem.description 
                        : 'A delicious ${menuItem.name} prepared with fresh ingredients and authentic flavors.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Price and Add to Cart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${menuItem.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(cartProvider.notifier).addItem(menuItem, menuItem.restaurantId, menuItem.restaurantName);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${menuItem.name} added to cart'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.shopping_cart, size: 20),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Reviews',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showReviewDialog(context, ref);
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Review'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Reviews List
                  if (menuItem.reviews != null && menuItem.reviews!.isNotEmpty)
                    ...menuItem.reviews!.map((review) => _buildReviewCard(review as Review))
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.reviews, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No reviews yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to review this ${menuItem.name}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _showReviewDialog(context, ref);
                            },
                            child: const Text('Write a Review'),
                          ),
                        ],
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

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(review.rating.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              review.date,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Rate ${menuItem.name}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How would you rate this item?'),
                const SizedBox(height: 16),
                // Star rating widget
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => const Icon(Icons.star_border, color: Colors.amber)),
                  ),
                ),
                const SizedBox(height: 20),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Your review',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save review logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review submitted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Submit Review'),
            ),
          ],
        );
      },
    );
  }
}

// Review model (add this to your models if not already present)
class Review {
  final String userName;
  final double rating;
  final String comment;
  final String date;

  Review({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}