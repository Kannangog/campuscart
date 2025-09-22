// ignore_for_file: deprecated_member_use

import 'package:campuscart/models/menu_item_model.dart';
import 'package:campuscart/screens/restaurant/menu_management/menu_dialogs.dart';
import 'package:campuscart/screens/restaurant/menu_management/menu_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../providers/restaurant_provider.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Veg', 'Non Veg', 'Briyani', 'Curries', 'Rotis', 'Meal', 'Pizza', 'Burger', 'Breakfast', 'Desserts'];
  bool _showTodaysSpecialOnly = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Safe method to handle menu operations with disposed state check
  Future<void> _safeMenuOperation(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      // Check if the error is due to disposed provider
      if (e is StateError && e.toString().contains('disposed')) {
        // Ignore disposal errors as the screen is closing
        return;
      }
      // Re-throw other errors to be handled by the UI
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.lightGreen[50],
        body: Center(
          child: Text('Please login to manage menu',
            style: TextStyle(
              color: Colors.lightGreen[800],
              fontSize: 16,
            )),
        ),
      );
    }

    final restaurants = ref.watch(restaurantsByOwnerProvider(user.uid));
    
    return restaurants.when(
      data: (restaurantList) {
        if (restaurantList.isEmpty) {
          return _buildNoRestaurant(context);
        }
        
        final restaurant = restaurantList.first;
        // Use allMenuItemsProvider to see ALL items
        final menuItems = ref.watch(allMenuItemsProvider(restaurant.id));
        
        return Scaffold(
          backgroundColor: Colors.lightGreen[50],
          body: Column(
            children: [
              // Search Bar with improved styling
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: Icon(Icons.search, color: Colors.lightGreen[700]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.lightGreen[700]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.lightGreen, width: 1.5),
                    ),
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              
              // Filter section with improved layout
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Today's Special Toggle and Add Item button
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 400) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Today's Special Toggle
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.lightGreen[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Today\'s Special Only',
                                      style: TextStyle(
                                        color: Colors.lightGreen[800],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      )),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: _showTodaysSpecialOnly,
                                      onChanged: (value) {
                                        setState(() {
                                          _showTodaysSpecialOnly = value;
                                        });
                                      },
                                      activeColor: Colors.lightGreen,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Add Item Button
                              ElevatedButton.icon(
                                onPressed: () => showAddItemDialog(context, ref, restaurant.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Item', style: TextStyle(fontSize: 14)),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              // Today's Special Toggle
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.lightGreen[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Today\'s Special Only',
                                      style: TextStyle(
                                        color: Colors.lightGreen[800],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      )),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: _showTodaysSpecialOnly,
                                      onChanged: (value) {
                                        setState(() {
                                          _showTodaysSpecialOnly = value;
                                        });
                                      },
                                      activeColor: Colors.lightGreen,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Add Item Button
                              ElevatedButton.icon(
                                onPressed: () => showAddItemDialog(context, ref, restaurant.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Item', style: TextStyle(fontSize: 14)),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category Filter
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('Filter by Category:',
                            style: TextStyle(
                              color: Colors.lightGreen[800],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            )),
                        ),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category;
                              
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.lightGreen[800],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    )),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  backgroundColor: Colors.lightGreen[50],
                                  selectedColor: Colors.lightGreen,
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? Colors.lightGreen : Colors.lightGreen[100]!,
                                    width: 1
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Menu Items List with improved empty states
              Expanded(
                child: menuItems.when(
                  data: (items) {
                    // Apply all filters
                    var filteredItems = items;
                    
                    // Filter by search query
                    if (_searchQuery.isNotEmpty) {
                      filteredItems = filteredItems.where((item) =>
                        item.name.toLowerCase().contains(_searchQuery) ||
                        item.description.toLowerCase().contains(_searchQuery) ||
                        item.category.toLowerCase().contains(_searchQuery)
                      ).toList();
                    }
                    
                    // Filter by today's special
                    if (_showTodaysSpecialOnly) {
                      filteredItems = filteredItems.where((item) => item.isTodaysSpecial).toList();
                    }
                    
                    // Filter by category - FIXED: Proper category filtering
                    if (_selectedCategory != 'All') {
                      // Handle special cases for Veg/Non Veg filtering
                      if (_selectedCategory == 'Veg') {
                        filteredItems = filteredItems.where((item) => item.isVegetarian).toList();
                      } else if (_selectedCategory == 'Non Veg') {
                        filteredItems = filteredItems.where((item) => !item.isVegetarian).toList();
                      } else {
                        // Filter by regular category
                        filteredItems = filteredItems.where((item) => 
                          item.category.toLowerCase() == _selectedCategory.toLowerCase()
                        ).toList();
                      }
                    }
                    
                    if (filteredItems.isEmpty) {
                      return _buildEmptyMenu(context, restaurant.id, ref);
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: MenuItemCard(
                            item: item,
                            index: index,
                            onToggleAvailability: (value) {
                              _safeMenuOperation(() => ref.read(menuManagementProvider.notifier)
                                  .toggleItemAvailability(item.id, value));
                            },
                            onToggleTodaysSpecial: () {
                              _safeMenuOperation(() => ref.read(menuManagementProvider.notifier)
                                  .toggleTodaysSpecial(item.id, !item.isTodaysSpecial));
                            },
                            onEdit: () => showEditItemDialog(context, ref, item),
                            onDelete: () => _showDeleteItemDialogWithSafety(context, ref, item),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.lightGreen,
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.lightGreen[700]),
                          const SizedBox(height: 16),
                          Text('Error loading menu items',
                            style: TextStyle(
                              color: Colors.lightGreen[800],
                              fontSize: 16,
                              fontWeight: FontWeight.w500
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text('Please try again later',
                            style: TextStyle(color: Colors.lightGreen[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => ref.refresh(allMenuItemsProvider(restaurant.id)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Colors.lightGreen[50],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.lightGreen),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.lightGreen[50],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.lightGreen[700]),
                const SizedBox(height: 16),
                Text('Error loading restaurant data',
                  style: TextStyle(
                    color: Colors.lightGreen[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Please try again later',
                  style: TextStyle(color: Colors.lightGreen[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Safe delete dialog method
  Future<void> _showDeleteItemDialogWithSafety(BuildContext context, WidgetRef ref, MenuItemModel item) async {
    try {
      showDeleteItemDialog(context, ref, item);
    } catch (e) {
      if (e is StateError && e.toString().contains('disposed')) {
        return;
      }
      // Show error message for other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildNoRestaurant(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 100,
                color: Colors.lightGreen[300],
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'No Restaurant Found',
                style: TextStyle(
                  color: Colors.lightGreen[800],
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'You need to create a restaurant first before you can manage menu items',
                style: TextStyle(
                  color: Colors.lightGreen[600],
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMenu(BuildContext context, String restaurantId, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood_outlined,
              size: 100,
              color: Colors.lightGreen[300],
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Menu Items',
              style: TextStyle(
                color: Colors.lightGreen[800],
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'No items found for "$_searchQuery"'
                    : _showTodaysSpecialOnly
                        ? 'No items marked as "Today\'s Special"'
                        : _selectedCategory != 'All'
                            ? 'No items found in "$_selectedCategory" category'
                            : 'Add your first menu item to get started',
                style: TextStyle(
                  color: Colors.lightGreen[600],
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (_searchQuery.isEmpty && !_showTodaysSpecialOnly && _selectedCategory == 'All')
              ElevatedButton(
                onPressed: () => showAddItemDialog(context, ref, restaurantId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text('Add Your First Item'),
              ),
          ],
        ),
      ),
    );
  }
}