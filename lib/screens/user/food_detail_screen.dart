// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_item_rating_provider.dart';
import '../../providers/auth_provider.dart'; // Add your auth provider
import '../../models/menu_item_model.dart';
import '../../models/menu_item_rating_model.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final MenuItemModel menuItem;

  const FoodDetailScreen({
    super.key, 
    required this.menuItem,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  // Helper method to get current user ID
  String? _getCurrentUserId() {
    final authState = ref.read(authProvider);
    return authState.value?.id;
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID
    final userId = _getCurrentUserId();
    
    // Access the provider notifier to call methods
    final menuRatingNotifier = ref.read(menuItemRatingProvider.notifier);
    ref.watch(menuItemRatingProvider);
    
    // Calculate values using the notifier with specific user ID
    final reviews = menuRatingNotifier.getMenuItemRatings(widget.menuItem.id);
    final averageRating = menuRatingNotifier.getAverageRating(widget.menuItem.id);
    final reviewCount = menuRatingNotifier.getRatingCount(widget.menuItem.id);
    final userRating = userId != null ? menuRatingNotifier.getUserRating(widget.menuItem.id, userId) : null;

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
                widget.menuItem.name,
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
                    tag: 'food-${widget.menuItem.id}',
                    child: CachedNetworkImage(
                      imageUrl: widget.menuItem.imageUrl,
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
                  // User Rating Section (if exists and user is logged in)
                  if (userId != null && userRating != null) 
                    _buildUserRatingSection(userRating),
                  
                  // Rating and Veg/Non-Veg badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.menuItem.isVegan ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.menuItem.isVegan ? 'VEG' : 'NON-VEG',
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
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
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
                    widget.menuItem.description.isNotEmpty 
                        ? widget.menuItem.description 
                        : 'A delicious ${widget.menuItem.name} prepared with fresh ingredients and authentic flavors.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity Selector
                  _buildQuantitySelector(),
                  const SizedBox(height: 24),

                  // Add to Cart Button
                  _buildAddToCartButton(),
                  const SizedBox(height: 32),

                  // Reviews Section
                  _buildReviewsSection(reviews, userId),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRatingSection(MenuItemRating userRating) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rating',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      userRating.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    if (userRating.review != null && userRating.review!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"${userRating.review!}"',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue[700], size: 20),
            onPressed: () => _showReviewDialog(context, ref, userRating),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantity',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Decrement Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: _decrementQuantity,
                  color: _quantity > 1 ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              // Quantity Display
              Text(
                '$_quantity',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              // Increment Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _incrementQuantity,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              // Total Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '₹${(widget.menuItem.price * _quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          for (int i = 0; i < _quantity; i++) {
            ref.read(cartProvider.notifier).addItem(
              widget.menuItem, 
              widget.menuItem.restaurantId, 
              widget.menuItem.restaurantName
            );
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_quantity ${widget.menuItem.name} added to cart'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to cart screen
                },
              ),
            ),
          );
          Navigator.pop(context);
        },
        icon: const Icon(Icons.shopping_cart, size: 20),
        label: Text(
          'Add $_quantity to Cart - ₹${(widget.menuItem.price * _quantity).toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildReviewsSection(List<MenuItemRating> reviews, String? userId) {
    final userRating = userId != null 
        ? ref.read(menuItemRatingProvider.notifier).getUserRating(widget.menuItem.id, userId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            // Only show Add Review button if user is logged in and hasn't rated yet
            if (userId != null && userRating == null)
              TextButton.icon(
                onPressed: () => _showReviewDialog(context, ref, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Review'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (reviews.isNotEmpty)
          ...reviews.map((review) => _buildReviewCard(review, userId)).toList()
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
                  'Be the first to review this ${widget.menuItem.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                // Only show Write a Review button if user is logged in and hasn't rated yet
                if (userId != null && userRating == null)
                  ElevatedButton(
                    onPressed: () => _showReviewDialog(context, ref, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Write a Review'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(MenuItemRating review, String? currentUserId) {
    final isCurrentUserReview = currentUserId != null && review.userName == currentUserId;

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
                CircleAvatar(
                  backgroundColor: isCurrentUserReview ? Colors.blue[100] : Colors.grey[300],
                  radius: 16,
                  child: Icon(
                    Icons.person, 
                    size: 16, 
                    color: isCurrentUserReview ? Colors.blue : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentUserReview ? 'You' : 'Customer',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(review.timestamp),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(review.rating.toStringAsFixed(1)),
                  ],
                ),
                // Only show edit button for current user's review
                if (isCurrentUserReview) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue[700], size: 16),
                    onPressed: () => _showReviewDialog(context, ref, review),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (review.review != null && review.review!.isNotEmpty)
              Text(
                review.review!,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref, MenuItemRating? existingRating) {
    double selectedRating = existingRating?.rating ?? 0.0;
    TextEditingController reviewController = TextEditingController(text: existingRating?.review ?? '');
    
    // Get current user ID
    final userId = _getCurrentUserId();

    // If user is not logged in, show message and return
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to rate items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingRating != null ? 'Update Your Rating' : 'Rate Food Item',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.menuItem.name,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'How would you rate this item?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  
                  // Star Rating - Fixed layout
                  Container(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: IconButton(
                            icon: Icon(
                              index < selectedRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedRating = (index + 1).toDouble();
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      selectedRating == 0 ? 'Tap to rate' : '${selectedRating.toStringAsFixed(1)} Stars',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Review Field Only
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      labelText: 'Your review (optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: selectedRating > 0
                            ? () {
                                final rating = MenuItemRating(
                                  menuItemId: widget.menuItem.id,
                                  restaurantId: widget.menuItem.restaurantId,
                                  userName: userId, // Use actual user ID
                                  rating: selectedRating,
                                  review: reviewController.text.trim().isEmpty ? null : reviewController.text.trim(),
                                  timestamp: DateTime.now(),
                                );
                                
                                ref.read(menuItemRatingProvider.notifier).addRating(rating);
                                Navigator.pop(context);
                                
                                // Force UI update
                                if (mounted) {
                                  setState(() {});
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(existingRating != null 
                                        ? 'Rating updated successfully!' 
                                        : 'Review submitted successfully!'
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(existingRating != null ? 'Update' : 'Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

extension on User? {
  String? get id => null;
}