import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled, readyForDelivery, delerved
}

class OrderItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String imageUrl;
  final String? specialInstructions;

  OrderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.specialInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'] ?? '',
      specialInstructions: map['specialInstructions'],
    );
  }

  double get total => price * quantity;

  double get totalPrice => price * quantity;
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImage;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final OrderStatus status;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String? specialInstructions;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedDeliveryTime;
  final DateTime? deliveredAt;
  final String? driverId;
  final String? driverName;
  final String? cancellationReason;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImage,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.discount,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.specialInstructions,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDeliveryTime,
    this.deliveredAt,
    this.driverId,
    this.driverName,
    this.cancellationReason,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse order status
    OrderStatus status;
    try {
      final statusString = data['status']?.toString() ?? 'pending';
      status = OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.$statusString',
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      status = OrderStatus.pending;
    }

    // Parse order items
    final List<OrderItem> items = [];
    final itemsData = data['items'] as List<dynamic>? ?? [];
    for (final itemData in itemsData) {
      if (itemData is Map<String, dynamic>) {
        items.add(OrderItem.fromMap(itemData));
      }
    }

    // Parse timestamps
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final estimatedDeliveryTime = (data['estimatedDeliveryTime'] as Timestamp?)?.toDate();
    final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();

    return OrderModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      userEmail: data['userEmail']?.toString() ?? '',
      userPhone: data['userPhone']?.toString() ?? '',
      restaurantId: data['restaurantId']?.toString() ?? '',
      restaurantName: data['restaurantName']?.toString() ?? '',
      restaurantImage: data['restaurantImage']?.toString() ?? '',
      items: items,
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      status: status,
      deliveryAddress: data['deliveryAddress']?.toString() ?? '',
      deliveryLatitude: (data['deliveryLatitude'] ?? 0.0).toDouble(),
      deliveryLongitude: (data['deliveryLongitude'] ?? 0.0).toDouble(),
      specialInstructions: data['specialInstructions']?.toString(),
      paymentMethod: data['paymentMethod']?.toString() ?? 'cash',
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      transactionId: data['transactionId']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      estimatedDeliveryTime: estimatedDeliveryTime,
      deliveredAt: deliveredAt,
      driverId: data['driverId']?.toString(),
      driverName: data['driverName']?.toString(),
      cancellationReason: data['cancellationReason']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImage': restaurantImage,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'specialInstructions': specialInstructions,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'estimatedDeliveryTime': estimatedDeliveryTime != null 
          ? Timestamp.fromDate(estimatedDeliveryTime!) 
          : null,
      'deliveredAt': deliveredAt != null 
          ? Timestamp.fromDate(deliveredAt!) 
          : null,
      'driverId': driverId,
      'driverName': driverName,
      'cancellationReason': cancellationReason,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? restaurantId,
    String? restaurantName,
    String? restaurantImage,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? discount,
    double? total,
    OrderStatus? status,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? specialInstructions,
    String? paymentMethod,
    String? paymentStatus,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? estimatedDeliveryTime,
    DateTime? deliveredAt,
    String? driverId,
    String? driverName,
    String? cancellationReason,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantImage: restaurantImage ?? this.restaurantImage,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  // Helper methods
  bool get isActive => ![
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ].contains(status);

  bool get canBeCancelled => [
    OrderStatus.pending,
    OrderStatus.confirmed,
  ].contains(status);

  Duration get estimatedTimeRemaining {
    if (estimatedDeliveryTime == null) return Duration.zero;
    final now = DateTime.now();
    return estimatedDeliveryTime!.isAfter(now) 
        ? estimatedDeliveryTime!.difference(now)
        : Duration.zero;
  }

  String get formattedStatus {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.readyForDelivery:
        // TODO: Handle this case.
        throw UnimplementedError();
      case OrderStatus.delerved:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedDeliveryFee => '\$${deliveryFee.toStringAsFixed(2)}';
  String get formattedTax => '\$${tax.toStringAsFixed(2)}';
  String get formattedDiscount => '\$${discount.toStringAsFixed(2)}';

  int get totalItems => items.fold(0, (int sum, OrderItem item) => sum + item.quantity);

  // Check if order is eligible for rating (delivered more than 1 hour ago)
  bool get canBeRated {
    if (status != OrderStatus.delivered || deliveredAt == null) return false;
    final now = DateTime.now();
    return now.difference(deliveredAt!).inHours >= 1;
  }
}