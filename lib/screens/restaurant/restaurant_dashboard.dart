import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_screen.dart';
import 'menu_management_screen.dart';
import 'orders_management_screen.dart';
import 'offers_screen.dart';
import 'restaurant_profile.dart'; // Import the profile screen

class RestaurantDashboard extends ConsumerStatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  ConsumerState<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends ConsumerState<RestaurantDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AnalyticsScreen(),
    const MenuManagementScreen(),
    const OrdersManagementScreen(),
    const OffersScreen(),
    const RestaurantProfileScreen(), // Added profile screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 4 ? null : _buildAppBar(), // No app bar for profile screen
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Offers',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  AppBar? _buildAppBar() {
    switch (_currentIndex) {
      case 0:
        return AppBar(
          title: const Text('Analytics Dashboard'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        );
      case 1:
        return AppBar(
          title: const Text('Menu Management'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Add new menu item
              },
            ),
          ],
        );
      case 2:
        return AppBar(
          title: const Text('Orders Management'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // Filter orders
              },
            ),
          ],
        );
      case 3:
        return AppBar(
          title: const Text('Offers & Promotions'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Add new offer
              },
            ),
          ],
        );
      default:
        return null; // No app bar for profile screen
    }
  }
}