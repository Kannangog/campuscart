// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/menu_provider.dart';
import '../../models/menu_item_model.dart';

class MenuDialogState {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController specialOfferController;
  String selectedCategory;
  bool isVegetarian;
  bool isVegan;
  bool isSpicy;
  bool isTodaysSpecial;
  bool hasSpecialOffer;
  String imageUrl;
  File? selectedImage;
  bool isUploading;

  MenuDialogState({
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.specialOfferController,
    this.selectedCategory = 'Main Course',
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

  @override
  void initState() {
    super.initState();
    _state = MenuDialogState(
      nameController: TextEditingController(text: widget.item?.name ?? ''),
      descriptionController: TextEditingController(text: widget.item?.description ?? ''),
      priceController: TextEditingController(text: widget.item?.price.toString() ?? ''),
      specialOfferController: TextEditingController(
        text: widget.item?.specialOfferPrice?.toString() ?? '',
      ),
      selectedCategory: widget.item?.category ?? 'Main Course',
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

  void _updateState(void Function() updateFn) {
    setState(updateFn);
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
                        _updateState(() {
                          _state.hasSpecialOffer = value ?? false;
                        });
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
                items: ['Appetizers', 'Main Course', 'Desserts', 'Beverages'].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  _updateState(() {
                    _state.selectedCategory = value!;
                  });
                },
                dropdownColor: lightGreenTheme.colorScheme.surfaceVariant,
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
                        _updateState(() {
                          _state.isVegetarian = value;
                          if (value) _state.isVegan = false;
                        });
                      },
                      backgroundColor: lightGreenTheme.colorScheme.surfaceVariant,
                      selectedColor: Colors.lightGreen[700],
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
                        _updateState(() {
                          _state.isVegetarian = !value;
                          if (value) _state.isVegan = false;
                        });
                      },
                      backgroundColor: lightGreenTheme.colorScheme.surfaceVariant,
                      selectedColor: Colors.brown,
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
                      _updateState(() {
                        _state.isVegan = value;
                        if (value) _state.isVegetarian = true;
                      });
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
                      _updateState(() {
                        _state.isSpicy = value;
                      });
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
                  _updateState(() {
                    _state.isTodaysSpecial = value ?? false;
                  });
                },
                activeColor: Colors.lightGreen[700],
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    _updateState(() {
                      _state.selectedImage = File(pickedFile.path);
                      _state.imageUrl = ''; // Clear the URL if we're using a new image
                    });
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
            onPressed: _state.isUploading ? null : () async {
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
                  _updateState(() {
                    _state.isUploading = true;
                  });
                  
                  // Upload to Firebase Storage
                  final storageRef = FirebaseStorage.instance
                      .ref()
                      .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                  
                  await storageRef.putFile(_state.selectedImage!);
                  finalImageUrl = await storageRef.getDownloadURL();
                  
                  _updateState(() {
                    _state.isUploading = false;
                  });
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
                    imageUrl: finalImageUrl.isEmpty 
                        ? 'https://via.placeholder.com/300x200?text=Food+Image'
                        : finalImageUrl,
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

                if (context.mounted) {
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
                _updateState(() {
                  _state.isUploading = false;
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