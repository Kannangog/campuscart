import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

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
  final int preparationTime;
  final double minimumOrder;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String email;
  final int totalReviews;
  final bool isFeatured;

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
    this.preparationTime = 15,
    this.minimumOrder = 0.0,
    this.isApproved = false,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
    this.totalReviews = 0,
    this.isFeatured = false,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse opening hours safely
    Map<String, String> parsedOpeningHours = {};
    final openingHoursData = data['openingHours'];
    if (openingHoursData is Map) {
      openingHoursData.forEach((key, value) {
        if (key is String && value is String) {
          parsedOpeningHours[key] = value;
        }
      });
    }

    return RestaurantModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      latitude: _parseDouble(data['latitude'], 0.0),
      longitude: _parseDouble(data['longitude'], 0.0),
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      rating: _parseDouble(data['rating'], 0.0),
      reviewCount: _parseInt(data['reviewCount'], 0),
      isOpen: data['isOpen'] ?? true,
      openingHours: parsedOpeningHours,
      deliveryFee: _parseDouble(data['deliveryFee'], 0.0),
      estimatedDeliveryTime: _parseInt(data['estimatedDeliveryTime'], 30),
      preparationTime: _parseInt(data['preparationTime'], 15),
      minimumOrder: _parseDouble(data['minimumOrder'], 0.0),
      isApproved: data['isApproved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      email: data['email']?.toString() ?? '',
      totalReviews: _parseInt(data['totalReviews'], 0),
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  // Helper methods for safe parsing
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
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
      'preparationTime': preparationTime,
      'minimumOrder': minimumOrder,
      'isApproved': isApproved,
      'email': email,
      'totalReviews': totalReviews,
      'isFeatured': isFeatured,
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
    int? preparationTime,
    double? minimumOrder,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    int? totalReviews,
    bool? isFeatured,
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
      preparationTime: preparationTime ?? this.preparationTime,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
      totalReviews: totalReviews ?? this.totalReviews,
      isFeatured: isFeatured ?? this.isFeatured,
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
      preparationTime: 15,
      minimumOrder: 0.0,
      isApproved: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      email: '',
      totalReviews: 0,
      isFeatured: false,
    );
  }

  // Helper methods
  bool get hasMinimumOrder => minimumOrder > 0;
  bool get hasDeliveryFee => deliveryFee > 0;
  String get formattedRating => rating.toStringAsFixed(1);
  String get formattedDeliveryTime => '$estimatedDeliveryTime min';
  String get formattedDeliveryFee => deliveryFee == 0 ? 'Free' : '₹$deliveryFee';
  String get formattedMinimumOrder => minimumOrder == 0 ? 'No minimum' : '₹$minimumOrder minimum';
  
  // Convert to LatLng for maps
  Map<String, double> get location => {'latitude': latitude, 'longitude': longitude};

  // Get opening time for today
  String? get todaysOpeningHours {
    final now = DateTime.now();
    final today = now.weekday;
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final todayKey = days[today - 1]; // DateTime.weekday returns 1-7 (Monday=1)
    
    return openingHours[todayKey];
  }

  // Get today's opening and closing times separately
  TimeOfDay? get openingTime {
    final hours = todaysOpeningHours;
    if (hours == null || hours.isEmpty) return null;
    
    try {
      final parts = hours.split('-');
      if (parts.length != 2) return null;
      
      return _parseTime(parts[0].trim());
    } catch (e) {
      return null;
    }
  }

  TimeOfDay? get closingTime {
    final hours = todaysOpeningHours;
    if (hours == null || hours.isEmpty) return null;
    
    try {
      final parts = hours.split('-');
      if (parts.length != 2) return null;
      
      return _parseTime(parts[1].trim());
    } catch (e) {
      return null;
    }
  }

  // Check if restaurant is currently open
  bool get isCurrentlyOpen {
    if (!isOpen) return false;
    
    final openTime = openingTime;
    final closeTime = closingTime;
    
    if (openTime == null || closeTime == null) return true;
    
    final now = TimeOfDay.now();
    
    // Check if current time is between opening and closing time
    final isAfterOpening = now.hour > openTime.hour || 
                          (now.hour == openTime.hour && now.minute >= openTime.minute);
    
    final isBeforeClosing = now.hour < closeTime.hour || 
                           (now.hour == closeTime.hour && now.minute < closeTime.minute);
    
    return isAfterOpening && isBeforeClosing;
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) throw const FormatException('Invalid time format');
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        throw const FormatException('Invalid time values');
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      // Return a default time if parsing fails
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  // Get average preparation time
  String get formattedPreparationTime => '$preparationTime min';

  // Check if restaurant is verified/approved
  bool get isVerified => isApproved;

  // Get categories as comma separated string
  String get formattedCategories => categories.join(', ');

  // Get star rating with reviews count
  String get ratingWithReviews {
    if (reviewCount == 0) return 'No reviews yet';
    return '$formattedRating • $reviewCount reviews';
  }

  // Calculate delivery time including preparation
  int get totalDeliveryTime => preparationTime + estimatedDeliveryTime;
  String get formattedTotalDeliveryTime => '$totalDeliveryTime min';

  // Get minimum order amount
  double get minOrderAmount => minimumOrder;

  // Get formatted opening status
  String get formattedOpeningStatus {
    if (!isOpen) return 'Closed';
    return isCurrentlyOpen ? 'Open' : 'Closed';
  }

  // Get next opening time if currently closed
  String? get nextOpeningTime {
    if (isCurrentlyOpen || !isOpen) return null;
    
    final openTime = openingTime;
    if (openTime == null) return null;
    
    return 'Opens at ${openTime.format(TimeOfDayFormat.HH_colon_mm as BuildContext)}';
  }

  // Get delivery information summary
  String get deliveryInfo {
    return '$formattedDeliveryFee delivery • $formattedTotalDeliveryTime • $formattedMinimumOrder';
  }

  // Check if restaurant offers delivery
  bool get offersDelivery => deliveryFee >= 0;

  // Get distance from current location
  String getDistanceFrom(double userLat, double userLng) {
    final distance = calculateDistance(latitude, longitude, userLat, userLng);
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
             math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
             math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    
    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // Get featured status
  bool get isRestaurantFeatured => isFeatured;

  // Get rating stars (for UI display)
  List<bool> get ratingStars {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    
    return List.generate(5, (index) {
      if (index < fullStars) return true;
      if (index == fullStars && hasHalfStar) return true;
      return false;
    });
  }

  // Get preparation status
  String get preparationStatus {
    if (preparationTime <= 15) return 'Fast';
    if (preparationTime <= 30) return 'Normal';
    return 'Slow';
  }

  // Check if restaurant is new (less than 7 days old)
  bool get isNewRestaurant {
    final now = DateTime.now();
    return now.difference(createdAt).inDays <= 7;
  }

  // Get formatted creation date
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Get contact information
  String get contactInfo => '$phoneNumber • $email';

  // Check if restaurant has valid location
  bool get hasValidLocation => latitude != 0.0 && longitude != 0.0;

  // Get map URL (for Google Maps)
  String get mapUrl {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  // Get directions URL
  String get directionsUrl {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
  }

  // Get shareable content
  String get shareContent {
    return 'Check out $name - $description\nRating: $formattedRating ⭐\n$address';
  }
}