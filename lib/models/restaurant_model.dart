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
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      phoneNumber: data['phoneNumber'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isOpen: data['isOpen'] ?? true,
      openingHours: Map<String, String>.from(data['openingHours'] ?? {}),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      estimatedDeliveryTime: data['estimatedDeliveryTime'] ?? 30,
      minimumOrder: (data['minimumOrder'] ?? 0.0).toDouble(),
      isApproved: data['isApproved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RestaurantModel copyWith({
    String? name,
    String? description,
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
    DateTime? updatedAt,
  }) {
    return RestaurantModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId,
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
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}