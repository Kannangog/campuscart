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

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    specialOfferController.dispose();
  }
}

void showAddItemDialog(BuildContext context, WidgetRef ref, String restaurantId) {
  showItemDialog(
    context, 
    ref, 
    restaurantId: restaurantId,
  );
}

void showEditItemDialog(BuildContext context, WidgetRef ref, MenuItemModel item) {
  showItemDialog(
    context, 
    ref, 
    restaurantId: item.restaurantId, 
    item: item,
  );
}

void showItemDialog(
  BuildContext context, 
  WidgetRef ref, 
  {required String restaurantId, 
  MenuItemModel? item}
) {
  final state = MenuDialogState(
    nameController: TextEditingController(text: item?.name ?? ''),
    descriptionController: TextEditingController(text: item?.description ?? ''),
    priceController: TextEditingController(text: item?.price.toString() ?? ''),
    specialOfferController: TextEditingController(
      text: item?.specialOfferPrice?.toString() ?? '',
    ),
    selectedCategory: item?.category ?? 'Main Course',
    isVegetarian: item?.isVegetarian ?? true,
    isVegan: item?.isVegan ?? false,
    isSpicy: item?.isSpicy ?? false,
    isTodaysSpecial: item?.isTodaysSpecial ?? false,
    hasSpecialOffer: item?.specialOfferPrice != null && item!.specialOfferPrice! > 0,
    imageUrl: item?.imageUrl ?? '',
  );

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
              if (state.imageUrl.isNotEmpty || state.selectedImage != null)
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
                    child: state.selectedImage != null
                        ? Image.file(state.selectedImage!, fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: state.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
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
                controller: state.nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: Colors.lightGreen[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightGreen),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: state.descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.lightGreen[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightGreen),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: state.priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  labelStyle: TextStyle(color: Colors.lightGreen[700]),
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightGreen),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
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
                        style: TextStyle(color: Colors.lightGreen[700])),
                      value: state.hasSpecialOffer,
                      onChanged: (value) {
                        setState(() {
                          state.hasSpecialOffer = value ?? false;
                        });
                      },
                      activeColor: Colors.lightGreen,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (state.hasSpecialOffer)
                    Expanded(
                      child: TextField(
                        controller: state.specialOfferController,
                        decoration: InputDecoration(
                          labelText: 'Offer Price',
                          labelStyle: TextStyle(color: Colors.lightGreen[700]),
                          prefixText: '₹',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.lightGreen),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: state.selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.lightGreen[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightGreen),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
                  ),
                ),
                items: ['Appetizers', 'Main Course', 'Desserts', 'Beverages'].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    state.selectedCategory = value!;
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
                          color: state.isVegetarian ? Colors.white : Colors.lightGreen[800],
                        )),
                      selected: state.isVegetarian,
                      onSelected: (value) {
                        setState(() {
                          state.isVegetarian = value;
                          if (value) state.isVegan = false;
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
                          color: !state.isVegetarian ? Colors.white : Colors.lightGreen[800],
                        )),
                      selected: !state.isVegetarian,
                      onSelected: (value) {
                        setState(() {
                          state.isVegetarian = !value;
                          if (value) state.isVegan = false;
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
                        color: state.isVegan ? Colors.white : Colors.lightGreen[800],
                      )),
                    selected: state.isVegan,
                    onSelected: (value) {
                      setState(() {
                        state.isVegan = value;
                        if (value) state.isVegetarian = true;
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
                        color: state.isSpicy ? Colors.white : Colors.lightGreen[800],
                      )),
                    selected: state.isSpicy,
                    onSelected: (value) {
                      setState(() {
                        state.isSpicy = value;
                      });
                    },
                    backgroundColor: Colors.lightGreen[50],
                    selectedColor: Colors.orange,
                    checkmarkColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: Text('Today\'s Special',
                  style: TextStyle(color: Colors.lightGreen[700])),
                value: state.isTodaysSpecial,
                onChanged: (value) {
                  setState(() {
                    state.isTodaysSpecial = value ?? false;
                  });
                },
                activeColor: Colors.purple,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      state.selectedImage = File(pickedFile.path);
                      state.imageUrl = ''; // Clear the URL if we're using a new image
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text(state.selectedImage != null || state.imageUrl.isNotEmpty 
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
            onPressed: state.isUploading ? null : () async {
              if (state.nameController.text.trim().isEmpty ||
                  state.descriptionController.text.trim().isEmpty ||
                  state.priceController.text.trim().isEmpty) {
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
                final price = double.parse(state.priceController.text.trim());
                double? specialOfferPrice;
                
                if (state.hasSpecialOffer && state.specialOfferController.text.isNotEmpty) {
                  specialOfferPrice = double.parse(state.specialOfferController.text.trim());
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
                
                String finalImageUrl = state.imageUrl;
                
                // Upload new image if selected
                if (state.selectedImage != null) {
                  setState(() {
                    state.isUploading = true;
                  });
                  
                  // Upload to Firebase Storage
                  final storageRef = FirebaseStorage.instance
                      .ref()
                      .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                  
                  await storageRef.putFile(state.selectedImage!);
                  finalImageUrl = await storageRef.getDownloadURL();
                  
                  setState(() {
                    state.isUploading = false;
                  });
                }
                
                if (item == null) {
                  // Add new item
                  final newItem = MenuItemModel(
                    id: '', // Will be set by Firestore
                    restaurantId: restaurantId,
                    name: state.nameController.text.trim(),
                    description: state.descriptionController.text.trim(),
                    price: price,
                    specialOfferPrice: specialOfferPrice,
                    imageUrl: finalImageUrl.isEmpty 
                        ? 'https://via.placeholder.com/300x200?text=Food+Image'
                        : finalImageUrl,
                    category: state.selectedCategory,
                    isVegetarian: state.isVegetarian,
                    isVegan: state.isVegan,
                    isSpicy: state.isSpicy,
                    isTodaysSpecial: state.isTodaysSpecial,
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
                      'name': state.nameController.text.trim(),
                      'description': state.descriptionController.text.trim(),
                      'price': price,
                      'specialOfferPrice': specialOfferPrice,
                      'category': state.selectedCategory,
                      'isVegetarian': state.isVegetarian,
                      'isVegan': state.isVegan,
                      'isSpicy': state.isSpicy,
                      'isTodaysSpecial': state.isTodaysSpecial,
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
                  state.isUploading = false;
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
            child: state.isUploading 
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
  ).then((_) {
    state.dispose();
  });
}

void showDeleteItemDialog(BuildContext context, WidgetRef ref, MenuItemModel item) {
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