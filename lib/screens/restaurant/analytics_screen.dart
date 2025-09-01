// ignore_for_file: deprecated_member_use

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
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: analyticsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (analyticsData) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Cards
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideX(begin: -0.3),
                
                const SizedBox(height: 16),
                
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth > 600 
                      ? (constraints.maxWidth - 16) / 2 
                      : constraints.maxWidth;
                    
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _buildOverviewCard(
                            context,
                            title: 'Total Orders',
                            value: analyticsData.totalOrders.toString(),
                            change: analyticsData.ordersChange,
                            isPositive: analyticsData.ordersChange.contains('+'),
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildOverviewCard(
                            context,
                            title: 'Revenue',
                            value: '₹${analyticsData.revenue.toStringAsFixed(0)}',
                            change: analyticsData.revenueChange,
                            isPositive: analyticsData.revenueChange.contains('+'),
                            icon: Icons.currency_rupee,
                            color: Colors.green,
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildOverviewCard(
                            context,
                            title: 'Avg Order',
                            value: '₹${analyticsData.avgOrderValue.toStringAsFixed(2)}',
                            change: analyticsData.avgOrderChange,
                            isPositive: analyticsData.avgOrderChange.contains('+'),
                            icon: Icons.shopping_cart,
                            color: Colors.orange,
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildOverviewCard(
                            context,
                            title: 'Rating',
                            value: analyticsData.rating.toStringAsFixed(1),
                            change: analyticsData.ratingChange,
                            isPositive: analyticsData.ratingChange.contains('+'),
                            icon: Icons.star,
                            color: Colors.amber,
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Revenue Chart
                Text(
                  'Revenue Trend',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3),
                
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      '₹${value.toInt()}',
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
                                  if (value.toInt() < analyticsData.revenueLabels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        analyticsData.revenueLabels[value.toInt()],
                                        style: const TextStyle(fontSize: 10),
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
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: analyticsData.revenueData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value);
                              }).toList(),
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 32),
                
                // Top Selling Items
                Text(
                  'Top Selling Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3),
                
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (int i = 0; i < analyticsData.topItems.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
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
                
                const SizedBox(height: 32),
                
                // Order Status Distribution
                Text(
                  'Order Status Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3),
                
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
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
                                  default:
                                    color = Colors.grey;
                                }
                                
                                return PieChartSectionData(
                                  value: value.toDouble(),
                                  title: '$status\n$percentage%',
                                  color: color,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
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
                          spacing: 8,
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
                                break;
                              case 'Out for Delivery':
                                color = Colors.purple;
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
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: const TextStyle(fontSize: 12),
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
            ),
          );
        },
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                color: Colors.grey.shade600,
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
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}