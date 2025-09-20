import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
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
  final double? deliveryLatitude; // Changed to nullable
  final double? deliveryLongitude; // Changed to nullable
  final OrderStatus status;
  final double total;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? driverId;
  final LatLng? driverLocation;
  final DateTime? estimatedDeliveryTime;

  OrderLocationModel({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.deliveryAddress,
    required this.deliveryLatitude, // Required but nullable
    required this.deliveryLongitude, // Required but nullable
    required this.status,
    required this.total,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.driverId,
    this.driverLocation,
    this.estimatedDeliveryTime,
  });

  factory OrderLocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse order status
    OrderStatus status;
    if (data['status'] is String) {
      final statusString = data['status'] as String;
      status = OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.$statusString',
        orElse: () => OrderStatus.pending,
      );
    } else {
      status = OrderStatus.pending;
    }

    // Parse items
    final List<OrderItem> items = [];
    if (data['items'] is List) {
      final itemsList = data['items'] as List;
      for (var item in itemsList) {
        if (item is Map<String, dynamic>) {
          items.add(OrderItem.fromMap(item));
        }
      }
    }

    // Parse driver location if available
    LatLng? driverLocation;
    if (data['driverLocation'] is GeoPoint) {
      final geoPoint = data['driverLocation'] as GeoPoint;
      driverLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
    }

    // Parse delivery location - use null instead of 0.0
    final double? deliveryLatitude = data['deliveryLatitude'] != null 
        ? (data['deliveryLatitude'] as num).toDouble() 
        : null;
    
    final double? deliveryLongitude = data['deliveryLongitude'] != null 
        ? (data['deliveryLongitude'] as num).toDouble() 
        : null;

    return OrderLocationModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      status: status,
      total: (data['total'] ?? 0.0).toDouble(),
      items: items,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      driverId: data['driverId'],
      driverLocation: driverLocation,
      estimatedDeliveryTime: data['estimatedDeliveryTime'] != null
          ? (data['estimatedDeliveryTime'] as Timestamp).toDate()
          : null,
    );
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
      'status': status.toString().split('.').last,
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
    OrderStatus? status,
    double? total,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? driverId,
    LatLng? driverLocation,
    DateTime? estimatedDeliveryTime,
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
    );
  }

  // Helper methods
  bool get isActive => status.index < OrderStatus.delivered.index;
  
  bool get isOutForDelivery => status == OrderStatus.outForDelivery;
  
  LatLng? get deliveryLatLng => (deliveryLatitude != null && deliveryLongitude != null)
      ? LatLng(deliveryLatitude!, deliveryLongitude!)
      : null;
  
  bool get hasLocation => deliveryLatitude != null && deliveryLongitude != null;

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
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
      deliveryLatitude: null, // Changed to null
      deliveryLongitude: null, // Changed to null
      status: OrderStatus.pending,
      total: 0.0,
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
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