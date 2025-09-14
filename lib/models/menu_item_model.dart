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
  final String restaurantImage;
  final String restaurantName;
  final List<Review>? reviews;

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
    this.restaurantImage = '',
    this.restaurantName = '',
    this.reviews,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Handle specialOfferPrice conversion safely
    double? specialOfferPrice;
    final specialOfferData = data['specialOfferPrice'];
    if (specialOfferData != null) {
      if (specialOfferData is double) {
        specialOfferPrice = specialOfferData;
      } else if (specialOfferData is int) {
        specialOfferPrice = specialOfferData.toDouble();
      } else if (specialOfferData is String) {
        specialOfferPrice = double.tryParse(specialOfferData);
      }
    }

    // Handle reviews list
    List<Review>? reviews;
    final reviewsData = data['reviews'];
    if (reviewsData is List) {
      reviews = reviewsData.map((reviewData) {
        if (reviewData is Map<String, dynamic>) {
          return Review.fromMap(reviewData);
        }
        return Review(
          userName: 'Unknown',
          rating: 0.0,
          comment: '',
          date: 'Unknown date',
        );
      }).toList();
    }

    return MenuItemModel(
      id: doc.id,
      restaurantId: data['restaurantId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: _parseDouble(data['price'], 0.0),
      specialOfferPrice: specialOfferPrice,
      imageUrl: data['imageUrl']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Main Course',
      isAvailable: data['isAvailable'] ?? true,
      isVegetarian: data['isVegetarian'] ?? false,
      isVegan: data['isVegan'] ?? false,
      isSpicy: data['isSpicy'] ?? false,
      isTodaysSpecial: data['isTodaysSpecial'] ?? false,
      allergens: List<String>.from(data['allergens'] ?? []),
      preparationTime: _parseInt(data['preparationTime'], 15),
      rating: _parseDouble(data['rating'], 0.0),
      reviewCount: _parseInt(data['reviewCount'], 0),
      orderCount: _parseInt(data['orderCount'], 0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      restaurantImage: data['restaurantImage']?.toString() ?? '',
      restaurantName: data['restaurantName']?.toString() ?? '',
      reviews: reviews,
    );
  }

  // Helper method to parse double safely
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper method to parse int safely
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
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
      'restaurantImage': restaurantImage,
      'restaurantName': restaurantName,
      'reviews': reviews?.map((review) => review.toMap()).toList(),
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
    String? restaurantImage,
    String? restaurantName,
    List<Review>? reviews,
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
      restaurantImage: restaurantImage ?? this.restaurantImage,
      restaurantName: restaurantName ?? this.restaurantName,
      reviews: reviews ?? this.reviews,
    );
  }

  // Getter for discounted price
  double get discountedPrice => specialOfferPrice ?? price;

  // Check if item is on sale
  bool get isOnSale => specialOfferPrice != null && specialOfferPrice! < price;

  // Calculate discount percentage
  double get discountPercentage {
    if (!isOnSale) return 0.0;
    return ((price - specialOfferPrice!) / price * 100).roundToDouble();
  }

  // Get preparation time as formatted string
  String get preparationTimeFormatted => '$preparationTime min';

  // Get rating as formatted string
  String get ratingFormatted => rating.toStringAsFixed(1);

  // Check if item is popular (based on order count)
  bool get isPopular => orderCount > 50;

  // Check if item is new (created within last 7 days)
  bool get isNew => DateTime.now().difference(createdAt).inDays <= 7;
}

// Review class with proper serialization
class Review {
  final String userName;
  final double rating;
  final String comment;
  final String date;
  final String? userId;
  final String? userImage;

  Review({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.userId,
    this.userImage,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      userName: map['userName']?.toString() ?? 'Unknown',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment']?.toString() ?? '',
      date: map['date']?.toString() ?? 'Unknown date',
      userId: map['userId']?.toString(),
      userImage: map['userImage']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'date': date,
      'userId': userId,
      'userImage': userImage,
    };
  }
}