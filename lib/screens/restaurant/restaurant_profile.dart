// ignore_for_file: deprecated_member_use

import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/utilities/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscart/models/restaurant_model.dart';
import 'package:campuscart/providers/restaurant_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campuscart/screens/notifications/notifications_screen.dart';
import 'package:campuscart/screens/support/support_screen.dart';
import 'package:campuscart/screens/restaurant/restaurant_management_screen.dart';

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  ConsumerState<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends ConsumerState<RestaurantProfileScreen> {

  @override
  void initState() {
    super.initState();
  }

  Future<void> _logout() async {
    try {
      await ref.read(authProvider.notifier).signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _navigateToSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportScreen()),
    );
  }

  void _navigateToRestaurantManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RestaurantManagementScreen()),
    );
  }

  void _toggleTheme() {
    final currentThemeMode = ref.read(themeProvider.notifier).getThemeMode();
    final newThemeMode = currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    ref.read(themeProvider.notifier).setThemeMode(newThemeMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final user = ref.watch(authStateProvider).value;
    final restaurantAsync = user != null ? ref.watch(restaurantsByOwnerProvider(user.uid)) : const AsyncValue.data([]);
    final themeMode = ref.watch(themeProvider.notifier).getThemeMode();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Profile'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _navigateToNotifications,
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.sunny : Icons.mood),
            onPressed: _toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: restaurantAsync.when(
        data: (restaurants) {
          final hasRestaurant = restaurants.isNotEmpty;
          final restaurant = hasRestaurant ? restaurants.first : null;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with profile image
                _buildProfileHeader(theme, restaurant, hasRestaurant),
                
                const SizedBox(height: 24),
                
                // Menu options
                _buildMenuOptions(theme, hasRestaurant),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => user != null ? ref.refresh(restaurantsByOwnerProvider(user.uid)) : null,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, RestaurantModel? restaurant, bool hasRestaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: hasRestaurant && restaurant!.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.shop, size: 40, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.warning, color: Colors.red),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.shop, size: 40, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (hasRestaurant && restaurant != null) ...[
            Text(
              restaurant.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.email,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: restaurant.isApproved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                restaurant.isApproved ? 'APPROVED' : 'PENDING APPROVAL',
                style: TextStyle(
                  color: restaurant.isApproved ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            Text(
              'No Restaurant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your restaurant profile to get started',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuOptions(ThemeData theme, bool hasRestaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuOption(
            theme,
            icon: Icons.shop,
            title: 'Restaurant/Shop',
            subtitle: hasRestaurant ? 'Manage your restaurant' : 'Create your restaurant',
            onTap: _navigateToRestaurantManagement,
          ),
          const Divider(height: 24),
          _buildMenuOption(
            theme,
            icon: Icons.notification_important,
            title: 'Notifications',
            subtitle: 'View your notifications',
            onTap: _navigateToNotifications,
          ),
          const Divider(height: 24),
          _buildMenuOption(
            theme,
            icon: Icons.support,
            title: 'Support',
            subtitle: 'Get help and support',
            onTap: _navigateToSupport,
          ),
          const Divider(height: 24),
          _buildMenuOption(
            theme,
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _showLogoutDialog,
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isLogout 
            ? Colors.red.withOpacity(0.2) 
            : theme.primaryColor.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : theme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isLogout ? Colors.red : theme.colorScheme.onBackground,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Icon(
        Icons.arrow_right,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}