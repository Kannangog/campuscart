// ignore_for_file: deprecated_member_use

import 'package:campuscart/providers/order_provider/firestore_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../models/restaurant_model.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUsers = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Customers'),
            Tab(text: 'Restaurants'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      body: allUsers.when(
        data: (users) => _buildContent(users),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildContent(List<UserModel> users) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ).animate().fadeIn().slideY(begin: -0.3),

        // Users List
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersList(users, UserRole.user),
              _buildUsersList(users, UserRole.restaurantOwner),
              _buildUsersList(users, UserRole.admin),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList(List<UserModel> users, UserRole roleFilter) {
    final filteredUsers = users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
      
      final matchesRole = user.role == roleFilter;
      
      return matchesSearch && matchesRole;
    }).toList();

    if (filteredUsers.isEmpty) {
      return _buildEmptyState(roleFilter);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(context, user, index);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
            backgroundImage: user.profileImageUrl != null 
                ? NetworkImage(user.profileImageUrl!) 
                : null,
            child: user.profileImageUrl == null
                ? Icon(
                    _getRoleIcon(user.role),
                    color: _getRoleColor(user.role),
                  )
                : null,
          ),
          title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleText(user.role),
                      style: TextStyle(
                        color: _getRoleColor(user.role),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!user.isApproved && user.role == UserRole.restaurantOwner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (user.role == UserRole.restaurantOwner && user.isApproved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Approved',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Joined ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => _buildPopupMenuItems(context, user),
          ),
          onTap: () {
            if (user.role == UserRole.restaurantOwner) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantDetailsScreen(userId: user.id),
                ),
              );
            } else {
              _showUserDetails(context, user);
            }
          },
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.3);
  }

  List<PopupMenuItem> _buildPopupMenuItems(BuildContext context, UserModel user) {
    return [
      PopupMenuItem(
        onTap: () {
          if (user.role == UserRole.restaurantOwner) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailsScreen(userId: user.id),
              ),
            );
          } else {
            _showUserDetails(context, user);
          }
        },
        child: const Row(
          children: [
            Icon(Icons.info, size: 20),
            SizedBox(width: 8),
            Text('View Details'),
          ],
        ),
      ),
      if (user.role == UserRole.restaurantOwner && !user.isApproved)
        PopupMenuItem(
          onTap: () => _approveUser(context, user),
          child: const Row(
            children: [
              Icon(Icons.check, size: 20, color: Colors.green),
              SizedBox(width: 8),
              Text('Approve', style: TextStyle(color: Colors.green)),
            ],
          ),
        ),
      PopupMenuItem(
        onTap: () => _showBanUserDialog(context, user),
        child: const Row(
          children: [
            Icon(Icons.block, size: 20, color: Colors.red),
            SizedBox(width: 8),
            Text('Ban User', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
      if (user.role != UserRole.admin)
        PopupMenuItem(
          onTap: () => _showDeleteUserDialog(context, user),
          child: const Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete User', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
    ];
  }

  Widget _buildEmptyState(UserRole role) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_getRoleText(role).toLowerCase()}s found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateMessage(role),
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'No customer accounts found';
      case UserRole.restaurantOwner:
        return 'No restaurant accounts found';
      case UserRole.admin:
        return 'No admin accounts found';
      default:
        return 'No users found';
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              title: Container(
                width: 150,
                height: 16,
                color: Colors.grey.shade300,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200,
                    height: 14,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 20,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading users',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(allUsersProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Colors.blue;
      case UserRole.restaurantOwner:
        return Colors.green;
      case UserRole.admin:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Icons.person;
      case UserRole.restaurantOwner:
        return Icons.restaurant;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Customer';
      case UserRole.restaurantOwner:
        return 'Restaurant';
      case UserRole.admin:
        return 'Admin';
      default:
        return 'User';
    }
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Role', _getRoleText(user.role)),
            _buildDetailRow('Status', user.isApproved ? 'Approved' : 'Pending'),
            if (user.phoneNumber != null)
              _buildDetailRow('Phone', user.phoneNumber!),
            _buildDetailRow('Joined', DateFormat('MMM dd, yyyy').format(user.createdAt)),
            _buildDetailRow('Last Updated', DateFormat('MMM dd, yyyy').format(user.updatedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _approveUser(BuildContext context, UserModel user) async {
    try {
      await ref.read(authProvider.notifier).approveRestaurant(user.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} has been approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBanUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: Text('Are you sure you want to ban "${user.name}"? This will prevent them from accessing the platform.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _banUser(context, user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ban User'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to permanently delete "${user.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteUser(context, user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser(BuildContext context, UserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'isBanned': true,
        'bannedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} has been banned successfully.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error banning user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(BuildContext context, UserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} has been deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Restaurant Details Screen with Analytics
class RestaurantDetailsScreen extends ConsumerStatefulWidget {
  final String userId;

  const RestaurantDetailsScreen({super.key, required this.userId});

  @override
  ConsumerState<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends ConsumerState<RestaurantDetailsScreen> {
  String _selectedFilter = 'Last 30 Days';
  final List<String> _filters = ['Today', 'Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'All Time'];
  RestaurantModel? _restaurant;
  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    try {
      // Get restaurant by owner ID
      final restaurantQuery = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('ownerId', isEqualTo: widget.userId)
          .get();

      if (restaurantQuery.docs.isNotEmpty) {
        setState(() {
          _restaurant = RestaurantModel.fromFirestore(restaurantQuery.docs.first);
        });
      }

      // Get restaurant orders
      final orders = ref.read(allOrdersProvider).value ?? [];
      setState(() {
        _orders = orders.where((order) => order.restaurantId == _restaurant?.id).toList();
      });
    } catch (e) {
      print('Error loading restaurant data: $e');
    }
  }

  Map<String, dynamic> _calculateAnalytics() {
    final filteredOrders = _filterOrdersByDate(_orders);
    final deliveredOrders = filteredOrders.where((order) => order.status == OrderStatus.delivered).toList();
    
    double totalRevenue = deliveredOrders.fold(0.0, (sum, order) => sum + order.total);
    double platformCommission = deliveredOrders.length * 5.0; // ₹5 per order
    double restaurantEarnings = totalRevenue - platformCommission;

    return {
      'totalOrders': filteredOrders.length,
      'deliveredOrders': deliveredOrders.length,
      'pendingOrders': filteredOrders.where((order) => order.status == OrderStatus.pending).length,
      'cancelledOrders': filteredOrders.where((order) => order.status == OrderStatus.cancelled).length,
      'totalRevenue': totalRevenue,
      'platformCommission': platformCommission,
      'restaurantEarnings': restaurantEarnings,
      'completionRate': filteredOrders.isNotEmpty ? (deliveredOrders.length / filteredOrders.length * 100) : 0,
    };
  }

  List<OrderModel> _filterOrdersByDate(List<OrderModel> orders) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        final today = DateTime(now.year, now.month, now.day);
        return orders.where((order) => order.createdAt.isAfter(today)).toList();
      case 'Last 7 Days':
        final weekAgo = now.subtract(const Duration(days: 7));
        return orders.where((order) => order.createdAt.isAfter(weekAgo)).toList();
      case 'Last 30 Days':
        final monthAgo = now.subtract(const Duration(days: 30));
        return orders.where((order) => order.createdAt.isAfter(monthAgo)).toList();
      case 'Last 3 Months':
        final threeMonthsAgo = now.subtract(const Duration(days: 90));
        return orders.where((order) => order.createdAt.isAfter(threeMonthsAgo)).toList();
      case 'All Time':
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final analytics = _calculateAnalytics();

    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurant!.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filters.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedFilter),
                  const Icon(Icons.arrow_drop_down),
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
            // Restaurant Basic Info
            _buildRestaurantInfo(),
            const SizedBox(height: 24),
            
            // Analytics Overview
            _buildAnalyticsOverview(analytics),
            const SizedBox(height: 24),
            
            // Order Statistics
            _buildOrderStatistics(analytics),
            const SizedBox(height: 24),
            
            // Revenue Breakdown
            _buildRevenueBreakdown(analytics),
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', _restaurant!.name),
            _buildInfoRow('Description', _restaurant!.description),
            _buildInfoRow('Address', _restaurant!.address),
            _buildInfoRow('Phone', _restaurant!.phoneNumber),
            _buildInfoRow('Email', _restaurant!.email),
            _buildInfoRow('Categories', _restaurant!.categories.join(', ')),
            _buildInfoRow('Delivery Fee', '₹${_restaurant!.deliveryFee.toStringAsFixed(2)}'),
            _buildInfoRow('Minimum Order', '₹${_restaurant!.minimumOrder.toStringAsFixed(2)}'),
            _buildInfoRow('Status', _restaurant!.isApproved ? 'Approved' : 'Pending Approval'),
            _buildInfoRow('Created', DateFormat('MMM dd, yyyy').format(_restaurant!.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverview(Map<String, dynamic> analytics) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview - $_selectedFilter',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Orders',
                  '${analytics['totalOrders']}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Delivered',
                  '${analytics['deliveredOrders']}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Completion Rate',
                  '${analytics['completionRate'].toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Total Revenue',
                  '₹${analytics['totalRevenue'].toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatistics(Map<String, dynamic> analytics) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOrderStatRow('Pending Orders', '${analytics['pendingOrders']}', Colors.orange),
            _buildOrderStatRow('Delivered Orders', '${analytics['deliveredOrders']}', Colors.green),
            _buildOrderStatRow('Cancelled Orders', '${analytics['cancelledOrders']}', Colors.red),
            _buildOrderStatRow('Total Orders', '${analytics['totalOrders']}', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(Map<String, dynamic> analytics) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRevenueRow('Total Revenue', '₹${analytics['totalRevenue'].toStringAsFixed(2)}', Colors.green),
            _buildRevenueRow('Platform Commission (₹5/order)', '₹${analytics['platformCommission'].toStringAsFixed(2)}', Colors.orange),
            _buildRevenueRow('Restaurant Earnings', '₹${analytics['restaurantEarnings'].toStringAsFixed(2)}', Colors.blue),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: ₹5 platform commission is charged per delivered order',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showBanRestaurantDialog,
            icon: const Icon(Icons.block),
            label: const Text('Ban Restaurant'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showDeleteRestaurantDialog,
            icon: const Icon(Icons.delete),
            label: const Text('Delete Restaurant'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showBanRestaurantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban Restaurant'),
        content: Text('Are you sure you want to ban "${_restaurant!.name}"? This will prevent the restaurant from operating on the platform.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _banRestaurant();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ban Restaurant'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRestaurantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content: Text('Are you sure you want to permanently delete "${_restaurant!.name}"? This action cannot be undone and will remove all restaurant data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRestaurant();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Restaurant'),
          ),
        ],
      ),
    );
  }

  Future<void> _banRestaurant() async {
    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(_restaurant!.id).update({
        'isBanned': true,
        'bannedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_restaurant!.name} has been banned successfully.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error banning restaurant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRestaurant() async {
    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(_restaurant!.id).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_restaurant!.name} has been deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting restaurant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Provider for all users
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList());
});