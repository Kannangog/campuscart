// ignore_for_file: deprecated_member_use

import 'package:campuscart/screens/user/Favorites_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart'; // Import your favorites screen

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view profile')),
      );
    }

    final userAsync = ref.watch(userProvider(user));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: userAsync.when(
        data: (userModel) {
          if (userModel == null) return const SizedBox();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: userModel.profileImageUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: userModel.profileImageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                      ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        userModel.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        userModel.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      
                      const SizedBox(height: 4),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Customer',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Profile Options
                Card(
                  child: Column(
                    children: [
                      _buildProfileOption(
                        context,
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        onTap: () => _showEditProfileDialog(context, ref, userModel),
                      ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3),
                      
                      const Divider(height: 1),
                      
                      _buildProfileOption(
                        context,
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        onTap: () {
                          // Navigate to notification settings
                        },
                      ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.3),
                      
                      const Divider(height: 1),
                      
                      _buildProfileOption(
                        context,
                        icon: Icons.favorite,
                        title: 'Favorites',
                        subtitle: 'Your favorite restaurants and dishes',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FavoritesScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // App Options
                Card(
                  child: Column(
                    children: [
                      _buildProfileOption(
                        context,
                        icon: Icons.help,
                        title: 'Help & Support',
                        subtitle: 'Get help and contact support',
                        onTap: () {
                          // Navigate to help
                        },
                      ).animate().fadeIn(delay: 1100.ms).slideX(begin: -0.3),
                      
                      const Divider(height: 1),
                      
                      _buildProfileOption(
                        context,
                        icon: Icons.logout,
                        title: 'Sign Out',
                        subtitle: 'Sign out of your account',
                        onTap: () => _showSignOutDialog(context, ref),
                        textColor: Colors.red,
                      ).animate().fadeIn(delay: 1200.ms).slideX(begin: -0.3),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App Version
                Text(
                  'FoodHub v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ).animate().fadeIn(delay: 1300.ms),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, userModel) {
    final nameController = TextEditingController(text: userModel.name);
    final phoneController = TextEditingController(text: userModel.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(authProvider.notifier).updateUserProfile(
                  userId: userModel.id,
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}