import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final List<Map<String, dynamic>> _promoCards = [
    {
      'title': 'Today\'s Top Sellers',
      'subtitle': 'Most ordered items today',
      'color': const Color(0xFF4CAF50),
      'icon': Icons.trending_up,
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      ),
    },
    {
      'title': 'Best Rated Foods',
      'subtitle': 'Highest rated by students',
      'color': const Color(0xFFFF9800),
      'icon': Icons.star,
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF9800), Color(0xFFEF6C00)],
      ),
    },
    {
      'title': 'Special Offers',
      'subtitle': 'Discounts just for you',
      'color': const Color(0xFF9C27B0),
      'icon': Icons.local_offer,
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
      ),
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.local_pizza, 'label': 'Pizza', 'color': Colors.orange},
    {'icon': Icons.ramen_dining, 'label': 'Noodles', 'color': Colors.red},
    {'icon': Icons.lunch_dining, 'label': 'Lunch', 'color': Colors.green},
    {'icon': Icons.local_cafe, 'label': 'Cafe', 'color': Colors.brown},
    {'icon': Icons.cake, 'label': 'Desserts', 'color': Colors.pink},
    {'icon': Icons.local_drink, 'label': 'Drinks', 'color': Colors.blue},
    {'icon': Icons.fastfood, 'label': 'Fast Food', 'color': Colors.purple},
    {'icon': Icons.set_meal, 'label': 'Meals', 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF4CAF50),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'CampusCart',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black26,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4CAF50),
                      Color(0xFF2E7D32),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: Colors.white, size: 26),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, 
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Welcome Section
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getGreeting()}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What would you like to eat today?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Promo Cards Section
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _promoCards.length,
                    itemBuilder: (context, index) {
                      final card = _promoCards[index];
                      final animationValue = _animationController.value;
                      final delay = index * 0.2;
                      final opacity = (animationValue - delay).clamp(0.0, 1.0);
                      
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, 50 * (1 - opacity)),
                          child: _buildPromoCard(context, card, index),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for food or restaurants...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 26),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Categories Section
          SliverToBoxAdapter(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_slideAnimation),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                    ),
                    TextButton(
                      onPressed: () {},
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
          
          SliverToBoxAdapter(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_slideAnimation),
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final animationValue = _animationController.value;
                    final delay = 0.4 + (index * 0.1);
                    final opacity = (animationValue - delay).clamp(0.0, 1.0);
                    
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - opacity)),
                        child: _buildCategoryItem(
                          context, 
                          category['icon'], 
                          category['label'], 
                          category['color'],
                          index
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Featured Restaurants Header
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Restaurants',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See All',
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

          // Featured Restaurants List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final animationValue = _animationController.value;
                final delay = 0.6 + (index * 0.15);
                final opacity = (animationValue - delay).clamp(0.0, 1.0);
                
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - opacity)),
                    child: _buildRestaurantCard(context, index),
                  ),
                );
              },
              childCount: 5, // Example count
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  // Helper method for building promo cards
  Widget _buildPromoCard(BuildContext context, Map<String, dynamic> card, int index) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.black.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: card['gradient'],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    card['icon'],
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card['subtitle'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Explore Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for building category items
  Widget _buildCategoryItem(BuildContext context, IconData icon, String label, Color color, int index) {
    return InkWell(
      onTap: () {
        // Add category selection logic here
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
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

  // Helper method for building restaurant card
  Widget _buildRestaurantCard(BuildContext context, int index) {
    final List<String> restaurantNames = [
      'Campus Cafe',
      'Student Bites',
      'The Grill Spot',
      'Pizza Corner',
      'Noodle House'
    ];
    
    final List<String> descriptions = [
      'Fresh food made daily for students',
      'Quick and delicious meals on the go',
      'Best grilled items in campus',
      'Authentic Italian pizzas',
      'Asian flavors for every taste'
    ];
    
    final List<double> ratings = [4.5, 4.2, 4.7, 4.8, 4.3];
    
    return InkWell(
      onTap: () {
        // Add restaurant selection logic here
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey.shade100,
                    child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 36),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Restaurant Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantNames[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descriptions[index],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ratings[index].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${20 + index * 5}-${30 + index * 5} min',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Open Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Open',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}