import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final double? specialOfferPrice;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final bool isSpicy;
  final bool isTodaysSpecial;
  final List<String> allergens;
  final int preparationTime;
  final double rating;
  final int reviewCount;
  final int orderCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.specialOfferPrice,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isSpicy = false,
    this.isTodaysSpecial = false,
    this.allergens = const [],
    this.preparationTime = 15,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.orderCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MenuItemModel(
      id: doc.id,
      restaurantId: data['restaurantId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      specialOfferPrice: data['specialOfferPrice'] != null 
          ? (data['specialOfferPrice']).toDouble() 
          : null,
      imageUrl: data['imageUrl']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Main Course',
      isAvailable: data['isAvailable'] ?? true,
      isVegetarian: data['isVegetarian'] ?? false,
      isVegan: data['isVegan'] ?? false,
      isSpicy: data['isSpicy'] ?? false,
      isTodaysSpecial: data['isTodaysSpecial'] ?? false,
      allergens: List<String>.from(data['allergens'] ?? []),
      preparationTime: data['preparationTime'] ?? 15,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      orderCount: data['orderCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'specialOfferPrice': specialOfferPrice,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isSpicy': isSpicy,
      'isTodaysSpecial': isTodaysSpecial,
      'allergens': allergens,
      'preparationTime': preparationTime,
      'rating': rating,
      'reviewCount': reviewCount,
      'orderCount': orderCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MenuItemModel copyWith({
    String? name,
    String? description,
    double? price,
    double? specialOfferPrice,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    bool? isVegetarian,
    bool? isVegan,
    bool? isSpicy,
    bool? isTodaysSpecial,
    List<String>? allergens,
    int? preparationTime,
    double? rating,
    int? reviewCount,
    int? orderCount,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      specialOfferPrice: specialOfferPrice ?? this.specialOfferPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isSpicy: isSpicy ?? this.isSpicy,
      isTodaysSpecial: isTodaysSpecial ?? this.isTodaysSpecial,
      allergens: allergens ?? this.allergens,
      preparationTime: preparationTime ?? this.preparationTime,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}