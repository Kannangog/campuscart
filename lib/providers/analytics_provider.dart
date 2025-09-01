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
  AnalyticsNotifier() : super(const AsyncValue.loading()) {
    fetchAnalytics('Today');
  }

  Future<void> fetchAnalytics(String period) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
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

      // Fetch orders data
      final ordersQuery = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: now);

      final ordersSnapshot = await ordersQuery.get();
      final orders = ordersSnapshot.docs;

      // Calculate analytics data
      final totalOrders = orders.length;
      final revenue = orders.fold(0.0, (sum, doc) => sum + (doc['totalAmount'] ?? 0.0));
      final avgOrderValue = totalOrders > 0 ? revenue / totalOrders : 0.0;
      
      // Calculate rating (assuming you have a ratings collection)
      final ratingSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      final ratings = ratingSnapshot.docs;
      final rating = ratings.isNotEmpty 
          ? ratings.fold(0.0, (sum, doc) => sum + (doc['rating'] ?? 0.0)) / ratings.length
          : 0.0;

      // Calculate revenue data for chart
      final revenueData = await _calculateRevenueData(period, user.uid);
      
      // Get top selling items
      final topItems = await _getTopSellingItems(period, user.uid);
      
      // Get order status distribution
      final orderStatusDistribution = _getOrderStatusDistribution(orders);

      // For demo purposes, using placeholder values for changes
      // In a real app, you would compare with previous period
      final ordersChange = '+12%';
      final revenueChange = '+8%';
      final avgOrderChange = '+5%';
      final ratingChange = '+0.2';

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
      );

      state = AsyncValue.data(analyticsData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<double>> _calculateRevenueData(String period, String userId) async {
    // This is a simplified implementation
    // In a real app, you would query Firestore for daily/weekly revenue
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
              .where('userId', isEqualTo: userId)
              .where('createdAt', isGreaterThanOrEqualTo: hourStart)
              .where('createdAt', isLessThan: hourEnd);
          
          final snapshot = await query.get();
          final revenue = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc['totalAmount'] ?? 0.0));
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
              .where('userId', isEqualTo: userId)
              .where('createdAt', isGreaterThanOrEqualTo: dayStart)
              .where('createdAt', isLessThan: dayEnd);
          
          final snapshot = await query.get();
          final revenue = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc['totalAmount'] ?? 0.0));
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
              .where('userId', isEqualTo: userId)
              .where('createdAt', isGreaterThanOrEqualTo: weekStart)
              .where('createdAt', isLessThan: weekEnd);
          
          final snapshot = await query.get();
          final revenue = snapshot.docs.fold(0.0, (sum, doc) => sum + (doc['totalAmount'] ?? 0.0));
          revenueData.add(revenue);
        }
        break;
    }
    
    return revenueData;
  }

  Future<List<TopItem>> _getTopSellingItems(String period, String userId) async {
    // This is a simplified implementation
    // In a real app, you would query Firestore for top items
    
    // For demo purposes, return some sample data
    return [
      TopItem(name: 'Margherita Pizza', quantity: 45, revenue: 540.0),
      TopItem(name: 'Chicken Burger', quantity: 38, revenue: 456.0),
      TopItem(name: 'Caesar Salad', quantity: 32, revenue: 320.0),
      TopItem(name: 'Pasta Carbonara', quantity: 28, revenue: 420.0),
      TopItem(name: 'Fish & Chips', quantity: 25, revenue: 375.0),
    ];
  }

  Map<String, int> _getOrderStatusDistribution(List<QueryDocumentSnapshot<Map<String, dynamic>>> orders) {
    final distribution = <String, int>{};
    
    for (final order in orders) {
      final status = order['status'] ?? 'Pending';
      distribution[status] = (distribution[status] ?? 0) + 1;
    }
    
    return distribution;
  }

  List<String> _generateRevenueLabels(String period) {
    switch (period) {
      case 'Today':
        final now = DateTime.now();
        return List.generate(12, (i) {
          final hour = (now.hour - 11 + i) % 24;
          return '${hour.toString().padLeft(2, '0')}:00';
        });
        
      case 'Last 7 Days':
        final now = DateTime.now();
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