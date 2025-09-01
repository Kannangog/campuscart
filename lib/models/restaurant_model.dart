import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String imageUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final Map<String, String> openingHours;
  final double deliveryFee;
  final int estimatedDeliveryTime;
  final double minimumOrder;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String email;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.imageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    this.categories = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOpen = true,
    this.openingHours = const {},
    this.deliveryFee = 0.0,
    this.estimatedDeliveryTime = 30,
    this.minimumOrder = 0.0,
    this.isApproved = false,
    required this.createdAt,
    required this.updatedAt,
    required this.email, required int totalReviews,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RestaurantModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      isOpen: data['isOpen'] ?? true,
      openingHours: Map<String, String>.from(data['openingHours'] ?? {}),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      estimatedDeliveryTime: (data['estimatedDeliveryTime'] ?? 30).toInt(),
      minimumOrder: (data['minimumOrder'] ?? 0.0).toDouble(),
      isApproved: data['isApproved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      email: data['email']?.toString() ?? '', totalReviews: (data['totalReviews'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'categories': categories,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOpen': isOpen,
      'openingHours': openingHours,
      'deliveryFee': deliveryFee,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'minimumOrder': minimumOrder,
      'isApproved': isApproved,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? imageUrl,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    List<String>? categories,
    double? rating,
    int? reviewCount,
    bool? isOpen,
    Map<String, String>? openingHours,
    double? deliveryFee,
    int? estimatedDeliveryTime,
    double? minimumOrder,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    int? totalReviews,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOpen: isOpen ?? this.isOpen,
      openingHours: openingHours ?? this.openingHours,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
      totalReviews: totalReviews ?? 0,
    );
  }

  static RestaurantModel empty() {
    return RestaurantModel(
      id: '',
      name: '',
      description: '',
      ownerId: '',
      imageUrl: '',
      address: '',
      latitude: 0.0,
      longitude: 0.0,
      phoneNumber: '',
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
      email: '', totalReviews: 0,
    );
  }

  // Helper methods
  bool get hasMinimumOrder => minimumOrder > 0;
  bool get hasDeliveryFee => deliveryFee > 0;
  String get formattedRating => rating.toStringAsFixed(1);
  String get formattedDeliveryTime => '$estimatedDeliveryTime min';
  String get formattedDeliveryFee => deliveryFee == 0 ? 'Free' : '\$$deliveryFee';
  String get formattedMinimumOrder => minimumOrder == 0 ? 'No minimum' : '\$$minimumOrder minimum';
  
  // Convert to LatLng for maps
  Map<String, double> get location => {'latitude': latitude, 'longitude': longitude};
}