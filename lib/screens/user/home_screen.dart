// ignore_for_file: deprecated_member_use, unused_result

import 'package:campuscart/screens/user/Favorites_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_item_model.dart';
import 'restaurant_detail_screen.dart';
import 'food_detail_screen.dart';
import 'cart_screen.dart'; // Add this import

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _promoCards = [
    {
      'title': '50% OFF',
      'subtitle': 'On your first order',
      'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      ),
      'route': '/specials',
    },
    {
      'title': 'Free Delivery',
      'subtitle': 'On orders above ₹299',
      'image': 'https://images.unsplash.com/photo-1565958011703-44f9829ba187',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.fromARGB(255, 50, 167, 54), Color(0xFF2E7D32)],
      ),
      'route': '/free-delivery',
    },
    {
      'title': 'Combo Offers',
      'subtitle': 'Special meal deals for you',
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
      ),
      'route': '/combo-offers',
    },
  ];

  // Updated categories to match menu management screen exactly
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.all_inclusive, 'label': 'All', 'category': 'All'},
    {'icon': Icons.eco, 'label': 'Veg', 'category': 'Veg'},
    {'icon': Icons.set_meal, 'label': 'Non Veg', 'category': 'Non Veg'},
    {'icon': Icons.rice_bowl, 'label': 'Briyani', 'category': 'Briyani'},
    {'icon': Icons.soup_kitchen, 'label': 'Curries', 'category': 'Curries'},
    {'icon': Icons.bakery_dining, 'label': 'Rotis', 'category': 'Rotis'},
    {'icon': Icons.lunch_dining, 'label': 'Meal', 'category': 'Meal'},
    {'icon': Icons.local_pizza, 'label': 'Pizza', 'category': 'Pizza'},
    {'icon': Icons.fastfood, 'label': 'Burger', 'category': 'Burger'},
    {'icon': Icons.breakfast_dining, 'label': 'Breakfast', 'category': 'Breakfast'},
    {'icon': Icons.cake, 'label': 'Desserts', 'category': 'Desserts'},
  ];

  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchResults = false;
  List<MenuItemModel> _searchResults = [];
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Add listener to search controller
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        setState(() {
          _showSearchResults = false;
          _searchResults.clear();
        });
      } else {
        _performSearch(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _showSearchResults = false;
        _searchResults.clear();
      });
      return;
    }

    try {
      final allMenuItems = await ref.read(menuProvider.future);
      final filteredItems = allMenuItems.where((item) {
        return item.name.toLowerCase().contains(query.toLowerCase()) ||
            item.description.toLowerCase().contains(query.toLowerCase()) ||
            item.category.toLowerCase().contains(query.toLowerCase());
      }).toList();

      setState(() {
        _searchResults = filteredItems;
        _showSearchResults = true;
      });
    } catch (e) {
      setState(() {
        _showSearchResults = false;
        _searchResults.clear();
      });
    }
  }

  void _addToCart(MenuItemModel item, int quantity, BuildContext context) {
    ref.read(cartProvider.notifier).addItem(item, quantity.toString(), context.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _toggleFavorite(MenuItemModel item, BuildContext context) {
    ref.read(favoriteProvider.notifier).toggleFavorite(item);
    final isFavorite = ref.read(favoriteProvider.notifier).isFavorite(item.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 2),
        backgroundColor: isFavorite ? Colors.green : Colors.grey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: const Text('This feature is coming soon! Stay tuned for exciting offers.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(restaurantsProvider);
    final topSellingItems = ref.watch(topSellingItemsProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final cart = ref.watch(cartProvider);
    final favorites = ref.watch(favoriteProvider);

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(restaurantsProvider);
          ref.refresh(topSellingItemsProvider);
          ref.refresh(menuProvider);
          ref.refresh(favoriteProvider);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: Colors.green[50],
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedOpacity(
                  opacity: _showSearchResults ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: const Text(
                    'ZoneFeast',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      fontFamily: 'Lobster',
                    ),
                  ),
                ),
                centerTitle: true,
                background: Container(
                  color: Colors.green[50],
                ),
              ),
              actions: [
                // Favorites Icon
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoritesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite, 
                          color: Colors.red, size: 24),
                    ),
                    if (favorites.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            favorites.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Cart Icon - Fixed navigation
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart, 
                          color: Colors.black87, size: 24),
                    ),
                    if (cart.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            cart.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    // Scroll to search bar
                    _scrollController.animateTo(
                      200,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.search, color: Colors.black87, size: 24),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Search Results Section (if applicable)
            if (_showSearchResults) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Search Results',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _showSearchResults = false;
                            _searchResults.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (_searchResults.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Try different keywords',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _searchResults[index];
                      return _buildSearchResultItem(context, item, index);
                    },
                    childCount: _searchResults.length,
                  ),
                ),
            ],

            // If showing search results, skip the rest of the content
            if (_showSearchResults) const SliverToBoxAdapter(child: SizedBox()),

            // Welcome Section
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_getGreeting()}${user?.displayName != null ? ' ${user?.displayName}' : ''}!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'What would you like to eat today?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Promo Carousel Section
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    CarouselSlider(
                      items: _promoCards.map((card) {
                        return GestureDetector(
                          onTap: () {
                            _showComingSoonDialog(context, card['title']);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: card['gradient'],
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedNetworkImage(
                                    imageUrl: card['image'],
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    color: Colors.black.withOpacity(0.2),
                                    colorBlendMode: BlendMode.darken,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        card['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        card['subtitle'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Order Now',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      options: CarouselOptions(
                        height: 160,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        viewportFraction: 0.8,
                        autoPlayInterval: const Duration(seconds: 5),
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentCarouselIndex = index;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _promoCards.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarouselIndex == entry.key
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for food or restaurants...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Categories Section
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Fixed: Navigate to categories screen
                          Navigator.pushNamed(context, '/categories');
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Categories List
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryItem(
                        context, 
                        category['icon'], 
                        category['label'], 
                        category['category'],
                        index
                      );
                    },
                  ),
                ),
              ),
            ),

            // POPULAR ITEMS SECTION - MOVED BEFORE RESTAURANTS
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Items',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Fixed: Navigate to popular items screen
                          Navigator.pushNamed(context, '/popular-items');
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Selling Items - MOVED BEFORE RESTAURANTS
            topSellingItems.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.fastfood, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No popular items yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Orders will appear here',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildFoodItemCard(context, item, index);
                      },
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading popular items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(topSellingItemsProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Popular Restaurants Header - MOVED AFTER POPULAR ITEMS
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Restaurants',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Fixed: Navigate to restaurants screen
                          Navigator.pushNamed(context, '/restaurants');
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Popular Restaurants Horizontal List (Netflix-style)
            restaurants.when(
              data: (restaurants) {
                if (restaurants.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.restaurant, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No restaurants available',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Check back later for new restaurants',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = restaurants[index];
                        return _buildRestaurantCardHorizontal(context, restaurant, index);
                      },
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading restaurants',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Please try again later',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(restaurantsProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for building category items
  Widget _buildCategoryItem(BuildContext context, IconData icon, String label, String category, int index) {
    final color = _getCategoryColor(index);
    final isSelected = _selectedCategory == category;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        // Navigate to category screen with filtered items
        Navigator.pushNamed(
          context, 
          '/category', 
          arguments: {'category': category, 'title': label}
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: color, width: 2) 
                    : null,
              ),
              child: Icon(
                icon, 
                color: isSelected ? Colors.white : color, 
                size: 28
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for building restaurant card (Horizontal Netflix-style)
  Widget _buildRestaurantCardHorizontal(BuildContext context, RestaurantModel restaurant, int index) {
    final isOpen = _isRestaurantOpen(restaurant.openingTime as String?, restaurant.closingTime as String?);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(restaurant: restaurant, restaurantId: restaurant.id),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            Stack(
              children: [
                Hero(
                  tag: 'restaurant-${restaurant.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 40),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 40),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOpen ? 'OPEN' : 'CLOSED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.preparationTime} min',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${restaurant.minOrderAmount} min',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
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
  }

  // Helper method for building food item card
  Widget _buildFoodItemCard(BuildContext context, MenuItemModel item, int index) {
    final isFavorite = ref.read(favoriteProvider.notifier).isFavorite(item.id);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodDetailScreen(menuItem: item),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            Hero(
              tag: 'food-${item.id}',
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 30),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 30),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(item, context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite ? Colors.red : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.isVegan ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isVegan ? 'VEG' : 'NON-VEG',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: item.isVegan ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 15,
                        ),
                      ),
                      InkWell(
                        onTap: () => _addToCart(item, 1, context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
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
  }

  // Helper method for building search result items
  Widget _buildSearchResultItem(BuildContext context, MenuItemModel item, int index) {
    final isFavorite = ref.read(favoriteProvider.notifier).isFavorite(item.id);
    
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: item.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade100,
            child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 24),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.shade100,
            child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 24),
          ),
        ),
      ),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      subtitle: Text('₹${item.price.toStringAsFixed(2)} • ${item.category}',
          style: TextStyle(color: Colors.grey.shade700)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () => _toggleFavorite(item, context),
          ),
          IconButton(
            icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _addToCart(item, 1, context),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodDetailScreen(menuItem: item),
          ),
        );
      },
    );
  }

  // Helper methods
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.orange.shade600,
      Colors.red.shade600,
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.purple.shade600,
      Colors.pink.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.brown.shade600,
      Colors.cyan.shade600,
      Colors.deepOrange.shade600,
    ];
    return colors[index % colors.length];
  }

  bool _isRestaurantOpen(String? openingTime, String? closingTime) {
    if (openingTime == null || closingTime == null) return true;
    
    try {
      final now = TimeOfDay.now();
      final open = _parseTime(openingTime);
      final close = _parseTime(closingTime);
      
      return (now.hour > open.hour || (now.hour == open.hour && now.minute >= open.minute)) &&
            (now.hour < close.hour || (now.hour == close.hour && now.minute < close.minute));
    } catch (e) {
      return true;
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}