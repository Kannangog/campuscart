import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  readyForDelivery,
  outForDelivery,
  delivered,
  cancelled, delerved,
  // Removed the duplicate 'delerved' status
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
      quantity: map['quantity']?.toInt() ?? 1,
      imageUrl: map['imageUrl'] ?? '',
      specialInstructions: map['specialInstructions'],
    );
  }

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
  final double convenienceFee;
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
  final String? cancelledBy;
  final String? foodImageUrl; // Added foodImageUrl field

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
    required this.convenienceFee,
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
    this.cancelledBy,
    this.foodImageUrl, // Added to constructor
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse order status - handle string to enum conversion
    final statusString = data['status']?.toString() ?? 'pending';
    OrderStatus status;
    
    try {
      // Handle both enum name string and legacy string values
      if (statusString.startsWith('OrderStatus.')) {
        // Remove 'OrderStatus.' prefix if present
        final cleanStatusString = statusString.replaceFirst('OrderStatus.', '');
        status = OrderStatus.values.firstWhere(
          (e) => e.toString() == 'OrderStatus.$cleanStatusString',
          orElse: () => OrderStatus.pending,
        );
      } else {
        // Handle direct enum name values
        status = OrderStatus.values.firstWhere(
          (e) => e.name == statusString,
          orElse: () => _parseLegacyStatus(statusString),
        );
      }
    } catch (e) {
      // Fallback for any parsing errors
      status = _parseLegacyStatus(statusString);
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
      convenienceFee: (data['convenienceFee'] ?? 5.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      status: status,
      deliveryAddress: data['deliveryAddress']?.toString() ?? '',
      deliveryLatitude: (data['deliveryLatitude'] ?? 0.0).toDouble(),
      deliveryLongitude: (data['deliveryLongitude'] ?? 0.0).toDouble(),
      specialInstructions: data['specialInstructions']?.toString(),
      paymentMethod: data['paymentMethod']?.toString() ?? 'Cash on Delivery',
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      transactionId: data['transactionId']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      estimatedDeliveryTime: estimatedDeliveryTime,
      deliveredAt: deliveredAt,
      driverId: data['driverId']?.toString(),
      driverName: data['driverName']?.toString(),
      cancellationReason: data['cancellationReason']?.toString(),
      cancelledBy: data['cancelledBy']?.toString(),
      foodImageUrl: data['foodImageUrl']?.toString(), // Added
    );
  }

  // Helper method to parse legacy status strings
  static OrderStatus _parseLegacyStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'delivered':
      case 'delerved': // Handle typo in legacy data - map to delivered
        return OrderStatus.delivered;
      case 'readyfordelivery':
      case 'ready_for_delivery':
        return OrderStatus.readyForDelivery;
      case 'outfordelivery':
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      default:
        return OrderStatus.pending;
    }
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
      'convenienceFee': convenienceFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status.name,
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
      'cancelledBy': cancelledBy,
      'foodImageUrl': foodImageUrl, // Added
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
    double? convenienceFee,
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
    String? cancelledBy,
    String? foodImageUrl, // Added
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
      convenienceFee: convenienceFee ?? this.convenienceFee,
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
      cancelledBy: cancelledBy ?? this.cancelledBy,
      foodImageUrl: foodImageUrl ?? this.foodImageUrl, // Added
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
      case OrderStatus.readyForDelivery:
        return 'Ready for Delivery';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.delerved:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  // Fixed currency formatting to use rupees instead of dollars
  String get formattedTotal => '₹${total.toStringAsFixed(2)}';
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';
  String get formattedDeliveryFee => '₹${deliveryFee.toStringAsFixed(2)}';
  String get formattedConvenienceFee => '₹${convenienceFee.toStringAsFixed(2)}';
  String get formattedTax => '₹${tax.toStringAsFixed(2)}';
  String get formattedDiscount => '₹${discount.toStringAsFixed(2)}';

  int get totalItems => items.fold(0, (int sum, OrderItem item) => sum + item.quantity);

  // Check if order is eligible for rating (delivered more than 1 hour ago)
  bool get canBeRated {
    if (status != OrderStatus.delivered || deliveredAt == null) return false;
    final now = DateTime.now();
    return now.difference(deliveredAt!).inHours >= 1;
  }
  
  // Additional helper method to get status priority for sorting
  int get statusPriority {
    switch (status) {
      case OrderStatus.pending:
        return 1;
      case OrderStatus.confirmed:
        return 2;
      case OrderStatus.preparing:
        return 3;
      case OrderStatus.ready:
        return 4;
      case OrderStatus.readyForDelivery:
        return 5;
      case OrderStatus.outForDelivery:
        return 6;
      case OrderStatus.delivered:
        return 7;
      case OrderStatus.cancelled:
        return 0;
      case OrderStatus.delerved:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
  
  // Get the next expected status in the workflow
  OrderStatus? get nextStatus {
    switch (status) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.readyForDelivery;
      case OrderStatus.readyForDelivery:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
      case OrderStatus.delerved:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
  
  // Get the progress percentage (0.0 to 1.0)
  double get progressPercentage {
    const totalSteps = 6; // pending to delivered
    final currentStep = statusPriority.clamp(1, totalSteps);
    return currentStep / totalSteps;
  }

  // Check if order was cancelled by customer
  bool get isCancelledByCustomer => cancelledBy?.toLowerCase() == 'customer';
  
  // Check if order was cancelled by restaurant
  bool get isCancelledByRestaurant => cancelledBy?.toLowerCase() == 'restaurant';
  
  // Check if order was cancelled by admin/support
  bool get isCancelledByAdmin => cancelledBy?.toLowerCase() == 'admin';
  
  // Get cancellation source text for display
  String get cancellationSource {
    if (cancelledBy == null) return 'Unknown';
    switch (cancelledBy!.toLowerCase()) {
      case 'customer':
        return 'Customer';
      case 'restaurant':
        return 'Restaurant';
      case 'admin':
        return 'Support Team';
      default:
        return cancelledBy!;
    }
  }
}