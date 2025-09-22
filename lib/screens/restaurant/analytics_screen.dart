// analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'Last 7 Days', 'Last 30 Days'];

  @override
  void initState() {
    super.initState();
    // Fetch analytics data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).fetchAnalytics(_selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final analyticsState = ref.watch(analyticsProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view analytics')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedPeriod,
              onSelected: (value) {
                setState(() {
                  _selectedPeriod = value;
                });
                ref.read(analyticsProvider.notifier).fetchAnalytics(value);
              },
              itemBuilder: (context) => _periods.map((period) {
                return PopupMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedPeriod,
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.green[800]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: analyticsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading analytics',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(analyticsProvider.notifier).fetchAnalytics(_selectedPeriod);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        data: (analyticsData) {
          // Check if user has a restaurant
          if (!analyticsData.hasRestaurant) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Restaurant Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to create or join a restaurant to view analytics',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to restaurant creation/join screen
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateRestaurantScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Create Restaurant'),
                  ),
                ],
              ),
            );
          }

          // Check if there's any data to show
          final hasData = analyticsData.totalOrders > 0;
          
          if (!hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Data Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No orders found for the selected period: $_selectedPeriod',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Cards
                Text(
                  'Performance Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 1.8,
                  children: [
                    _buildOverviewCard(
                      context,
                      title: 'Total Orders',
                      value: analyticsData.totalOrders.toString(),
                      change: analyticsData.ordersChange,
                      isPositive: analyticsData.ordersChange.contains('+'),
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                    _buildOverviewCard(
                      context,
                      title: 'Revenue',
                      value: '₹${analyticsData.revenue.toStringAsFixed(0)}',
                      change: analyticsData.revenueChange,
                      isPositive: analyticsData.revenueChange.contains('+'),
                      icon: Icons.currency_rupee,
                      color: Colors.green,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                    _buildOverviewCard(
                      context,
                      title: 'Avg Order Value',
                      value: '₹${analyticsData.avgOrderValue.toStringAsFixed(2)}',
                      change: analyticsData.avgOrderChange,
                      isPositive: analyticsData.avgOrderChange.contains('+'),
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                    _buildOverviewCard(
                      context,
                      title: 'Customer Rating',
                      value: analyticsData.rating.toStringAsFixed(1),
                      change: analyticsData.ratingChange,
                      isPositive: analyticsData.ratingChange.contains('+'),
                      icon: Icons.star,
                      color: Colors.amber,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Revenue Chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Revenue Trend',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedPeriod,
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: analyticsData.revenueLabels.isEmpty ? 1 : (analyticsData.revenueLabels.length - 1).toDouble(),
                          minY: 0,
                          maxY: analyticsData.revenueData.isEmpty ? 1 : (analyticsData.revenueData.reduce((a, b) => a > b ? a : b) * 1.1),
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '₹${value.toInt()}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 24,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < analyticsData.revenueLabels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        analyticsData.revenueLabels[value.toInt()],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: analyticsData.revenueData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value);
                              }).toList(),
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 4,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 32),
                
                // Responsive two-column layout for smaller cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Desktop/tablet layout
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTopSellingItems(analyticsData),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildOrderStatusDistribution(analyticsData),
                          ),
                        ],
                      );
                    } else {
                      // Mobile layout
                      return Column(
                        children: [
                          _buildTopSellingItems(analyticsData),
                          const SizedBox(height: 24),
                          _buildOrderStatusDistribution(analyticsData),
                        ],
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSellingItems(analyticsData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Selling Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        
        const SizedBox(height: 16),
        
        analyticsData.topItems.isEmpty
            ? _buildEmptyState('No items sold yet')
            : Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int i = 0; i < analyticsData.topItems.length; i++) ...[
                        if (i > 0) const Divider(height: 1, thickness: 0.5),
                        _buildTopItemRow(
                          analyticsData.topItems[i].name, 
                          analyticsData.topItems[i].quantity, 
                          '₹${analyticsData.topItems[i].revenue.toStringAsFixed(0)}'
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildOrderStatusDistribution(analyticsData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        
        const SizedBox(height: 16),
        
        analyticsData.orderStatusDistribution.isEmpty
            ? _buildEmptyState('No orders with status data')
            : Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: analyticsData.orderStatusDistribution.entries.map((e) {
                              final status = e.key;
                              final value = e.value;
                              final percentage = (value / analyticsData.totalOrders * 100).round();
                              
                              Color color;
                              switch (status) {
                                case 'Delivered':
                                  color = Colors.green;
                                  break;
                                case 'Preparing':
                                  color = Colors.orange;
                                  break;
                                case 'Pending':
                                  color = Colors.blue;
                                  break;
                                case 'Out for Delivery':
                                  color = Colors.purple;
                                  break;
                                case 'Cancelled':
                                  color = Colors.red;
                                  break;
                                default:
                                  color = Colors.grey;
                              }
                              
                              return PieChartSectionData(
                                value: value.toDouble(),
                                title: '$percentage%',
                                color: color,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Legend for order status
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: analyticsData.orderStatusDistribution.entries.map((e) {
                          final status = e.key;
                          
                          Color color;
                          switch (status) {
                            case 'Delivered':
                              color = Colors.green;
                              break;
                            case 'Preparing':
                              color = Colors.orange;
                              break;
                            case 'Pending':
                              color = Colors.blue;
                            case 'Out for Delivery':
                              color = Colors.purple;
                              break;
                            case 'Cancelled':
                              color = Colors.red;
                              break;
                            default:
                              color = Colors.grey;
                          }
                          
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.3),
      ],
    );
  }

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
        padding: const EdgeInsets.all(20),
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
                    color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        change,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 12,
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
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItemRow(String name, int quantity, String revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$quantity sold',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              revenue,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}