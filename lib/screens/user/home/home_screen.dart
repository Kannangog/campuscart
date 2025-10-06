// ignore_for_file: deprecated_member_use, unused_result

import 'package:campuscart/screens/user/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscart/screens/user/Favorites_screen.dart';
import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/providers/restaurant_provider.dart';
import 'package:campuscart/providers/menu_provider.dart';
import 'package:campuscart/providers/cart_provider.dart';
import 'package:campuscart/providers/favorite_provider.dart';
import 'package:campuscart/models/menu_item_model.dart';
import 'home_components.dart';
import 'home_helpers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchResults = false;
  List<MenuItemModel> _searchResults = [];
  List<MenuItemModel> _filteredMenuItems = [];
  int _currentCarouselIndex = 0;
  String _selectedCategory = 'All';

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

    // Initialize with all menu items
    _loadMenuItems();
  }

  void _loadMenuItems() async {
    try {
      final allMenuItems = await ref.read(menuProvider.future);
      setState(() {
        _filteredMenuItems = allMenuItems;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _filterByCategory(String category) async {
    setState(() {
      _selectedCategory = category;
    });

    try {
      final allMenuItems = await ref.read(menuProvider.future);
      
      if (category == 'All') {
        setState(() {
          _filteredMenuItems = allMenuItems;
        });
      } else {
        final filtered = allMenuItems.where((item) {
          return item.category.toLowerCase() == category.toLowerCase();
        }).toList();
        
        setState(() {
          _filteredMenuItems = filtered;
        });
      }
    } catch (e) {
      // Handle error
    }
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
          _loadMenuItems();
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

            // Welcome Section
            if (!_showSearchResults) ...[
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${HomeHelpers.getGreeting()}${user?.displayName != null ? ' ${user?.displayName}' : ''}!',
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
                  child: HomeComponents.buildPromoCarousel(
                    context,
                    _currentCarouselIndex,
                    (index) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                    HomeHelpers.showComingSoonDialog,
                  ),
                ),
              ),
            ],

            // Search Bar - Always visible
            SliverToBoxAdapter(
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
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _showSearchResults = false;
                                  _searchResults.clear();
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Search Results Section (shown below search bar when searching)
            if (_showSearchResults) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Search Results (${_searchResults.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      if (_searchResults.isNotEmpty)
                        Text(
                          'Found ${_searchResults.length} items',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try different keywords or browse categories',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
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
                      return HomeComponents.buildSearchResultItem(
                        context, 
                        item, 
                        index,
                        ref.read(favoriteProvider.notifier).isFavorite(item.id),
                        () => _toggleFavorite(item, context),
                        () => _addToCart(item, 1, context),
                      );
                    },
                    childCount: _searchResults.length,
                  ),
                ),
            ],

            // If showing search results, skip the rest of the content
            if (_showSearchResults) const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Only show categories and other content when not searching
            if (!_showSearchResults) ...[
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
              
              // Categories List with filtering
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: HomeHelpers.categories.length,
                      itemBuilder: (context, index) {
                        final category = HomeHelpers.categories[index];
                        final isSelected = _selectedCategory == category['category'];
                        return GestureDetector(
                          onTap: () => _filterByCategory(category['category']),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 80,
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    category['icon'],
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade700,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Category Filter Results Header
              if (_selectedCategory != 'All') ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_selectedCategory (${_filteredMenuItems.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        if (_filteredMenuItems.isNotEmpty)
                          Chip(
                            label: Text(
                              '${_filteredMenuItems.length} items',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                      ],
                    ),
                  ),
                ),

                // Category Filtered Items
                if (_filteredMenuItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No items found in $_selectedCategory',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Try another category',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filteredMenuItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredMenuItems[index];
                          return HomeComponents.buildFoodItemCard(
                            context, 
                            item, 
                            index,
                            ref.read(favoriteProvider.notifier).isFavorite(item.id),
                            () => _toggleFavorite(item, context),
                            () => _addToCart(item, 1, context),
                          );
                        },
                      ),
                    ),
                  ),
              ],

              // POPULAR ITEMS SECTION
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

              // Top Selling Items
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
                          return HomeComponents.buildFoodItemCard(
                            context, 
                            item, 
                            index,
                            ref.read(favoriteProvider.notifier).isFavorite(item.id),
                            () => _toggleFavorite(item, context),
                            () => _addToCart(item, 1, context),
                          );
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

              // Popular Restaurants Header
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
                          return HomeComponents.buildRestaurantCardHorizontal(
                            context, 
                            restaurant, 
                            index
                          );
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
          ],
        ),
      ),
    );
  }
}