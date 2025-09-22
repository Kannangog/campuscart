// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../providers/menu_provider.dart';
import '../../../../models/menu_item_model.dart';

// Use immutable state with freezed or manual implementation
class MenuDialogState {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController specialOfferController;
  final String selectedCategory;
  final bool isVegetarian;
  final bool isVegan;
  final bool isSpicy;
  final bool isTodaysSpecial;
  final bool hasSpecialOffer;
  final String imageUrl;
  final File? selectedImage;
  final bool isUploading;

  MenuDialogState({
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.specialOfferController,
    this.selectedCategory = 'briyani',
    this.isVegetarian = true,
    this.isVegan = false,
    this.isSpicy = false,
    this.isTodaysSpecial = false,
    this.hasSpecialOffer = false,
    this.imageUrl = '',
    this.selectedImage,
    this.isUploading = false,
  });

  MenuDialogState copyWith({
    TextEditingController? nameController,
    TextEditingController? descriptionController,
    TextEditingController? priceController,
    TextEditingController? specialOfferController,
    String? selectedCategory,
    bool? isVegetarian,
    bool? isVegan,
    bool? isSpicy,
    bool? isTodaysSpecial,
    bool? hasSpecialOffer,
    String? imageUrl,
    File? selectedImage,
    bool? isUploading,
  }) {
    return MenuDialogState(
      nameController: nameController ?? this.nameController,
      descriptionController: descriptionController ?? this.descriptionController,
      priceController: priceController ?? this.priceController,
      specialOfferController: specialOfferController ?? this.specialOfferController,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isSpicy: isSpicy ?? this.isSpicy,
      isTodaysSpecial: isTodaysSpecial ?? this.isTodaysSpecial,
      hasSpecialOffer: hasSpecialOffer ?? this.hasSpecialOffer,
      imageUrl: imageUrl ?? this.imageUrl,
      selectedImage: selectedImage ?? this.selectedImage,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    specialOfferController.dispose();
  }
}

// Category color mapping function
Map<String, Color> getCategoryColor(String category) {
  final colors = {
    'briyani': Colors.orange,
    'chinese': Colors.red,
    'curries': Colors.green,
    'rotis': Colors.amber,
    'meal': Colors.brown,
    'pizza': Colors.purple,
    'burger': Colors.deepOrange,
    'breakfast': Colors.blue,
    'desserts': Colors.pink,
  };
  
  final lowerCategory = category.toLowerCase();
  return {
    'color': colors[lowerCategory] ?? Colors.grey,
    'lightColor': colors[lowerCategory]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
  };
}

// Enhanced category mapping with better matching
String getCategoryDisplayName(String category) {
  final names = {
    'briyani': 'Briyani', 'biriyani': 'Briyani', 'biriani': 'Briyani', 'biryani': 'Briyani',
    'chinese': 'Chinese', 'china': 'Chinese',
    'curries': 'Curries', 'curry': 'Curries',
    'rotis': 'Rotis', 'roti': 'Rotis', 'naan': 'Rotis', 'bread': 'Rotis',
    'meal': 'Meal', 'thali': 'Meal', 'combo': 'Meal',
    'pizza': 'Pizza', 'pizzas': 'Pizza',
    'burger': 'Burger', 'burgers': 'Burger',
    'breakfast': 'Breakfast', 'morning': 'Breakfast',
    'desserts': 'Desserts', 'dessert': 'Desserts', 'sweet': 'Desserts',
  };
  
  String normalized = category.toLowerCase().trim();
  
  // Try exact match first
  if (names.containsKey(normalized)) {
    return names[normalized]!;
  }
  
  // Try partial match
  for (var key in names.keys) {
    if (normalized.contains(key) || key.contains(normalized)) {
      return names[key]!;
    }
  }
  
  // Fallback: capitalize first letter of each word
  return category.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

// Create a StatefulWidget to properly manage the state
class MenuDialog extends ConsumerStatefulWidget {
  final String restaurantId;
  final MenuItemModel? item;

  const MenuDialog({
    super.key,
    required this.restaurantId,
    this.item,
  });

  @override
  ConsumerState<MenuDialog> createState() => _MenuDialogState();
}

class _MenuDialogState extends ConsumerState<MenuDialog> {
  late MenuDialogState _state;
  final List<String> _categories = [
    'briyani',
    'chinese',
    'curries',
    'rotis',
    'meal',
    'pizza',
    'burger',
    'breakfast',
    'desserts'
  ];

  @override
  void initState() {
    super.initState();
    
    // Normalize the category from the item
    String initialCategory = widget.item?.category ?? 'briyani';
    String normalizedCategory = initialCategory.toLowerCase().trim();
    
    // Map to our standard categories
    final categoryMap = {
      'briyani': 'briyani', 'biriyani': 'briyani', 'biriani': 'briyani', 'biryani': 'briyani',
      'chinese': 'chinese', 'china': 'chinese',
      'curries': 'curries', 'curry': 'curries',
      'rotis': 'rotis', 'roti': 'rotis', 'naan': 'rotis', 'bread': 'rotis',
      'meal': 'meal', 'thali': 'meal', 'combo': 'meal',
      'pizza': 'pizza', 'pizzas': 'pizza',
      'burger': 'burger', 'burgers': 'burger',
      'breakfast': 'breakfast', 'morning': 'breakfast',
      'desserts': 'desserts', 'dessert': 'desserts', 'sweet': 'desserts',
    };
    
    // Find the matching category
    String finalCategory = 'briyani'; // default
    for (var key in categoryMap.keys) {
      if (normalizedCategory == key || normalizedCategory.contains(key)) {
        finalCategory = categoryMap[key]!;
        break;
      }
    }
    
    _state = MenuDialogState(
      nameController: TextEditingController(text: widget.item?.name ?? ''),
      descriptionController: TextEditingController(text: widget.item?.description ?? ''),
      priceController: TextEditingController(text: widget.item?.price.toString() ?? ''),
      specialOfferController: TextEditingController(
        text: widget.item?.specialOfferPrice?.toString() ?? '',
      ),
      selectedCategory: finalCategory,
      isVegetarian: widget.item?.isVegetarian ?? true,
      isVegan: widget.item?.isVegan ?? false,
      isSpicy: widget.item?.isSpicy ?? false,
      isTodaysSpecial: widget.item?.isTodaysSpecial ?? false,
      hasSpecialOffer: widget.item?.specialOfferPrice != null && widget.item!.specialOfferPrice! > 0,
      imageUrl: widget.item?.imageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  // Helper method to update state properly
  void _updateState(MenuDialogState newState) {
    if (mounted) {
      setState(() {
        _state = newState;
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        return await storageRef.getDownloadURL();
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Image upload error: $e');
      rethrow;
    }
  }

  Future<void> _saveMenuItem() async {
    if (_state.nameController.text.trim().isEmpty ||
        _state.descriptionController.text.trim().isEmpty ||
        _state.priceController.text.trim().isEmpty) {
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
      final price = double.parse(_state.priceController.text.trim());
      double? specialOfferPrice;
      
      if (_state.hasSpecialOffer && _state.specialOfferController.text.isNotEmpty) {
        specialOfferPrice = double.parse(_state.specialOfferController.text.trim());
        if (specialOfferPrice >= price) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Special offer price must be less than regular price'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }
      }
      
      String finalImageUrl = _state.imageUrl;
      
      // Upload new image if selected
      if (_state.selectedImage != null) {
        _updateState(_state.copyWith(isUploading: true));
        
        try {
          finalImageUrl = await _uploadImage(_state.selectedImage!) ?? _state.imageUrl;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          _updateState(_state.copyWith(isUploading: false));
          return;
        }
        
        _updateState(_state.copyWith(isUploading: false));
      }
      
      // Use default image if no image is provided
      if (finalImageUrl.isEmpty) {
        finalImageUrl = 'https://via.placeholder.com/300x200?text=Food+Image';
      }
      
      if (widget.item == null) {
        // Add new item
        final newItem = MenuItemModel(
          id: '', // Will be set by Firestore
          restaurantId: widget.restaurantId,
          name: _state.nameController.text.trim(),
          description: _state.descriptionController.text.trim(),
          price: price,
          specialOfferPrice: specialOfferPrice,
          imageUrl: finalImageUrl,
          category: _state.selectedCategory,
          isVegetarian: _state.isVegetarian,
          isVegan: _state.isVegan,
          isSpicy: _state.isSpicy,
          isTodaysSpecial: _state.isTodaysSpecial,
          isAvailable: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await ref.read(menuManagementProvider.notifier).addMenuItem(newItem);
      } else {
        // Update existing item
        await ref.read(menuManagementProvider.notifier).updateMenuItem(
          widget.item!.id,
          {
            'name': _state.nameController.text.trim(),
            'description': _state.descriptionController.text.trim(),
            'price': price,
            'specialOfferPrice': specialOfferPrice,
            'category': _state.selectedCategory,
            'isVegetarian': _state.isVegetarian,
            'isVegan': _state.isVegan,
            'isSpicy': _state.isSpicy,
            'isTodaysSpecial': _state.isTodaysSpecial,
            'imageUrl': finalImageUrl,
            'updatedAt': DateTime.now(),
          },
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null 
                ? 'Menu item added successfully!' 
                : 'Menu item updated successfully!'),
            backgroundColor: Colors.lightGreen[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      _updateState(_state.copyWith(isUploading: false));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightGreenTheme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.lightGreen[700],
        secondary: Colors.lightGreen[300],
        surface: Colors.lightGreen[50],
        onSurface: Colors.green[900],
        surfaceContainerHighest: Colors.lightGreen[100],
      ),
    );
    
    return Theme(
      data: lightGreenTheme,
      child: AlertDialog(
        title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item',
          style: TextStyle(color: lightGreenTheme.colorScheme.primary, fontWeight: FontWeight.bold)),
        backgroundColor: lightGreenTheme.colorScheme.surface,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Preview
              if (_state.imageUrl.isNotEmpty || _state.selectedImage != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: lightGreenTheme.colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _state.selectedImage != null
                        ? Image.file(_state.selectedImage!, fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: _state.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(color: lightGreenTheme.colorScheme.primary),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.fastfood,
                              color: lightGreenTheme.colorScheme.primary.withOpacity(0.5),
                              size: 50,
                            ),
                          ),
                  ),
                ).animate().fadeIn().scale(),

              TextField(
                controller: _state.nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: lightGreenTheme.colorScheme.onSurface),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _state.descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: lightGreenTheme.colorScheme.onSurface),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _state.priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  labelStyle: TextStyle(color: lightGreenTheme.colorScheme.onSurface),
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text('Special Offer',
                        style: TextStyle(color: lightGreenTheme.colorScheme.onSurface)),
                      value: _state.hasSpecialOffer,
                      onChanged: (value) {
                        _updateState(_state.copyWith(hasSpecialOffer: value ?? false));
                      },
                      activeColor: lightGreenTheme.colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (_state.hasSpecialOffer)
                    Expanded(
                      child: TextField(
                        controller: _state.specialOfferController,
                        decoration: InputDecoration(
                          labelText: 'Offer Price',
                          labelStyle: TextStyle(color: lightGreenTheme.colorScheme.onSurface),
                          prefixText: '₹',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _state.selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: lightGreenTheme.colorScheme.onSurface),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: lightGreenTheme.colorScheme.primary, width: 2),
                  ),
                ),
                items: _categories.map((category) {
                  final categoryColors = getCategoryColor(category);
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: categoryColors['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(getCategoryDisplayName(category)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateState(_state.copyWith(selectedCategory: value));
                  }
                },
                dropdownColor: lightGreenTheme.colorScheme.surfaceVariant,
              ),
              const SizedBox(height: 16),
              
              // Category Preview Tag
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightGreenTheme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Category Preview: ', 
                      style: TextStyle(
                        color: lightGreenTheme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      )),
                    _buildCategoryPreviewTag(_state.selectedCategory),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      label: Text('Vegetarian',
                        style: TextStyle(
                          color: _state.isVegetarian ? Colors.white : lightGreenTheme.colorScheme.onSurface,
                        )),
                      selected: _state.isVegetarian,
                      onSelected: (value) {
                        _updateState(_state.copyWith(
                          isVegetarian: value,
                          isVegan: value ? _state.isVegan : false,
                        ));
                      },
                      backgroundColor: lightGreenTheme.colorScheme.surfaceVariant,
                      selectedColor: Colors.green,
                      checkmarkColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChip(
                      label: Text('Non-Vegetarian',
                        style: TextStyle(
                          color: !_state.isVegetarian ? Colors.white : lightGreenTheme.colorScheme.onSurface,
                        )),
                      selected: !_state.isVegetarian,
                      onSelected: (value) {
                        _updateState(_state.copyWith(
                          isVegetarian: !value,
                          isVegan: false,
                        ));
                      },
                      backgroundColor: lightGreenTheme.colorScheme.surfaceVariant,
                      selectedColor: Colors.red,
                      checkmarkColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Vegan',
                      style: TextStyle(
                        color: _state.isVegan ? Colors.white : lightGreenTheme.colorScheme.onSurface,
                      )),
                    selected: _state.isVegan,
                    onSelected: (value) {
                      _updateState(_state.copyWith(
                        isVegan: value,
                        isVegetarian: value ? true : _state.isVegetarian,
                      ));
                    },
                    backgroundColor: lightGreenTheme.colorScheme.surfaceVariant,
                    selectedColor: Colors.lightGreen[700],
                    checkmarkColor: Colors.white,
                  ),
                  FilterChip(
                    label: Text('Spicy',
                      style: TextStyle(
                        color: _state.isSpicy ? Colors.white : lightGreenTheme.colorScheme.onSurface,
                      )),
                    selected: _state.isSpicy,
                    onSelected: (value) {
                      _updateState(_state.copyWith(isSpicy: value));
                    },
                    backgroundColor: lightGreenTheme.colorScheme.surfaceVariant,
                    selectedColor: Colors.orange[700],
                    checkmarkColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: Text('Today\'s Special',
                  style: TextStyle(color: lightGreenTheme.colorScheme.onSurface)),
                value: _state.isTodaysSpecial,
                onChanged: (value) {
                  _updateState(_state.copyWith(isTodaysSpecial: value ?? false));
                },
                activeColor: Colors.purple[700],
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    _updateState(_state.copyWith(
                      selectedImage: File(pickedFile.path),
                      imageUrl: '', // Clear the URL if we're using a new image
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightGreenTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.image),
                label: Text(_state.selectedImage != null || _state.imageUrl.isNotEmpty 
                    ? 'Change Image' : 'Add Image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', 
              style: TextStyle(color: lightGreenTheme.colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: _state.isUploading ? null : _saveMenuItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: lightGreenTheme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: _state.isUploading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(widget.item == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPreviewTag(String category) {
    final categoryColors = getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColors['lightColor'],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: categoryColors['color']!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: categoryColors['color'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            getCategoryDisplayName(category),
            style: TextStyle(
              color: categoryColors['color'],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

void showAddItemDialog(BuildContext context, WidgetRef ref, String restaurantId) {
  showDialog(
    context: context,
    builder: (context) => MenuDialog(restaurantId: restaurantId),
  );
}

void showEditItemDialog(BuildContext context, WidgetRef ref, MenuItemModel item) {
  showDialog(
    context: context,
    builder: (context) => MenuDialog(restaurantId: item.restaurantId, item: item),
  );
}

void showDeleteItemDialog(BuildContext context, WidgetRef ref, MenuItemModel item) {
  final lightGreenTheme = Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      primary: Colors.lightGreen[700],
      secondary: Colors.lightGreen[300],
      surface: Colors.lightGreen[50],
      onSurface: Colors.green[900],
      surfaceVariant: Colors.lightGreen[100],
    ),
  );
  
  showDialog(
    context: context,
    builder: (context) => Theme(
      data: lightGreenTheme,
      child: AlertDialog(
        title: const Text('Delete Menu Item',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        backgroundColor: lightGreenTheme.colorScheme.surface,
        content: Text('Are you sure you want to delete "${item.name}"?',
          style: TextStyle(color: lightGreenTheme.colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', 
              style: TextStyle(color: lightGreenTheme.colorScheme.onSurface)),
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
                      backgroundColor: Colors.lightGreen[700],
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
    ),
  );
}