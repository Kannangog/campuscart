import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum OrderLocationStatus {
  pending,
  confirmed,
  preparing,
  ready,
  readyForDelivery,
  outForDelivery,
  delivered,
  cancelled
}

class OrderLocationModel {
  final String id;
  final String restaurantId;
  final String userId;
  final String userName;
  final String userPhone;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final OrderLocationStatus status;
  final double total;
  final List<OrderLocationItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? driverId;
  final LatLng? driverLocation;
  final DateTime? estimatedDeliveryTime;
  final String? specialInstructions;
  final String? foodImageUrl;

  OrderLocationModel({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.status,
    required this.total,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.driverId,
    this.driverLocation,
    this.estimatedDeliveryTime,
    this.specialInstructions,
    this.foodImageUrl,
  });

  factory OrderLocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse order status - handle both string formats
    final statusString = data['status']?.toString() ?? 'pending';
    OrderLocationStatus status;
    
    try {
      if (statusString.startsWith('OrderLocationStatus.')) {
        final cleanStatusString = statusString.replaceFirst('OrderLocationStatus.', '');
        status = OrderLocationStatus.values.firstWhere(
          (e) => e.toString() == 'OrderLocationStatus.$cleanStatusString',
          orElse: () => OrderLocationStatus.pending,
        );
      } else if (statusString.startsWith('OrderStatus.')) {
        final cleanStatusString = statusString.replaceFirst('OrderStatus.', '');
        // Map OrderStatus to OrderLocationStatus
        status = _mapOrderStatusToLocationStatus(cleanStatusString);
      } else {
        // Handle direct enum name values
        status = OrderLocationStatus.values.firstWhere(
          (e) => e.name == statusString,
          orElse: () => _parseLegacyStatus(statusString),
        );
      }
    } catch (e) {
      status = _parseLegacyStatus(statusString);
    }

    // Parse items
    final List<OrderLocationItem> items = [];
    final itemsData = data['items'] as List<dynamic>? ?? [];
    for (final itemData in itemsData) {
      if (itemData is Map<String, dynamic>) {
        items.add(OrderLocationItem.fromMap(itemData));
      }
    }

    // Parse delivery location
    final double? deliveryLatitude = data['deliveryLatitude'] != null 
        ? (data['deliveryLatitude'] as num).toDouble() 
        : null;
    
    final double? deliveryLongitude = data['deliveryLongitude'] != null 
        ? (data['deliveryLongitude'] as num).toDouble() 
        : null;

    // Parse driver location if available
    LatLng? driverLocation;
    if (data['driverLocation'] is GeoPoint) {
      final geoPoint = data['driverLocation'] as GeoPoint;
      driverLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
    }

    return OrderLocationModel(
      id: doc.id,
      restaurantId: data['restaurantId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? data['customerName']?.toString() ?? '',
      userPhone: data['userPhone']?.toString() ?? '',
      deliveryAddress: data['deliveryAddress']?.toString() ?? '',
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      status: status,
      total: (data['total'] ?? 0.0).toDouble(),
      items: items,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      driverId: data['driverId']?.toString(),
      driverLocation: driverLocation,
      estimatedDeliveryTime: data['estimatedDeliveryTime'] != null
          ? (data['estimatedDeliveryTime'] as Timestamp).toDate()
          : null,
      specialInstructions: data['specialInstructions']?.toString(),
      foodImageUrl: data['foodImageUrl']?.toString(),
    );
  }

  static OrderLocationStatus _mapOrderStatusToLocationStatus(String status) {
    switch (status) {
      case 'readyForDelivery':
        return OrderLocationStatus.readyForDelivery;
      case 'outForDelivery':
        return OrderLocationStatus.outForDelivery;
      case 'delivered':
        return OrderLocationStatus.delivered;
      case 'cancelled':
        return OrderLocationStatus.cancelled;
      case 'confirmed':
        return OrderLocationStatus.confirmed;
      case 'preparing':
        return OrderLocationStatus.preparing;
      case 'ready':
        return OrderLocationStatus.ready;
      default:
        return OrderLocationStatus.pending;
    }
  }

  static OrderLocationStatus _parseLegacyStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'delivered':
      case 'delerved':
        return OrderLocationStatus.delivered;
      case 'readyfordelivery':
      case 'ready_for_delivery':
        return OrderLocationStatus.readyForDelivery;
      case 'outfordelivery':
      case 'out_for_delivery':
        return OrderLocationStatus.outForDelivery;
      case 'cancelled':
      case 'canceled':
        return OrderLocationStatus.cancelled;
      case 'confirmed':
        return OrderLocationStatus.confirmed;
      case 'preparing':
        return OrderLocationStatus.preparing;
      case 'ready':
        return OrderLocationStatus.ready;
      default:
        return OrderLocationStatus.pending;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'status': status.name,
      'total': total,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'driverId': driverId,
      'driverLocation': driverLocation != null
          ? GeoPoint(driverLocation!.latitude, driverLocation!.longitude)
          : null,
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'specialInstructions': specialInstructions,
      'foodImageUrl': foodImageUrl,
    };
  }

  OrderLocationModel copyWith({
    String? id,
    String? restaurantId,
    String? userId,
    String? userName,
    String? userPhone,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    OrderLocationStatus? status,
    double? total,
    List<OrderLocationItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? driverId,
    LatLng? driverLocation,
    DateTime? estimatedDeliveryTime,
    String? specialInstructions,
    String? foodImageUrl,
  }) {
    return OrderLocationModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      status: status ?? this.status,
      total: total ?? this.total,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      driverId: driverId ?? this.driverId,
      driverLocation: driverLocation ?? this.driverLocation,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      foodImageUrl: foodImageUrl ?? this.foodImageUrl,
    );
  }

  // Helper methods
  bool get isActive => status.index < OrderLocationStatus.delivered.index;
  
  bool get isOutForDelivery => status == OrderLocationStatus.outForDelivery;
  
  bool get isReadyForDelivery => status == OrderLocationStatus.readyForDelivery;
  
  bool get isPreparing => status == OrderLocationStatus.preparing;
  
  LatLng? get deliveryLatLng => (deliveryLatitude != null && deliveryLongitude != null)
      ? LatLng(deliveryLatitude!, deliveryLongitude!)
      : null;
  
  bool get hasLocation => deliveryLatitude != null && deliveryLongitude != null;

  String get statusText {
    switch (status) {
      case OrderLocationStatus.pending:
        return 'Pending';
      case OrderLocationStatus.confirmed:
        return 'Confirmed';
      case OrderLocationStatus.preparing:
        return 'Preparing';
      case OrderLocationStatus.ready:
        return 'Ready';
      case OrderLocationStatus.readyForDelivery:
        return 'Ready for Delivery';
      case OrderLocationStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderLocationStatus.delivered:
        return 'Delivered';
      case OrderLocationStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Convert to OrderModel compatible properties
  double get deliveryLatitudeDouble => deliveryLatitude ?? 0.0;
  double get deliveryLongitudeDouble => deliveryLongitude ?? 0.0;

  // Convert status to OrderStatus for compatibility
  OrderStatus get orderStatus {
    switch (status) {
      case OrderLocationStatus.pending:
        return OrderStatus.pending;
      case OrderLocationStatus.confirmed:
        return OrderStatus.confirmed;
      case OrderLocationStatus.preparing:
        return OrderStatus.preparing;
      case OrderLocationStatus.ready:
        return OrderStatus.ready;
      case OrderLocationStatus.readyForDelivery:
        return OrderStatus.ready;
      case OrderLocationStatus.outForDelivery:
        return OrderStatus.outForDelivery;
      case OrderLocationStatus.delivered:
        return OrderStatus.delivered;
      case OrderLocationStatus.cancelled:
        return OrderStatus.cancelled;
    }
  }

  static OrderLocationModel empty() {
    return OrderLocationModel(
      id: '',
      restaurantId: '',
      userId: '',
      userName: '',
      userPhone: '',
      deliveryAddress: '',
      deliveryLatitude: null,
      deliveryLongitude: null,
      status: OrderLocationStatus.pending,
      total: 0.0,
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class OrderLocationItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  OrderLocationItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderLocationItem.fromMap(Map<String, dynamic> map) {
    return OrderLocationItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 1).toInt(),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  double get total => price * quantity;
}

// Add OrderStatus enum for compatibility
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled
}