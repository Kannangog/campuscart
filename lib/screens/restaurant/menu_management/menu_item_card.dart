import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/menu_item_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final int index;
  final Function(bool) onToggleAvailability;
  final Function() onToggleTodaysSpecial;
  final Function() onEdit;
  final Function() onDelete;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onToggleAvailability,
    required this.onToggleTodaysSpecial,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasSpecialOffer = item.specialOfferPrice != null && item.specialOfferPrice! > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: item.isAvailable ? Colors.white : Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Image, Name, and Availability
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image
                  _buildImageSection(hasSpecialOffer),
                  
                  const SizedBox(width: 12),
                  
                  // Name and Availability
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: item.isAvailable 
                                    ? Colors.grey[900] 
                                    : Colors.grey[500],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildAvailabilityToggle(),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Description
                        Text(
                          item.description,
                          style: TextStyle(
                            color: item.isAvailable 
                              ? Colors.grey[600] 
                              : Colors.grey[400],
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tags Row - Category and Spicy
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildCategoryTag(),
                  if (item.isSpicy) _buildSpicyTag(),
                  if (item.isTodaysSpecial) _buildTodaysSpecialTag(),
                  if (hasSpecialOffer) _buildOfferTag(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Footer Row - Price and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Section
                  _buildPriceSection(hasSpecialOffer),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool hasSpecialOffer) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Main Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fastfood, color: Colors.grey[300], size: 30),
              ),
              errorWidget: (context, url, error) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fastfood, color: Colors.grey[300], size: 30),
              ),
            ),
          ),
          
          // Vegetarian Indicator
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
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Unavailable Overlay
          if (!item.isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'UNAVAILABLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: item.isAvailable ? Colors.green[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isAvailable ? Colors.green[200]! : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: item.isAvailable ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                item.isAvailable ? 'Available' : 'Unavailable',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: item.isAvailable ? Colors.green[700] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Transform.scale(
          scale: 0.7,
          child: Switch(
            value: item.isAvailable,
            onChanged: onToggleAvailability,
            activeColor: Colors.green,
            inactiveTrackColor: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: item.isAvailable ? Colors.blue[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isAvailable ? Colors.blue[100]! : Colors.grey[300]!,
        ),
      ),
      child: Text(
        item.category.toUpperCase(),
        style: TextStyle(
          color: item.isAvailable ? Colors.blue[700] : Colors.grey[600],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSpicyTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: item.isAvailable ? Colors.orange[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isAvailable ? Colors.orange[100]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, 
              size: 10, 
              color: item.isAvailable ? Colors.orange[700] : Colors.grey[600]),
          const SizedBox(width: 2),
          Text('Spicy',
            style: TextStyle(
              color: item.isAvailable ? Colors.orange[700] : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }

  Widget _buildTodaysSpecialTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: item.isAvailable ? Colors.purple[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isAvailable ? Colors.purple[100]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, 
              size: 10, 
              color: item.isAvailable ? Colors.purple[700] : Colors.grey[600]),
          const SizedBox(width: 2),
          Text('Today\'s Special',
            style: TextStyle(
              color: item.isAvailable ? Colors.purple[700] : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }

  Widget _buildOfferTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: item.isAvailable ? Colors.amber[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isAvailable ? Colors.amber[100]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer, 
              size: 10, 
              color: item.isAvailable ? Colors.amber[700] : Colors.grey[600]),
          const SizedBox(width: 2),
          Text('Special Offer',
            style: TextStyle(
              color: item.isAvailable ? Colors.amber[700] : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }

  Widget _buildPriceSection(bool hasSpecialOffer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSpecialOffer)
          Text(
            '₹${item.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
              fontWeight: FontWeight.w400,
            ),
          ),
        Text(
          hasSpecialOffer 
            ? '₹${item.specialOfferPrice!.toStringAsFixed(0)}' 
            : '₹${item.price.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: item.isAvailable 
              ? (hasSpecialOffer ? Colors.amber[800] : Colors.green[700])
              : Colors.grey[500],
          ),
        ),
        if (hasSpecialOffer)
          Text(
            'Save ₹${(item.price - item.specialOfferPrice!).toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Today's Special Toggle
        _buildIconButton(
          icon: item.isTodaysSpecial ? Icons.star : Icons.star_outline,
          color: item.isAvailable
            ? (item.isTodaysSpecial ? Colors.amber[600] : Colors.grey[600])
            : Colors.grey[400],
          tooltip: item.isTodaysSpecial 
              ? 'Remove from Today\'s Special' 
              : 'Add to Today\'s Special',
          onPressed: item.isAvailable ? onToggleTodaysSpecial : null,
        ),
        
        const SizedBox(width: 8),
        
        // Edit Button
        _buildIconButton(
          icon: Icons.edit,
          color: item.isAvailable ? Colors.blue[600] : Colors.grey[400],
          tooltip: 'Edit Item',
          onPressed: onEdit,
        ),
        
        const SizedBox(width: 8),
        
        // Delete Button
        _buildIconButton(
          icon: Icons.delete,
          color: item.isAvailable ? Colors.red[600] : Colors.grey[400],
          tooltip: 'Delete Item',
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color? color,
    required String tooltip,
    required Function()? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
        iconSize: 18,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}