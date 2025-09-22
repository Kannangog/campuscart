// ignore_for_file: empty_catches, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'phone_auth_screen.dart';
import '../../screens/user/user_dashboard.dart';
import '../../screens/restaurant/restaurant_dashboard.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _checkUserAndNavigate(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkUserAndNavigate(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userModel = UserModel.fromFirestore(userDoc);
        _navigateToDashboard(userModel);
      }
    } catch (e) {
    }
  }

  void _navigateToDashboard(UserModel user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) {
          if (user.role == UserRole.restaurantOwner) {
            return const RestaurantDashboard();
          } else {
            return const UserDashboard();
          }
        },
      ),
      (route) => false,
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signInWithGoogle(role: _selectedRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToPhoneAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhoneAuthScreen(selectedRole: _selectedRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const lightGreen = Colors.lightGreen;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade700),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with improved animation
              Text(
                'Join ZoneFeast',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: lightGreen,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: lightGreen.withOpacity(0.2),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn()
              .slideY(begin: -0.3, curve: Curves.easeOutCubic),
              
              const SizedBox(height: 8),
              
              Text(
                'Choose how you want to sign up',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: -0.2, curve: Curves.easeOutCubic),
              
              const SizedBox(height: 40),
              
              // Role Selection with improved animation
              Text(
                'I am a:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms)
              .slideX(begin: -0.1, curve: Curves.easeOut),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.user,
                      title: 'Customer',
                      subtitle: 'Order food from restaurants',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.restaurantOwner,
                      title: 'Restaurant',
                      subtitle: 'Manage your restaurant',
                      icon: Icons.restaurant,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 400.ms)
              .slideX(begin: -0.3, curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              // Sign Up Options
              Text(
                'Sign up with:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              )
              .animate()
              .fadeIn(delay: 500.ms)
              .slideX(begin: -0.1, curve: Curves.easeOut),
              
              const SizedBox(height: 16),
              
              // Phone Sign Up Button with improved styling
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _navigateToPhoneAuth,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: lightGreen,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: lightGreen.withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_rounded, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Continue with Phone',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 600.ms)
                .slideY(
                  begin: 0.5,
                  curve: Curves.easeOutBack,
                  duration: 600.ms,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Google Sign Up Button with improved styling
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_icon.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                )
                .animate()
                .fadeIn(delay: 700.ms)
                .slideY(
                  begin: 0.5,
                  curve: Curves.easeOutBack,
                  duration: 600.ms,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Restaurant notice with improved styling
              if (_selectedRole == UserRole.restaurantOwner)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightGreen.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: lightGreen.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: lightGreen, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can create your restaurant profile after signing up.',
                          style: TextStyle(
                            color: lightGreen.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 800.ms)
                .slideY(begin: 0.3, curve: Curves.easeOut),
              
              if (_selectedRole == UserRole.restaurantOwner) const SizedBox(height: 24),
              
              const SizedBox(height: 24),
              
              // Terms and Privacy with improved styling
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(delay: 900.ms)
              .blur(
                begin: const Offset(0, 5),
                duration: 600.ms,
                curve: Curves.easeOut,
              ),
              
              const SizedBox(height: 32),
              
              // Sign In Link with improved styling
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: lightGreen,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 1000.ms)
              .scale(begin: const Offset(0.95, 0.95), duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    const lightGreen = Colors.lightGreen;
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? lightGreen.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? lightGreen
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: lightGreen.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.shade300.withOpacity(0.5),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? lightGreen
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isSelected 
                    ? lightGreen
                    : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}