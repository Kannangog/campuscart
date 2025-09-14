// ignore_for_file: avoid_types_as_parameter_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Data models
class AnalyticsData {
  final int totalOrders;
  final double revenue;
  final double avgOrderValue;
  final double rating;
  final String ordersChange;
  final String revenueChange;
  final String avgOrderChange;
  final String ratingChange;
  final List<double> revenueData;
  final List<String> revenueLabels;
  final List<TopItem> topItems;
  final Map<String, int> orderStatusDistribution;
  final bool hasRestaurant; // New field to track if user has a restaurant

  AnalyticsData({
    required this.totalOrders,
    required this.revenue,
    required this.avgOrderValue,
    required this.rating,
    required this.ordersChange,
    required this.revenueChange,
    required this.avgOrderChange,
    required this.ratingChange,
    required this.revenueData,
    required this.revenueLabels,
    required this.topItems,
    required this.orderStatusDistribution,
    this.hasRestaurant = true, // Default to true for backward compatibility
  });
}

class TopItem {
  final String name;
  final int quantity;
  final double revenue;

  TopItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

// Analytics Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsData>>((ref) {
  return AnalyticsNotifier();
});

class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsData>> {
  AnalyticsNotifier() : super(const AsyncValue.loading());

  Future<void> fetchAnalytics(String period) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user's restaurant ID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }
      
      final restaurantId = userDoc.data()?['restaurantId'];
      if (restaurantId == null) {
        // Return empty analytics data instead of throwing an error
        final emptyAnalyticsData = AnalyticsData(
          totalOrders: 0,
          revenue: 0,
          avgOrderValue: 0,
          rating: 0,
          ordersChange: '0%',
          revenueChange: '0%',
          avgOrderChange: '0%',
          ratingChange: '0',
          revenueData: [],
          revenueLabels: _generateRevenueLabels(period),
          topItems: [],
          orderStatusDistribution: {},
          hasRestaurant: false,
        );
        state = AsyncValue.data(emptyAnalyticsData);
        return;
      }

      // Calculate date range based on period
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case 'Last 7 Days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'Today':
        default:
          startDate = DateTime(now.year, now.month, now.day);
          break;
      }

      // Fetch orders data for the restaurant
      final ordersQuery = FirebaseFirestore.instance
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: now);

      final ordersSnapshot = await ordersQuery.get();
      final orders = ordersSnapshot.docs;

      // Calculate analytics data
      final totalOrders = orders.length;
      final revenue = orders.fold(0.0, (sum, doc) => sum + (doc.data()['totalAmount'] ?? 0.0));
      final avgOrderValue = totalOrders > 0 ? revenue / totalOrders : 0.0;
      
      // Calculate rating for the restaurant
      final ratingSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      
      final ratings = ratingSnapshot.docs;
      final rating = ratings.isNotEmpty 
          ? ratings.fold(0.0, (sum, doc) => sum + (doc.data()['rating'] ?? 0.0)) / ratings.length
          : 0.0;

      // Calculate revenue data for chart
      final revenueData = await _calculateRevenueData(period, restaurantId);
      
      // Get top selling items
      final topItems = await _getTopSellingItems(period, restaurantId);
      
      // Get order status distribution
      final orderStatusDistribution = _getOrderStatusDistribution(orders);

      // For demo purposes, using placeholder values for changes
      // In a real app, you would compare with previous period
      const ordersChange = '+12%';
      const revenueChange = '+8%';
      const avgOrderChange = '+5%';
      const ratingChange = '+0.2';

      // Generate labels based on period
      final revenueLabels = _generateRevenueLabels(period);

      final analyticsData = AnalyticsData(
        totalOrders: totalOrders,
        revenue: revenue,
        avgOrderValue: avgOrderValue,
        rating: rating,
        ordersChange: ordersChange,
        revenueChange: revenueChange,
        avgOrderChange: avgOrderChange,
        ratingChange: ratingChange,
        revenueData: revenueData,
        revenueLabels: revenueLabels,
        topItems: topItems,
        orderStatusDistribution: orderStatusDistribution,
        hasRestaurant: true,
      );

      state = AsyncValue.data(analyticsData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<double>> _calculateRevenueData(String period, String restaurantId) async {
    final now = DateTime.now();
    List<double> revenueData = [];
    
    switch (period) {
      case 'Today':
        // For today, get hourly data (last 12 hours)
        for (int i = 0; i < 12; i++) {
          final hourStart = DateTime(now.year, now.month, now.day, now.hour - i);
          final hourEnd = hourStart.add(const Duration(hours: 1));
          
          final query = FirebaseFirestore.instance
              .collection('orders')
              .where('restaurantId', isEqualTo: restaurantId)
              .where('createdAt', isGreaterThanOrEqualTo: hourStart)
              .where('createdAt', isLessThan: hourEnd);
          
          final snapshot = await query.get();
          final revenue = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc.data()['totalAmount'] ?? 0.0));
          revenueData.add(revenue);
        }
        revenueData = revenueData.reversed.toList();
        break;
        
      case 'Last 7 Days':
        // For last 7 days, get daily data
        for (int i = 6; i >= 0; i--) {
          final dayStart = DateTime(now.year, now.month, now.day - i);
          final dayEnd = dayStart.add(const Duration(days: 1));
          
          final query = FirebaseFirestore.instance
              .collection('orders')
              .where('restaurantId', isEqualTo: restaurantId)
              .where('createdAt', isGreaterThanOrEqualTo: dayStart)
              .where('createdAt', isLessThan: dayEnd);
          
          final snapshot = await query.get();
          final revenue = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc.data()['totalAmount'] ?? 0.0));
          revenueData.add(revenue);
        }
        break;
        
      case 'Last 30 Days':
        // For last 30 days, get weekly data (4 weeks)
        for (int i = 3; i >= 0; i--) {
          final weekStart = DateTime(now.year, now.month, now.day - (i * 7));
          final weekEnd = weekStart.add(const Duration(days: 7));
          
          final query = FirebaseFirestore.instance
              .collection('orders')
              .where('restaurantId', isEqualTo: restaurantId)
              .where('createdAt', isGreaterThanOrEqualTo: weekStart)
              .where('createdAt', isLessThan: weekEnd);
          
          final snapshot = await query.get();
          final revenue = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc.data()['totalAmount'] ?? 0.0));
          revenueData.add(revenue);
        }
        break;
        
      default:
        revenueData = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    }
    
    return revenueData;
  }

  Future<List<TopItem>> _getTopSellingItems(String period, String restaurantId) async {
    try {
      // Query order items for the restaurant
      final ordersQuery = FirebaseFirestore.instance
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId);
      
      final ordersSnapshot = await ordersQuery.get();
      
      // Aggregate item sales
      final itemSales = <String, Map<String, dynamic>>{};
      
      for (final order in ordersSnapshot.docs) {
        final items = order.data()['items'] as List<dynamic>? ?? [];
        
        for (final item in items) {
          final itemName = item['name'] ?? 'Unknown Item';
          final quantity = (item['quantity'] ?? 1) as int;
          final price = (item['price'] ?? 0.0) as double;
          final revenue = quantity * price;
          
          if (itemSales.containsKey(itemName)) {
            itemSales[itemName]!['quantity'] += quantity;
            itemSales[itemName]!['revenue'] += revenue;
          } else {
            itemSales[itemName] = {
              'quantity': quantity,
              'revenue': revenue,
            };
          }
        }
      }
      
      // Convert to TopItem list and sort by revenue
      final topItemsList = itemSales.entries.map((entry) {
        return TopItem(
          name: entry.key,
          quantity: entry.value['quantity'],
          revenue: entry.value['revenue'],
        );
      }).toList();
      
      topItemsList.sort((a, b) => b.revenue.compareTo(a.revenue));
      
      // Return top 5 items
      return topItemsList.take(5).toList();
    } catch (e) {
      // Fallback to sample data if there's an error
      return [
        TopItem(name: 'Margherita Pizza', quantity: 45, revenue: 540.0),
        TopItem(name: 'Chicken Burger', quantity: 38, revenue: 456.0),
        TopItem(name: 'Caesar Salad', quantity: 32, revenue: 320.0),
        TopItem(name: 'Pasta Carbonara', quantity: 28, revenue: 420.0),
        TopItem(name: 'Fish & Chips', quantity: 25, revenue: 375.0),
      ];
    }
  }

  Map<String, int> _getOrderStatusDistribution(List<QueryDocumentSnapshot<Map<String, dynamic>>> orders) {
    final distribution = <String, int>{
      'Pending': 0,
      'Preparing': 0,
      'Out for Delivery': 0,
      'Delivered': 0,
      'Cancelled': 0,
    };
    
    for (final order in orders) {
      final status = order.data()['status'] ?? 'Pending';
      distribution[status] = (distribution[status] ?? 0) + 1;
    }
    
    return distribution;
  }

  List<String> _generateRevenueLabels(String period) {
    final now = DateTime.now();
    
    switch (period) {
      case 'Today':
        return List.generate(12, (i) {
          final hour = (now.hour - 11 + i) % 24;
          return '${hour.toString().padLeft(2, '0')}:00';
        });
        
      case 'Last 7 Days':
        return List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          return '${day.day}/${day.month}';
        });
        
      case 'Last 30 Days':
        return ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
        
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
  }
}