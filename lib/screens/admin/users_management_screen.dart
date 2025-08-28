import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Restaurants'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      body: Column(
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
                _buildUsersList(UserRole.user),
                _buildUsersList(UserRole.restaurant),
                _buildUsersList(UserRole.admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(UserRole? roleFilter) {
    // Mock data for demonstration
    final mockUsers = _getMockUsers().where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
      
      final matchesRole = roleFilter == null || user.role == roleFilter;
      
      return matchesSearch && matchesRole;
    }).toList();

    if (mockUsers.isEmpty) {
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
              'No users found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mockUsers.length,
      itemBuilder: (context, index) {
        final user = mockUsers[index];
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
            child: Icon(
              _getRoleIcon(user.role),
              color: _getRoleColor(user.role),
            ),
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
                  if (!user.isApproved && user.role == UserRole.restaurant)
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
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _showUserDetails(context, user),
                child: const Row(
                  children: [
                    Icon(Icons.info, size: 20),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
              if (user.role == UserRole.restaurant && !user.isApproved)
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
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.3);
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Colors.blue;
      case UserRole.restaurant:
        return Colors.green;
      case UserRole.admin:
        return Colors.purple;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Icons.person;
      case UserRole.restaurant:
        return Icons.restaurant;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Customer';
      case UserRole.restaurant:
        return 'Restaurant';
      case UserRole.admin:
        return 'Admin';
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
            width: 80,
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
        content: Text('Are you sure you want to ban "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name} has been banned'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  List<UserModel> _getMockUsers() {
    return [
      UserModel(
        id: '1',
        email: 'john.doe@example.com',
        name: 'John Doe',
        role: UserRole.user,
        isApproved: true,
        phoneNumber: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      UserModel(
        id: '2',
        email: 'pizza.palace@example.com',
        name: 'Pizza Palace',
        role: UserRole.restaurant,
        isApproved: true,
        phoneNumber: '+1234567891',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      UserModel(
        id: '3',
        email: 'admin@foodhub.com',
        name: 'Admin User',
        role: UserRole.admin,
        isApproved: true,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      UserModel(
        id: '4',
        email: 'jane.smith@example.com',
        name: 'Jane Smith',
        role: UserRole.user,
        isApproved: true,
        phoneNumber: '+1234567892',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      UserModel(
        id: '5',
        email: 'burger.king@example.com',
        name: 'Burger King',
        role: UserRole.restaurant,
        isApproved: false,
        phoneNumber: '+1234567893',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}