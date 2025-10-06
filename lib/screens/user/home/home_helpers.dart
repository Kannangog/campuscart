import 'package:flutter/material.dart';

class HomeHelpers {
  // Promo cards data
  static final List<Map<String, dynamic>> promoCards = [
    {
      'title': '50% OFF',
      'subtitle': 'On your first order',
      'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      ),
      'route': '/specials',
    },
    {
      'title': 'Free Delivery',
      'subtitle': 'On orders above ₹299',
      'image': 'https://images.unsplash.com/photo-1565958011703-44f9829ba187',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.fromARGB(255, 50, 167, 54), Color(0xFF2E7D32)],
      ),
      'route': '/free-delivery',
    },
    {
      'title': 'Combo Offers',
      'subtitle': 'Special meal deals for you',
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      'gradient': const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
      ),
      'route': '/combo-offers',
    },
  ];

  // Categories data
  static final List<Map<String, dynamic>> categories = [
    {'icon': Icons.all_inclusive, 'label': 'All', 'category': 'All'},
    {'icon': Icons.eco, 'label': 'Veg', 'category': 'Veg'},
    {'icon': Icons.set_meal, 'label': 'Non Veg', 'category': 'Non Veg'},
    {'icon': Icons.rice_bowl, 'label': 'Briyani', 'category': 'Briyani'},
    {'icon': Icons.soup_kitchen, 'label': 'Curries', 'category': 'Curries'},
    {'icon': Icons.bakery_dining, 'label': 'Rotis', 'category': 'Rotis'},
    {'icon': Icons.lunch_dining, 'label': 'Meal', 'category': 'Meal'},
    {'icon': Icons.local_pizza, 'label': 'Pizza', 'category': 'Pizza'},
    {'icon': Icons.fastfood, 'label': 'Burger', 'category': 'Burger'},
    {'icon': Icons.breakfast_dining, 'label': 'Breakfast', 'category': 'Breakfast'},
    {'icon': Icons.cake, 'label': 'Desserts', 'category': 'Desserts'},
  ];

  // Helper methods
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  static Color getCategoryColor(int index) {
    final colors = [
      Colors.orange.shade600,
      Colors.red.shade600,
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.purple.shade600,
      Colors.pink.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.brown.shade600,
      Colors.cyan.shade600,
      Colors.deepOrange.shade600,
    ];
    return colors[index % colors.length];
  }

  static bool isRestaurantOpen(String? openingTime, String? closingTime) {
    if (openingTime == null || closingTime == null) return true;
    
    try {
      final now = TimeOfDay.now();
      final open = _parseTime(openingTime);
      final close = _parseTime(closingTime);
      
      return (now.hour > open.hour || (now.hour == open.hour && now.minute >= open.minute)) &&
            (now.hour < close.hour || (now.hour == close.hour && now.minute < close.minute));
    } catch (e) {
      return true;
    }
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static void showComingSoonDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: const Text('This feature is coming soon! Stay tuned for exciting offers.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}