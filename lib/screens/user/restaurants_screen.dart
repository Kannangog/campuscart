// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/restaurant_provider.dart';
import 'restaurant_detail_screen.dart';

class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Light green color scheme
  final Color _primaryColor = const Color(0xFF4CAF50); // Light green
  final Color _secondaryColor = const Color(0xFFE8F5E9); // Very light green
  final Color _accentColor = const Color(0xFF388E3C); // Darker green for accents

  final List<String> _categories = [
    'All',
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'American',
    'Thai',
    'Japanese',
    'Fast Food',
    'Desserts',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(restaurantsProvider);

    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        title: const Text(
          'Restaurants',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear, color: Colors.grey),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _secondaryColor.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ).animate().fadeIn().slideY(begin: -0.3),

          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: _primaryColor,
                    side: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

          const SizedBox(height: 8),

          // Restaurant List
          Expanded(
            child: restaurants.when(
              data: (restaurantList) {
                // Filter restaurants based on search and category
                final filteredRestaurants = restaurantList.where((restaurant) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      restaurant.name.toLowerCase().contains(_searchQuery) ||
                      restaurant.description.toLowerCase().contains(_searchQuery);
                  
                  final matchesCategory = _selectedCategory == 'All' ||
                      restaurant.categories.contains(_selectedCategory);
                  
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredRestaurants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 80,
                          color: _primaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No restaurants found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                              _searchController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = filteredRestaurants[index];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailScreen(
                                  restaurant: restaurant,
                                  restaurantId: restaurant.id,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Restaurant Image
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: restaurant.imageUrl,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: _secondaryColor,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation(_primaryColor),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: _secondaryColor,
                                        child: Icon(
                                          Icons.restaurant,
                                          size: 64,
                                          color: _primaryColor.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: restaurant.isOpen
                                              ? _primaryColor
                                              : Colors.red,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          restaurant.isOpen ? 'OPEN' : 'CLOSED',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (restaurant.isFeatured)
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'FEATURED',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Restaurant Info
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            restaurant.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: _accentColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 18,
                                              color: Colors.amber.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              restaurant.rating.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _accentColor,
                                              ),
                                            ),
                                            Text(
                                              ' (${restaurant.reviewCount})',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      restaurant.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Categories
                                    if (restaurant.categories.isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: restaurant.categories.take(3).map((category) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _secondaryColor,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _primaryColor.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                color: _primaryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Delivery Info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildInfoItem(
                                          icon: Icons.access_time,
                                          value: '${restaurant.estimatedDeliveryTime} min',
                                        ),
                                        _buildInfoItem(
                                          icon: Icons.delivery_dining,
                                          value: '₹${restaurant.deliveryFee.toStringAsFixed(2)}',
                                        ),
                                        _buildInfoItem(
                                          icon: Icons.shopping_bag,
                                          value: 'Min ₹${restaurant.minimumOrder.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (300 + index * 100).ms).slideY(begin: 0.3);
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: _secondaryColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 20,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: _secondaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  height: 16,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: _secondaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 16,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: _secondaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                      height: 16,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: _secondaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    Container(
                                      height: 16,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: _secondaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    Container(
                                      height: 16,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: _secondaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: _primaryColor),
                    const SizedBox(height: 20),
                    Text(
                      'Error loading restaurants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => ref.refresh(restaurantsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _primaryColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}