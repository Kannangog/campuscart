import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'login_screen.dart';
import 'pending_approval_screen.dart';
import '../user/user_dashboard.dart';
import '../restaurant/restaurant_dashboard.dart';
import '../admin/admin_dashboard.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        final userAsync = ref.watch(userProvider(user));
        return userAsync.when(
          data: (userModel) {
            if (userModel == null) {
              return const LoginScreen();
            }

            // Check if restaurant owner needs approval
            if (userModel.role == UserRole.restaurant && !userModel.isApproved) {
              return const PendingApprovalScreen();
            }

            // Route to appropriate dashboard based on role
            switch (userModel.role) {
              case UserRole.user:
                return const UserDashboard();
              case UserRole.restaurant:
                return const RestaurantDashboard();
              case UserRole.admin:
                return const AdminDashboard();
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Authentication Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(authStateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}