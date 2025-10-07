// ignore_for_file: deprecated_member_use

import 'package:campuscart/providers/order_provider/firestore_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuscart/models/order_model.dart';
import 'package:campuscart/models/user_model.dart';
import 'package:campuscart/models/restaurant_model.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  String _selectedPeriod = 'Last 30 Days';
  final List<String> _periods = ['Today', 'Last 7 Days', 'Last 30 Days', 'All Time'];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'Last 7 Days':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'Last 30 Days':
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
        break;
      case 'All Time':
        _startDate = null;
        _endDate = null;
        break;
    }
    setState(() {});
  }

  String _formatRupees(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(allOrdersProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final restaurantsAsync = ref.watch(allRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _updateDateRange();
              });
            },
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Overview
            Text(
              'Platform Overview',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ).animate().fadeIn().slideX(begin: -0.3),
            
            const SizedBox(height: 16),
            
            // Overview Cards
            ordersAsync.when(
              data: (orders) => usersAsync.when(
                data: (users) => restaurantsAsync.when(
                  data: (restaurants) {
                    final analytics = _calculateAnalytics(
                      orders, 
                      users, 
                      restaurants,
                      _startDate,
                      _endDate,
                    );
                    
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildOverviewCard(
                          context,
                          title: 'Total Users',
                          value: '${analytics['totalUsers']}',
                          change: '+${analytics['userGrowth']}%',
                          isPositive: analytics['userGrowth'] > 0,
                          icon: Icons.people,
                          color: Colors.blue,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                        
                        _buildOverviewCard(
                          context,
                          title: 'Active Restaurants',
                          value: '${analytics['activeRestaurants']}',
                          change: '+${analytics['restaurantGrowth']}%',
                          isPositive: analytics['restaurantGrowth'] > 0,
                          icon: Icons.restaurant,
                          color: theme.colorScheme.primary,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                        
                        _buildOverviewCard(
                          context,
                          title: 'Total Orders',
                          value: '${analytics['totalOrders']}',
                          change: '+${analytics['orderGrowth']}%',
                          isPositive: analytics['orderGrowth'] > 0,
                          icon: Icons.receipt_long,
                          color: Colors.orange,
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                        
                        _buildOverviewCard(
                          context,
                          title: 'Platform Revenue',
                          value: _formatRupees(analytics['totalRevenue']),
                          change: '+${analytics['revenueGrowth']}%',
                          isPositive: analytics['revenueGrowth'] > 0,
                          icon: Icons.currency_rupee,
                          color: Colors.purple,
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                      ],
                    );
                  },
                  loading: () => _buildLoadingGrid(),
                  error: (error, stack) => _buildErrorGrid(error),
                ),
                loading: () => _buildLoadingGrid(),
                error: (error, stack) => _buildErrorGrid(error),
              ),
              loading: () => _buildLoadingGrid(),
              error: (error, stack) => _buildErrorGrid(error),
            ),
            
            const SizedBox(height: 24),
            
            // Revenue Chart
            Text(
              'Revenue Trend',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3),
            
            const SizedBox(height: 16),
            
            ordersAsync.when(
              data: (orders) {
                final revenueData = _calculateRevenueTrend(orders, _startDate);
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      _formatRupees(value),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                  if (value.toInt() < months.length) {
                                    return Text(
                                      months[value.toInt()],
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: revenueData,
                              isCurved: true,
                              color: theme.colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3);
              },
              loading: () => _buildLoadingChart(),
              error: (error, stack) => _buildErrorChart(error),
            ),
            
            const SizedBox(height: 24),
            
            // Top Performing Restaurants
            Text(
              'Top Performing Restaurants',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3),
            
            const SizedBox(height: 16),
            
            ordersAsync.when(
              data: (orders) => restaurantsAsync.when(
                data: (restaurants) {
                  final topRestaurants = _getTopPerformingRestaurants(orders, restaurants, _startDate);
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: topRestaurants.take(5).map((restaurant) => 
                          _buildTopRestaurantRow(
                            restaurant['name'] ?? 'Unknown',
                            restaurant['orderCount'] ?? 0,
                            _formatRupees(restaurant['revenue'] ?? 0),
                          )
                        ).toList(),
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3);
                },
                loading: () => _buildLoadingList(),
                error: (error, stack) => _buildErrorList(error),
              ),
              loading: () => _buildLoadingList(),
              error: (error, stack) => _buildErrorList(error),
            ),
            
            const SizedBox(height: 24),
            
            // Order Status Distribution
            Text(
              'Order Status Distribution',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3),
            
            const SizedBox(height: 16),
            
            ordersAsync.when(
              data: (orders) {
                final statusDistribution = _getOrderStatusDistribution(orders, _startDate);
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildOrderStatusGrid(statusDistribution),
                  ),
                ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.3);
              },
              loading: () => _buildLoadingStatusGrid(),
              error: (error, stack) => _buildErrorStatusGrid(error),
            ),
          ],
        ),
      ),
    );
  }

  // Analytics calculation methods
  Map<String, dynamic> _calculateAnalytics(
    List<OrderModel> orders, 
    List<UserModel> users, 
    List<RestaurantModel> restaurants,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // Filter data based on date range
    final filteredOrders = _filterOrdersByDate(orders, startDate, endDate);
    final previousPeriodOrders = _getPreviousPeriodOrders(orders, startDate, endDate);
    
    // Calculate totals
    final totalUsers = users.length;
    final activeRestaurants = restaurants.where((r) => r.isOpen && r.isApproved).length;
    final totalOrders = filteredOrders.length;
    final totalRevenue = filteredOrders
        .where((order) => order.status == OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.total);

    // Calculate growth percentages
    final previousUsers = (users.length * 0.9).round();
    final previousRestaurants = (restaurants.length * 0.9).round();
    final previousOrderCount = previousPeriodOrders.length;
    final previousRevenue = previousPeriodOrders
        .where((order) => order.status == OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.total);

    final userGrowth = previousUsers > 0 ? ((totalUsers - previousUsers) / previousUsers * 100).round() : 0;
    final restaurantGrowth = previousRestaurants > 0 ? ((activeRestaurants - previousRestaurants) / previousRestaurants * 100).round() : 0;
    final orderGrowth = previousOrderCount > 0 ? ((totalOrders - previousOrderCount) / previousOrderCount * 100).round() : 0;
    final revenueGrowth = previousRevenue > 0 ? ((totalRevenue - previousRevenue) / previousRevenue * 100).round() : 0;

    return {
      'totalUsers': totalUsers,
      'activeRestaurants': activeRestaurants,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'userGrowth': userGrowth,
      'restaurantGrowth': restaurantGrowth,
      'orderGrowth': orderGrowth,
      'revenueGrowth': revenueGrowth,
    };
  }

  List<OrderModel> _filterOrdersByDate(List<OrderModel> orders, DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return orders;
    
    return orders.where((order) {
      final orderDate = order.createdAt;
      if (startDate != null && orderDate.isBefore(startDate)) return false;
      if (endDate != null && orderDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  List<OrderModel> _getPreviousPeriodOrders(List<OrderModel> orders, DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return [];
    
    final duration = endDate.difference(startDate);
    final previousStartDate = startDate.subtract(duration);
    final previousEndDate = startDate;
    
    return _filterOrdersByDate(orders, previousStartDate, previousEndDate);
  }

  List<FlSpot> _calculateRevenueTrend(List<OrderModel> orders, DateTime? startDate) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    
    return months.asMap().entries.map((entry) {
      final month = entry.value;
      final nextMonth = DateTime(month.year, month.month + 1);
      
      final monthlyRevenue = orders
          .where((order) => 
            order.createdAt.isAfter(month) && 
            order.createdAt.isBefore(nextMonth) &&
            order.status == OrderStatus.delivered)
          .fold(0.0, (sum, order) => sum + order.total);
      
      return FlSpot(entry.key.toDouble(), monthlyRevenue);
    }).toList();
  }

  List<Map<String, dynamic>> _getTopPerformingRestaurants(
    List<OrderModel> orders, 
    List<RestaurantModel> restaurants,
    DateTime? startDate,
  ) {
    final restaurantPerformance = <String, Map<String, dynamic>>{};
    
    for (final restaurant in restaurants) {
      final restaurantOrders = orders.where((order) => 
        order.restaurantId == restaurant.id &&
        (startDate == null || order.createdAt.isAfter(startDate)) &&
        order.status == OrderStatus.delivered
      ).toList();
      
      final revenue = restaurantOrders.fold(0.0, (sum, order) => sum + order.total);
      
      restaurantPerformance[restaurant.id] = {
        'name': restaurant.name,
        'orderCount': restaurantOrders.length,
        'revenue': revenue,
      };
    }
    
    return restaurantPerformance.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
  }

  List<Map<String, dynamic>> _getOrderStatusDistribution(List<OrderModel> orders, DateTime? startDate) {
    final filteredOrders = _filterOrdersByDate(orders, startDate, null);
    final totalOrders = filteredOrders.length;
    
    if (totalOrders == 0) return [];
    
    final statusCounts = <OrderStatus, int>{};
    for (final order in filteredOrders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
    
    final statusColors = {
      OrderStatus.delivered: Colors.green,
      OrderStatus.confirmed: Colors.orange,
      OrderStatus.pending: Colors.blue,
      OrderStatus.cancelled: Colors.red,
      OrderStatus.outForDelivery: Colors.purple,
    };
    
    final statusLabels = {
      OrderStatus.delivered: 'Delivered',
      OrderStatus.confirmed: 'Preparing',
      OrderStatus.pending: 'Pending',
      OrderStatus.cancelled: 'Cancelled',
      OrderStatus.outForDelivery: 'Out for Delivery',
    };
    
    return statusCounts.entries.map((entry) {
      final percentage = (entry.value / totalOrders * 100).round();
      return {
        'status': statusLabels[entry.key] ?? entry.key.toString().split('.').last,
        'value': entry.value.toDouble(),
        'percentage': percentage,
        'color': statusColors[entry.key] ?? Colors.grey,
      };
    }).toList();
  }

  // UI Components
  Widget _buildOverviewCard(
    BuildContext context, {
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        change,
                        style: TextStyle(
                          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRestaurantRow(String name, int orders, String revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$orders orders',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            revenue,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusGrid(List<Map<String, dynamic>> statusData) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: statusData.map((status) => 
        Container(
          decoration: BoxDecoration(
            color: status['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: status['color'].withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${status['value'].toInt()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: status['color'],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status['status'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '${status['percentage']}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        )
      ).toList(),
    );
  }

  // Loading and error states
  Widget _buildLoadingGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: List.generate(4, (index) => 
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorGrid(dynamic error) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: List.generate(4, (index) => 
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorChart(dynamic error) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load chart',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(5, (index) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorList(dynamic error) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading data',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStatusGrid() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: List.generate(4, (index) => 
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorStatusGrid(dynamic error) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading status data',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Additional providers needed
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList());
});

final allRestaurantsProvider = StreamProvider<List<RestaurantModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('restaurants')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList());
});