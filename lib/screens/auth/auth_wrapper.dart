import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'login_screen.dart';
import 'pending_approval_screen.dart';
import '../user/user_dashboard.dart';
import '../restaurant/restaurant_dashboard.dart';
import '../admin/admin_dashboard.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isInitialCheckDone = false;

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure auth state is properly loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isInitialCheckDone = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (!_isInitialCheckDone) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const LoginScreen();
        }

        final userAsync = ref.watch(userProvider(user));
        return userAsync.when(
          data: (userModel) {
            if (userModel == null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('User profile not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(authProvider.notifier).signOut(),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Debug print to check the user role and approval status
            debugPrint('User Role: ${userModel.role}');
            debugPrint('Is Approved: ${userModel.isApproved}');

            // Check if restaurant owner needs approval
            if (userModel.role == UserRole.restaurantOwner && !userModel.isApproved) {
              return const PendingApprovalScreen();
            }

            // Route to appropriate dashboard based on role
            switch (userModel.role) {
              case UserRole.admin:
                return const AdminDashboard();
              case UserRole.restaurantOwner:
                return const RestaurantDashboard();
              case UserRole.user:
              default:
                return const UserDashboard();
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading user: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(authProvider.notifier).signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Authentication Error: ${error.toString()}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}