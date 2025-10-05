// main.dart
import 'package:campuscart/utilities/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'providers/notification_provider.dart'; // Single import now

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enhanced Firebase initialization with error handling
  try {
    // Check if Firebase is already initialized
    try {
      Firebase.app();
    } catch (_) {
      // Initialize if not already initialized
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Continue without Firebase for debugging
    debugPrint('Firebase initialization failed: $e');
  }
  
  // Initialize notifications with error handling
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
    // Continue without notifications
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme provider to get the current theme
    final theme = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Zonefeast',
      debugShowCheckedModeBanner: false,
      theme: theme, // Use the theme from themeProvider
      home: const AuthWrapper(),
    );
  }
}
