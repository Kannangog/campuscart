// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/menu_item_model.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Appetizers', 'Main Course', 'Desserts', 'Beverages'];
  File? _selectedImage;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.lightGreen[50],
        body: Center(
          child: Text('Please login to manage menu',
            style: TextStyle(color: Colors.lightGreen[800])),
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
        final menuItems = ref.watch(menuItemsProvider(restaurant.id));
        
        return Scaffold(
          backgroundColor: Colors.lightGreen[50],
          body: Column(
            children: [
              // Category Filter
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.lightGreen[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: ChoiceChip(
                        label: Text(category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.lightGreen[800],
                            fontWeight: FontWeight.w500,
                          )),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.lightGreen[50],
                        selectedColor: Colors.lightGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),
              
              const SizedBox(height: 16),
              
              // Menu Items List
              Expanded(
                child: menuItems.when(
                  data: (items) {
                    final filteredItems = _selectedCategory == 'All'
                        ? items
                        : items.where((item) => item.category == _selectedCategory).toList();
                    
                    if (filteredItems.isEmpty) {
                      return _buildEmptyMenu(context, restaurant.id);
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildMenuItemCard(context, item, index);
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: Colors.lightGreen,
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.lightGreen[700]),
                        const SizedBox(height: 16),
                        Text('Error loading menu: $error',
                          style: TextStyle(color: Colors.lightGreen[800])),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(menuItemsProvider(restaurant.id)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddItemDialog(context, restaurant.id),
            backgroundColor: Colors.lightGreen,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Colors.lightGreen[50],
        body: Center(
          child: CircularProgressIndicator(color: Colors.lightGreen),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.lightGreen[50],
        body: Center(
          child: Text('Error: $error',
            style: TextStyle(color: Colors.lightGreen[800])),
        ),
      ),
    );
  }

  Widget _buildNoRestaurant(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 120,
              color: Colors.lightGreen[300],
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            Text(
              'No Restaurant Found',
              style: TextStyle(
                color: Colors.lightGreen[800],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 12),
            
            Text(
              'Please create a restaurant first to manage menu items',
              style: TextStyle(
                color: Colors.lightGreen[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMenu(BuildContext context, String restaurantId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 120,
            color: Colors.lightGreen[300],
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),
          
          Text(
            'No Menu Items',
            style: TextStyle(
              color: Colors.lightGreen[800],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          
          const SizedBox(height: 12),
          
          Text(
            'Add your first menu item to get started',
            style: TextStyle(
              color: Colors.lightGreen[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: () => _showAddItemDialog(context, restaurantId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Menu Item'),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(BuildContext context, MenuItemModel item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Item Image with enhanced UI
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.lightGreen[100],
                        child: Icon(Icons.fastfood, color: Colors.lightGreen[300]),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.lightGreen[100],
                        child: Icon(Icons.fastfood, color: Colors.lightGreen[300]),
                      ),
                    ),
                  ),
                  // Vegetarian/Non-vegetarian indicator
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isVegetarian ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.isVegetarian ? 'VEG' : 'NON-VEG',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.lightGreen[900],
                            ),
                          ),
                        ),
                        Switch(
                          value: item.isAvailable,
                          onChanged: (value) {
                            ref.read(menuManagementProvider.notifier)
                                .toggleItemAvailability(item.id, value);
                          },
                          activeColor: Colors.lightGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.lightGreen[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              color: Colors.lightGreen[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.isSpicy)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.local_fire_department, 
                                    size: 14, color: Colors.orange[800]),
                                const SizedBox(width: 2),
                                Text('Spicy',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 10,
                                  )),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.lightGreen[800],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _showEditItemDialog(context, item),
                              icon: Icon(Icons.edit, size: 22, color: Colors.lightGreen[700]),
                            ).animate().scale(duration: 200.ms),
                            IconButton(
                              onPressed: () => _showDeleteItemDialog(context, item),
                              icon: Icon(Icons.delete, size: 22, color: Colors.red[700]),
                            ).animate().scale(duration: 200.ms),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
     .fadeIn(delay: (index * 100).ms)
     .slideX(begin: 0.3)
     .then()
     .shake(delay: 200.ms, curve: Curves.easeOut);
  }

  void _showAddItemDialog(BuildContext context, String restaurantId) {
    _showItemDialog(context, restaurantId: restaurantId);
  }

  void _showEditItemDialog(BuildContext context, MenuItemModel item) {
    _showItemDialog(context, restaurantId: item.restaurantId, item: item);
  }

  void _showItemDialog(BuildContext context, {required String restaurantId, MenuItemModel? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    String selectedCategory = item?.category ?? 'Main Course';
    bool isVegetarian = item?.isVegetarian ?? true;
    bool isVegan = item?.isVegan ?? false;
    bool isSpicy = item?.isSpicy ?? false;
    String imageUrl = item?.imageUrl ?? '';
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'Add Menu Item' : 'Edit Menu Item',
            style: TextStyle(color: Colors.lightGreen[800])),
          backgroundColor: Colors.lightGreen[50],
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Preview
                if (imageUrl.isNotEmpty || selectedImage != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.lightGreen[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: selectedImage != null
                          ? Image.file(selectedImage!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(color: Colors.lightGreen),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.fastfood,
                                color: Colors.lightGreen[300],
                                size: 50,
                              ),
                            ),
                    ),
                  ).animate().fadeIn().scale(),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: TextStyle(color: Colors.lightGreen[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.lightGreen),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.lightGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.lightGreen[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.lightGreen),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.lightGreen, width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    labelStyle: TextStyle(color: Colors.lightGreen[700]),
                    prefixText: '₹',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.lightGreen),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.lightGreen, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: Colors.lightGreen[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.lightGreen),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.lightGreen, width: 2),
                    ),
                  ),
                  items: _categories.skip(1).map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                  dropdownColor: Colors.lightGreen[50],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text('Vegetarian',
                          style: TextStyle(
                            color: isVegetarian ? Colors.white : Colors.lightGreen[800],
                          )),
                        selected: isVegetarian,
                        onSelected: (value) {
                          setState(() {
                            isVegetarian = value;
                            if (value) isVegan = false;
                          });
                        },
                        backgroundColor: Colors.lightGreen[50],
                        selectedColor: Colors.green,
                        checkmarkColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: Text('Non-Vegetarian',
                          style: TextStyle(
                            color: !isVegetarian ? Colors.white : Colors.lightGreen[800],
                          )),
                        selected: !isVegetarian,
                        onSelected: (value) {
                          setState(() {
                            isVegetarian = !value;
                            if (value) isVegan = false;
                          });
                        },
                        backgroundColor: Colors.lightGreen[50],
                        selectedColor: Colors.red,
                        checkmarkColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: Text('Vegan',
                        style: TextStyle(
                          color: isVegan ? Colors.white : Colors.lightGreen[800],
                        )),
                      selected: isVegan,
                      onSelected: (value) {
                        setState(() {
                          isVegan = value;
                          if (value) isVegetarian = true;
                        });
                      },
                      backgroundColor: Colors.lightGreen[50],
                      selectedColor: Colors.green,
                      checkmarkColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('Spicy',
                        style: TextStyle(
                          color: isSpicy ? Colors.white : Colors.lightGreen[800],
                        )),
                      selected: isSpicy,
                      onSelected: (value) {
                        setState(() {
                          isSpicy = value;
                        });
                      },
                      backgroundColor: Colors.lightGreen[50],
                      selectedColor: Colors.orange,
                      checkmarkColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        selectedImage = File(pickedFile.path);
                        imageUrl = ''; // Clear the URL if we're using a new image
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(selectedImage != null || imageUrl.isNotEmpty 
                      ? 'Change Image' : 'Add Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', 
                style: TextStyle(color: Colors.lightGreen[800])),
            ),
            ElevatedButton(
              onPressed: _isUploading ? null : () async {
                if (nameController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }

                try {
                  final price = double.parse(priceController.text.trim());
                  
                  String finalImageUrl = imageUrl;
                  
                  // Upload new image if selected
                  if (selectedImage != null) {
                    setState(() {
                      _isUploading = true;
                    });
                    
                    // Upload to Firebase Storage
                    final storageRef = FirebaseStorage.instance
                        .ref()
                        .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    
                    await storageRef.putFile(selectedImage!);
                    finalImageUrl = await storageRef.getDownloadURL();
                    
                    setState(() {
                      _isUploading = false;
                    });
                  }
                  
                  if (item == null) {
                    // Add new item
                    final newItem = MenuItemModel(
                      id: '', // Will be set by Firestore
                      restaurantId: restaurantId,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      price: price,
                      imageUrl: finalImageUrl.isEmpty 
                          ? 'https://via.placeholder.com/300x200?text=Food+Image'
                          : finalImageUrl,
                      category: selectedCategory,
                      isVegetarian: isVegetarian,
                      isVegan: isVegan,
                      isSpicy: isSpicy,
                      isAvailable: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    
                    await ref.read(menuManagementProvider.notifier).addMenuItem(newItem);
                  } else {
                    // Update existing item
                    await ref.read(menuManagementProvider.notifier).updateMenuItem(
                      item.id,
                      {
                        'name': nameController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'price': price,
                        'category': selectedCategory,
                        'isVegetarian': isVegetarian,
                        'isVegan': isVegan,
                        'isSpicy': isSpicy,
                        'imageUrl': finalImageUrl,
                        'updatedAt': DateTime.now(),
                      },
                    );
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(item == null 
                            ? 'Menu item added successfully!' 
                            : 'Menu item updated successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() {
                    _isUploading = false;
                  });
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                foregroundColor: Colors.white,
              ),
              child: _isUploading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(item == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteItemDialog(BuildContext context, MenuItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Menu Item',
          style: TextStyle(color: Colors.lightGreen[800])),
        backgroundColor: Colors.lightGreen[50],
        content: Text('Are you sure you want to delete "${item.name}"?',
          style: TextStyle(color: Colors.lightGreen[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', 
              style: TextStyle(color: Colors.lightGreen[800])),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(menuManagementProvider.notifier).deleteMenuItem(item.id);
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Menu item deleted successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting item: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}