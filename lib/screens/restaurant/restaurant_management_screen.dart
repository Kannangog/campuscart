// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_result

import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/screens/restaurant/restaurant_location_screen.dart';
import 'package:campuscart/utilities/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscart/models/restaurant_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:campuscart/providers/restaurant_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RestaurantManagementScreen extends ConsumerStatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  ConsumerState<RestaurantManagementScreen> createState() => _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState extends ConsumerState<RestaurantManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  final ImagePicker _imagePicker = ImagePicker();
  RestaurantModel? _currentRestaurant;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  void _loadRestaurantData() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final restaurantAsync = ref.read(restaurantsByOwnerProvider(user.uid));
      restaurantAsync.whenData((restaurants) {
        if (restaurants.isNotEmpty && mounted) {
          final restaurant = restaurants.first;
          _currentRestaurant = restaurant;
          setState(() {
            _nameController.text = restaurant.name;
            _descriptionController.text = restaurant.description;
            _addressController.text = restaurant.address;
            _phoneController.text = restaurant.phoneNumber;
            _emailController.text = restaurant.email;
            _selectedLatitude = restaurant.latitude;
            _selectedLongitude = restaurant.longitude;
          });
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Select Image Source'),
          content: const Text('Choose where to pick the image from'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Gallery'),
            ),
          ],
        ),
      );

      if (source == null) return;

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null && _currentRestaurant != null) {
        // Call updateRestaurant with the image file
        await ref.read(restaurantManagementProvider.notifier).updateRestaurant(
          _currentRestaurant!.id,
          {
            'name': _nameController.text,
            'description': _descriptionController.text,
            'phoneNumber': _phoneController.text,
            'email': _emailController.text,
            'address': _addressController.text,
            if (_selectedLatitude != null) 'latitude': _selectedLatitude,
            if (_selectedLongitude != null) 'longitude': _selectedLongitude,
          },
          imageFile: _profileImage, // Pass the image file here
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant updated successfully')),
          );
          // Refresh data and reset image
          ref.refresh(restaurantsByOwnerProvider(user.uid));
          setState(() {
            _profileImage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating restaurant: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        // CORRECTED: Pass ownerId as a String, not cast as RestaurantModel
        await ref.read(restaurantManagementProvider.notifier).createRestaurant(
          user.uid, // Correct: ownerId as String
          name: _nameController.text,
          description: _descriptionController.text,
          phoneNumber: _phoneController.text,
          categories: const [], // You might want to add category selection
          address: _addressController.text,
          latitude: _selectedLatitude ?? 0.0,
          longitude: _selectedLongitude ?? 0.0,
          imageFile: _profileImage, // Pass the image file here
          email: _emailController.text,
          openingTime: '09:00', // Add proper time pickers
          closingTime: '21:00',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant created successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating restaurant: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

Future<void> _deleteRestaurant() async {
  final user = ref.read(authStateProvider).value;
  if (user != null && _currentRestaurant != null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Restaurant'),
          content: const Text('Are you sure you want to delete your restaurant? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                try {
                  await ref.read(restaurantManagementProvider.notifier).deleteRestaurant(_currentRestaurant!.id);
                  
                  // Force refresh user status
                  await ref.read(restaurantManagementProvider.notifier).refreshUserRestaurantStatus(user.uid);
                  
                  if (mounted) {
                    // Force refresh the provider
                    ref.invalidate(restaurantsByOwnerProvider(user.uid));
                    ref.invalidate(userHasRestaurantProvider);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restaurant deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting restaurant: ${e.toString()}')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

  Future<void> _selectLocation() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantLocationScreen(
          initialLocation: _selectedLatitude != null && _selectedLongitude != null
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : null,
        ),
      ),
    );

    if (selectedLocation != null && mounted) {
      setState(() {
        _selectedLatitude = selectedLocation.latitude;
        _selectedLongitude = selectedLocation.longitude;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location selected: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final user = ref.watch(authStateProvider).value;
    final restaurantAsync = user != null ? ref.watch(restaurantsByOwnerProvider(user.uid)) : const AsyncValue.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Management'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: restaurantAsync.when(
        data: (restaurants) {
          final hasRestaurant = restaurants.isNotEmpty;
          final restaurant = hasRestaurant ? restaurants.first : null;
          _currentRestaurant = restaurant;
          
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile image section
                    _buildProfileImageSection(theme, restaurant, hasRestaurant),
                    
                    const SizedBox(height: 24),
                    
                    // Restaurant form
                    _buildRestaurantForm(theme, restaurant, hasRestaurant),
                    
                    const SizedBox(height: 24),
                    
                    // Location preview if selected
                    if (_selectedLatitude != null && _selectedLongitude != null)
                      _buildLocationPreview(theme),
                  ],
                ),
              ),
              
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => user != null ? ref.refresh(restaurantsByOwnerProvider(user.uid)) : null,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(ThemeData theme, RestaurantModel? restaurant, bool hasRestaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        )
                      : (hasRestaurant && restaurant!.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: restaurant.imageUrl,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.restaurant, size: 50, color: Colors.grey[600]),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, color: Colors.red),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.restaurant, size: 50, color: Colors.grey[600]),
                            )),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, size: 20, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            hasRestaurant ? 'Update Restaurant Image' : 'Add Restaurant Image',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the camera icon to change',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantForm(ThemeData theme, RestaurantModel? restaurant, bool hasRestaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasRestaurant ? 'Update Restaurant Details' : 'Create Restaurant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Restaurant Name',
                prefixIcon: Icon(Icons.restaurant, color: theme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter restaurant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description, color: theme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter restaurant description';
                }
                if (value.length < 20) {
                  return 'Description should be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone, color: theme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email, color: theme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on, color: theme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter restaurant address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  foregroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.map, color: theme.primaryColor),
                label: _selectedLatitude == null
                    ? const Text('Select Location on Map')
                    : Text('Location Selected: ${_selectedLatitude!.toStringAsFixed(4)}, ${_selectedLongitude!.toStringAsFixed(4)}'),
              ),
            ),
            const SizedBox(height: 24),
            
            if (hasRestaurant) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _deleteRestaurant,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete Restaurant',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateRestaurant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update Restaurant'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRestaurant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Restaurant'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Latitude: ${_selectedLatitude!.toStringAsFixed(6)}',
            style: TextStyle(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          Text(
            'Longitude: ${_selectedLongitude!.toStringAsFixed(6)}',
            style: TextStyle(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _selectLocation,
              child: const Text('Change Location'),
            ),
          ),
        ],
      ),
    );
  }
}