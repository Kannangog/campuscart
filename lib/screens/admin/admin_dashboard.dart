import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_analytics_screen.dart';
import 'restaurant_approvals_screen.dart';
import 'users_management_screen.dart';
import 'admin_profile_screen.dart'; // Import the admin profile screen

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminAnalyticsScreen(),
    const RestaurantApprovalsScreen(),
    const UsersManagementScreen(),
    const AdminProfileScreen(), // Add profile screen to the screens list
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex != 3 ? _buildAppBar() : null, // Don't show app bar on profile screen
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
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
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

  AppBar _buildAppBar() {
    String title;
    switch (_currentIndex) {
      case 0:
        title = 'Analytics Dashboard';
        break;
      case 1:
        title = 'Restaurant Approvals';
        break;
      case 2:
        title = 'Users Management';
        break;
      default:
        title = 'Admin Dashboard';
    }

    return AppBar(
      title: Text(title),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      actions: _currentIndex != 3 ? _buildAppBarActions() : null,
    );
  }

  List<Widget> _buildAppBarActions() {
    switch (_currentIndex) {
      case 0: // Analytics
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh analytics data
            },
            tooltip: 'Refresh Data',
          ),
        ];
      case 1: // Approvals
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
            tooltip: 'Filter',
          ),
        ];
      case 2: // Users Management
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search users
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Sort users
            },
            tooltip: 'Sort',
          ),
        ];
      default:
        return [];
    }
  }
}