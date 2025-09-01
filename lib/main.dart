import 'package:campuscart/utilities/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';

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
      title: 'Campuscart',
      debugShowCheckedModeBanner: false,
      theme: theme, // Use the theme from themeProvider
      home: const AuthWrapper(),
    );
  }
}