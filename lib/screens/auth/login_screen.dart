// ignore_for_file: deprecated_member_use

import 'package:campuscart/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import 'phone_auth_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signInWithGoogle(role: UserRole.customer);
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

  @override
  Widget build(BuildContext context) {
    const lightGreen = Colors.lightGreen;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Logo and Title with improved animation
              Column(
                children: [
                  Container(
                    width: 124,
                    height: 116,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          lightGreen,
                          lightGreen.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: lightGreen.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/app_image.jpg', 
                        width: 500,
                        height: 500,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.elasticOut)
                  .shake(delay: 300.ms, hz: 4, offset: const Offset(0.5, 0)),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'ZoneFeast',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
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
                  )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOutCubic),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Delicious food delivered to your campus',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                ],
              ),
              
              const SizedBox(height: 60),
              
              // Sign In Options
              Column(
                children: [
                  // Phone Sign In with improved button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PhoneAuthScreen(),
                          ),
                        );
                      },
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
                  
                  const SizedBox(height: 20),
                  
                  // Divider with improved styling
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(delay: 700.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 500.ms),
                  
                  const SizedBox(height: 20),
                  
                  // Google Sign In with improved button
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading)
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey.shade600,
                              ),
                            )
                          else
                            Image.asset(
                              'assets/images/google_icon.png',
                              height: 24,
                              width: 24,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            _isLoading ? 'Signing in...' : 'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 800.ms)
                    .slideY(
                      begin: 0.5,
                      curve: Curves.easeOutBack,
                      duration: 600.ms,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Sign Up Link with improved styling
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Sign Up',
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
              .fadeIn(delay: 900.ms)
              .scale(begin: const Offset(0.95, 0.95), duration: 500.ms),
              
              const SizedBox(height: 24),
              
              // Terms and Privacy with improved styling
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(delay: 1000.ms)
              .blur(
                begin: const Offset(0, 5),
                duration: 600.ms,
                curve: Curves.easeOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}