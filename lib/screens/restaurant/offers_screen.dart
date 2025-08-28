import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/offer_provider.dart';
import '../../models/offer_model.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to manage offers')),
      );
    }

    final userAsync = ref.watch(userProvider(user));
    
    return userAsync.when(
      data: (userModel) {
        if (userModel == null) return const SizedBox();
        
        final restaurants = ref.watch(restaurantsByOwnerProvider(userModel.id));
        
        return restaurants.when(
          data: (restaurantList) {
            if (restaurantList.isEmpty) {
              return _buildNoRestaurant(context);
            }
            
            final restaurant = restaurantList.first;
            final offers = ref.watch(restaurantOffersProvider(restaurant.id));
            
            return Scaffold(
              appBar: AppBar(
                title: const Text('Special Offers'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    onPressed: () => _showCreateOfferDialog(context, ref, restaurant.id),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              body: offers.when(
                data: (offerList) {
                  if (offerList.isEmpty) {
                    return _buildEmptyOffers(context, ref, restaurant.id);
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: offerList.length,
                    itemBuilder: (context, index) {
                      final offer = offerList[index];
                      return _buildOfferCard(context, ref, offer, index);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading offers: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(restaurantOffersProvider(restaurant.id)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showCreateOfferDialog(context, ref, restaurant.id),
                child: const Icon(Icons.add),
              ).animate().scale().fadeIn(),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(child: Text('Error: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildNoRestaurant(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 120,
              color: Colors.grey.shade400,
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            Text(
              'No Restaurant Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 12),
            
            Text(
              'Please create a restaurant first to manage offers',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOffers(BuildContext context, WidgetRef ref, String restaurantId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 120,
            color: Colors.grey.shade400,
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 24),
          
          Text(
            'No Special Offers',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          
          const SizedBox(height: 12),
          
          Text(
            'Create your first special offer to attract more customers',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () => _showCreateOfferDialog(context, ref, restaurantId),
            icon: const Icon(Icons.add),
            label: const Text('Create Offer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, WidgetRef ref, OfferModel offer, int index) {
    final isActive = offer.isValid;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade400,
                      Colors.red.shade400,
                    ],
                  )
                : null,
            color: isActive ? null : Colors.grey.shade100,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Offer Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        offer.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Switch(
                          value: offer.isActive,
                          onChanged: (value) {
                            ref.read(offerManagementProvider.notifier)
                                .toggleOfferStatus(offer.id, value);
                          },
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white.withOpacity(0.3),
                        ),
                        PopupMenuButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: isActive ? Colors.white : Colors.grey.shade600,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () => _showEditOfferDialog(context, ref, offer),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () => _showDeleteOfferDialog(context, ref, offer),
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Offer Description
                Text(
                  offer.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isActive ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Offer Details
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? Colors.white.withOpacity(0.2)
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${offer.value.toInt()}% OFF',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (offer.minimumOrder > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Min \$${offer.minimumOrder.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Offer Period
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isActive ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM dd').format(offer.startDate)} - ${DateFormat('MMM dd, yyyy').format(offer.endDate)}',
                      style: TextStyle(
                        color: isActive ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Usage Stats
                if (offer.usageLimit > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: isActive ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.usageCount}/${offer.usageLimit} used',
                        style: TextStyle(
                          color: isActive ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                
                // Status Indicator
                if (!isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      offer.endDate.isBefore(DateTime.now()) ? 'Expired' : 'Inactive',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.3);
  }

  void _showCreateOfferDialog(BuildContext context, WidgetRef ref, String restaurantId) {
    _showOfferDialog(context, ref, restaurantId: restaurantId);
  }

  void _showEditOfferDialog(BuildContext context, WidgetRef ref, OfferModel offer) {
    _showOfferDialog(context, ref, restaurantId: offer.restaurantId, offer: offer);
  }

  void _showOfferDialog(BuildContext context, WidgetRef ref, {required String restaurantId, OfferModel? offer}) {
    final titleController = TextEditingController(text: offer?.title ?? '');
    final descriptionController = TextEditingController(text: offer?.description ?? '');
    final valueController = TextEditingController(text: offer?.value.toString() ?? '');
    final minimumOrderController = TextEditingController(text: offer?.minimumOrder.toString() ?? '0');
    final usageLimitController = TextEditingController(text: offer?.usageLimit.toString() ?? '0');
    
    DateTime startDate = offer?.startDate ?? DateTime.now();
    DateTime endDate = offer?.endDate ?? DateTime.now().add(const Duration(days: 7));
    OfferType selectedType = offer?.type ?? OfferType.percentage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(offer == null ? 'Create Special Offer' : 'Edit Special Offer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Offer Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<OfferType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Offer Type',
                    border: OutlineInputBorder(),
                  ),
                  items: OfferType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: selectedType == OfferType.percentage ? 'Discount (%)' : 'Discount Amount (\$)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minimumOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Order Amount (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usageLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Usage Limit (0 for unlimited)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              startDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    valueController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final value = double.parse(valueController.text.trim());
                  final minimumOrder = double.parse(minimumOrderController.text.trim());
                  final usageLimit = int.parse(usageLimitController.text.trim());
                  
                  if (offer == null) {
                    // Create new offer
                    final newOffer = OfferModel(
                      id: '', // Will be set by Firestore
                      restaurantId: restaurantId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      type: selectedType,
                      value: value,
                      minimumOrder: minimumOrder,
                      startDate: startDate,
                      endDate: endDate,
                      usageLimit: usageLimit,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    
                    await ref.read(offerManagementProvider.notifier).createOffer(newOffer);
                  } else {
                    // Update existing offer
                    await ref.read(offerManagementProvider.notifier).updateOffer(
                      offer.id,
                      {
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'type': selectedType.toString().split('.').last,
                        'value': value,
                        'minimumOrder': minimumOrder,
                        'startDate': startDate,
                        'endDate': endDate,
                        'usageLimit': usageLimit,
                      },
                    );
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(offer == null 
                            ? 'Offer created successfully!' 
                            : 'Offer updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(offer == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteOfferDialog(BuildContext context, WidgetRef ref, OfferModel offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text('Are you sure you want to delete "${offer.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(offerManagementProvider.notifier).deleteOffer(offer.id);
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Offer deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting offer: $e'),
                      backgroundColor: Colors.red,
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