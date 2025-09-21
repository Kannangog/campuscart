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
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: item.isAvailable ? Colors.white : Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image with enhanced UI
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
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
                    // Availability overlay
                    if (!item.isAvailable)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'UNAVAILABLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                backgroundColor: Colors.red[700],
                              ),
                            ),
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
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Special offer badge
                    if (hasSpecialOffer)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OFFER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Today's Special badge
                    if (item.isTodaysSpecial)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SPECIAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Item Details - Fixed overflow by using Expanded properly
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name and availability toggle - Fixed overflow
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: item.isAvailable 
                                ? Colors.lightGreen[900] 
                                : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Availability Toggle with clear label
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.isAvailable ? 'Available' : 'Unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.isAvailable 
                                  ? Colors.green[700] 
                                  : Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 24,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Switch(
                                  value: item.isAvailable,
                                  onChanged: (value) {
                                    // This should only toggle availability, not delete
                                    onToggleAvailability(value);
                                  },
                                  activeColor: Colors.lightGreen,
                                  inactiveThumbColor: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      item.description,
                      style: TextStyle(
                        color: item.isAvailable 
                          ? Colors.grey.shade700 
                          : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Category and spicy indicator
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isAvailable 
                              ? Colors.lightGreen[100] 
                              : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              color: item.isAvailable 
                                ? Colors.lightGreen[800] 
                                : Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.isSpicy)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.isAvailable 
                                ? Colors.orange[100] 
                                : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_fire_department, 
                                    size: 12, 
                                    color: item.isAvailable 
                                      ? Colors.orange[800] 
                                      : Colors.grey[600]),
                                const SizedBox(width: 2),
                                Text('Spicy',
                                  style: TextStyle(
                                    color: item.isAvailable 
                                      ? Colors.orange[800] 
                                      : Colors.grey[600],
                                    fontSize: 10,
                                  )),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Price and action buttons - Fixed potential overflow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasSpecialOffer)
                                Text(
                                  '₹${item.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                hasSpecialOffer 
                                  ? '₹${item.specialOfferPrice!.toStringAsFixed(2)}' 
                                  : '₹${item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: item.isAvailable 
                                    ? (hasSpecialOffer ? Colors.amber[800] : Colors.lightGreen[800])
                                    : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action buttons - Fixed potential overflow
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Today's Special Toggle Button
                            IconButton(
                              onPressed: item.isAvailable ? onToggleTodaysSpecial : null,
                              icon: Icon(
                                item.isTodaysSpecial ? Icons.star : Icons.star_border,
                                size: 20,
                                color: item.isAvailable
                                  ? (item.isTodaysSpecial ? Colors.amber[700] : Colors.grey[600])
                                  : Colors.grey[400],
                              ),
                              tooltip: item.isTodaysSpecial 
                                  ? 'Remove from Today\'s Special' 
                                  : 'Add to Today\'s Special',
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Edit button
                            IconButton(
                              onPressed: onEdit,
                              icon: Icon(Icons.edit, 
                                size: 20, 
                                color: item.isAvailable 
                                  ? Colors.lightGreen[700] 
                                  : Colors.grey[400]),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Delete button
                            IconButton(
                              onPressed: onDelete,
                              icon: Icon(Icons.delete, 
                                size: 20, 
                                color: item.isAvailable 
                                  ? Colors.red[700] 
                                  : Colors.grey[400]),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
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
    );
  }
}