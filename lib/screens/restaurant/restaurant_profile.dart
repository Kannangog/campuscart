import 'package:campuscart/providers/auth_provider.dart';
import 'package:campuscart/screens/restaurant/restaurant_location_screen.dart';
import 'package:campuscart/utilities/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscart/models/restaurant_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:campuscart/providers/restaurant_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  ConsumerState<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends ConsumerState<RestaurantProfileScreen> {
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
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

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
      // Show options for camera or gallery
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

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 80,
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Restaurant Image',
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              activeControlsWidgetColor: Theme.of(context).primaryColor,
              showCropGrid: true,
            ),
            IOSUiSettings(
              title: 'Crop Restaurant Image',
              aspectRatioLockEnabled: true,
              aspectRatioPickerButtonHidden: true,
              resetAspectRatioEnabled: false,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
          ],
        );

        if (croppedFile != null && mounted) {
          setState(() {
            _profileImage = File(croppedFile.path);
          });
        }
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
      if (user != null) {
        final restaurants = ref.read(restaurantsByOwnerProvider(user.uid)).value ?? [];
        if (restaurants.isNotEmpty) {
          final existingRestaurant = restaurants.first;
          
          String? imageUrl;
          if (_profileImage != null) {
            // Clear cache for old image if exists
            if (existingRestaurant.imageUrl.isNotEmpty) {
              _cacheManager.removeFile(existingRestaurant.imageUrl);
            }
            
            imageUrl = await ref.read(restaurantManagementProvider.notifier).uploadImage(_profileImage!);
          }

          await ref.read(restaurantManagementProvider.notifier).updateRestaurant(
            existingRestaurant.id,
            {
              'name': _nameController.text,
              'description': _descriptionController.text,
              'phoneNumber': _phoneController.text,
              'email': _emailController.text,
              'address': _addressController.text,
              if (imageUrl != null) 'imageUrl': imageUrl,
              if (_selectedLatitude != null) 'latitude': _selectedLatitude,
              if (_selectedLongitude != null) 'longitude': _selectedLongitude,
              'updatedAt': DateTime.now(),
            },
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restaurant updated successfully')),
            );
          }
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
    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location for your restaurant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        String? imageUrl;
        if (_profileImage != null) {
          imageUrl = await ref.read(restaurantManagementProvider.notifier).uploadImage(_profileImage!);
        }

        final restaurant = RestaurantModel(
          id: '',
          name: _nameController.text,
          description: _descriptionController.text,
          ownerId: user.uid,
          imageUrl: imageUrl ?? '',
          address: _addressController.text,
          latitude: _selectedLatitude!,
          longitude: _selectedLongitude!,
          phoneNumber: _phoneController.text,
          categories: [],
          rating: 0.0,
          reviewCount: 0,
          isOpen: true,
          openingHours: {},
          deliveryFee: 0.0,
          estimatedDeliveryTime: 30,
          minimumOrder: 0.0,
          isApproved: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          email: _emailController.text,
        );

        await ref.read(restaurantManagementProvider.notifier).createRestaurant(restaurant);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant created successfully! Waiting for approval.')),
          );
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
    if (user != null) {
      final restaurants = ref.read(restaurantsByOwnerProvider(user.uid)).value ?? [];
      if (restaurants.isNotEmpty) {
        final restaurant = restaurants.first;
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
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
                      // Clear cached image
                      if (restaurant.imageUrl.isNotEmpty) {
                        _cacheManager.removeFile(restaurant.imageUrl);
                      }
                      
                      await ref.read(restaurantManagementProvider.notifier).deleteRestaurant(restaurant.id);
                      
                      if (mounted) {
                        setState(() {
                          _nameController.clear();
                          _descriptionController.clear();
                          _addressController.clear();
                          _phoneController.clear();
                          _emailController.clear();
                          _profileImage = null;
                          _selectedLatitude = null;
                          _selectedLongitude = null;
                        });
                        
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

  Future<void> _logout() async {
    try {
      await ref.read(authProvider.notifier).signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
        title: const Text('Restaurant Profile'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: restaurantAsync.when(
        data: (restaurants) {
          final hasRestaurant = restaurants.isNotEmpty;
          final restaurant = hasRestaurant ? restaurants.first : null;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image Section
                  _buildProfileImageSection(theme, restaurant, hasRestaurant),
                  const SizedBox(height: 20),

                  // Restaurant Info
                  if (hasRestaurant && restaurant != null) ...[
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      restaurant.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Chip(
                      label: Text(
                        restaurant.isApproved ? 'APPROVED' : 'PENDING APPROVAL',
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                      backgroundColor: restaurant.isApproved ? Colors.green : Colors.orange,
                    ),
                  ],
                  const SizedBox(height: 30),

                  // Form Fields
                  _buildFormFields(theme),
                  const SizedBox(height: 30),

                  // Action Buttons
                  _buildActionButtons(theme, hasRestaurant, restaurant),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
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
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
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
                                child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, color: Colors.red),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                            )),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
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
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap to change image',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Restaurant Name',
            prefixIcon: Icon(Icons.restaurant, color: theme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.cardColor,
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
            labelText: 'Restaurant Description',
            prefixIcon: Icon(Icons.description, color: theme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.cardColor,
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
            fillColor: theme.cardColor,
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
            fillColor: theme.cardColor,
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
            labelText: 'Restaurant Address',
            prefixIcon: Icon(Icons.location_on, color: theme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.cardColor,
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
        
        // Location Selection
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _selectLocation,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: theme.cardColor,
            ),
            icon: Icon(Icons.map, color: theme.primaryColor),
            label: _selectedLatitude == null
                ? const Text('Select Restaurant Location on Map')
                : Text('Location Selected: ${_selectedLatitude!.toStringAsFixed(4)}, ${_selectedLongitude!.toStringAsFixed(4)}'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool hasRestaurant, RestaurantModel? restaurant) {
    return Column(
      children: [
        if (hasRestaurant) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _updateRestaurant,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isLoading 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: _isLoading 
                  ? const Text('Updating...')
                  : const Text('Update Restaurant'),
            ),
          ),
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteRestaurant,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: theme.cardColor,
              ),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Delete Restaurant',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _createRestaurant,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isLoading 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_business),
              label: _isLoading 
                  ? const Text('Creating...')
                  : const Text('Create Restaurant'),
            ),
          ),
        ],
        
        const SizedBox(height: 20),

        // Restaurant Status
        if (hasRestaurant && restaurant != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: restaurant.isApproved 
                ? Colors.green.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: restaurant.isApproved ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  restaurant.isApproved ? Icons.verified : Icons.pending,
                  color: restaurant.isApproved ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    restaurant.isApproved
                        ? 'Your restaurant is approved and visible to customers'
                        : 'Your restaurant is pending approval',
                    style: TextStyle(
                      color: restaurant.isApproved ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}