import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferType { percentage, fixed, buyOneGetOne }

class OfferModel {
  final String id;
  final String restaurantId;
  final String title;
  final String description;
  final OfferType type;
  final double value;
  final double minimumOrder;
  final String? imageUrl;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final int usageLimit;
  final int usageCount;
  final List<String> applicableItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  OfferModel({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.minimumOrder = 0.0,
    this.imageUrl,
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    this.usageLimit = 0,
    this.usageCount = 0,
    this.applicableItems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: OfferType.values.firstWhere(
        (e) => e.toString() == 'OfferType.${data['type']}',
        orElse: () => OfferType.percentage,
      ),
      value: (data['value'] ?? 0.0).toDouble(),
      minimumOrder: (data['minimumOrder'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      usageLimit: data['usageLimit'] ?? 0,
      usageCount: data['usageCount'] ?? 0,
      applicableItems: List<String>.from(data['applicableItems'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'value': value,
      'minimumOrder': minimumOrder,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'applicableItems': applicableItems,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (usageLimit == 0 || usageCount < usageLimit);
  }

  double calculateDiscount(double orderTotal) {
    if (!isValid || orderTotal < minimumOrder) return 0.0;

    switch (type) {
      case OfferType.percentage:
        return orderTotal * (value / 100);
      case OfferType.fixed:
        return value;
      case OfferType.buyOneGetOne:
        return 0.0; // Special handling required
    }
  }

  OfferModel copyWith({
    String? title,
    String? description,
    OfferType? type,
    double? value,
    double? minimumOrder,
    String? imageUrl,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    int? usageLimit,
    int? usageCount,
    List<String>? applicableItems,
    DateTime? updatedAt,
  }) {
    return OfferModel(
      id: id,
      restaurantId: restaurantId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      applicableItems: applicableItems ?? this.applicableItems,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}