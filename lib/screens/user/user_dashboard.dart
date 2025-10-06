// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home/home_screen.dart';
import 'restaurants_screen.dart';
import 'cart_screen.dart';
import 'order_screen/orders_screen.dart';
import 'profile_screen.dart';
import '../../providers/cart_provider.dart';

class UserDashboard extends ConsumerStatefulWidget {
  final int initialIndex; // Add this parameter
  
  const UserDashboard({super.key, this.initialIndex = 0}); // Set default value

  @override
  ConsumerState<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends ConsumerState<UserDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // Initialize with 0
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RestaurantsScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Use the initialIndex from widget parameter
    _currentIndex = widget.initialIndex;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _animationController.reset();
                _animationController.forward();
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF4CAF50), // Light green
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            items: [
              BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _currentIndex == 0 ? _animation : const AlwaysStoppedAnimation(1.0),
                  child: const Icon(Icons.home_outlined),
                ),
                activeIcon: ScaleTransition(
                  scale: _animation,
                  child: const Icon(Icons.home),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _currentIndex == 1 ? _animation : const AlwaysStoppedAnimation(1.0),
                  child: const Icon(Icons.restaurant_outlined),
                ),
                activeIcon: ScaleTransition(
                  scale: _animation,
                  child: const Icon(Icons.restaurant),
                ),
                label: 'Restaurants',
              ),
              BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _currentIndex == 2 ? _animation : const AlwaysStoppedAnimation(1.0),
                  child: _buildCartIcon(Icons.shopping_cart_outlined, cartState.totalItems),
                ),
                activeIcon: ScaleTransition(
                  scale: _animation,
                  child: _buildCartIcon(Icons.shopping_cart, cartState.totalItems),
                ),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _currentIndex == 3 ? _animation : const AlwaysStoppedAnimation(1.0),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                activeIcon: ScaleTransition(
                  scale: _animation,
                  child: const Icon(Icons.receipt_long),
                ),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _currentIndex == 4 ? _animation : const AlwaysStoppedAnimation(1.0),
                  child: const Icon(Icons.person_outlined),
                ),
                activeIcon: ScaleTransition(
                  scale: _animation,
                  child: const Icon(Icons.person),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartIcon(IconData icon, int itemCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (itemCount > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B), // Complementary red color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                itemCount > 9 ? '9+' : '$itemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}