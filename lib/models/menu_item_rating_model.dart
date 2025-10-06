// models/menu_item_rating_model.dart
class MenuItemRating {
  final String menuItemId;
  final String restaurantId;
  final String userName;
  final double rating;
  final String? review;
  final DateTime timestamp;

  MenuItemRating({
    required this.menuItemId,
    required this.restaurantId,
    required this.userName,
    required this.rating,
    this.review,
    required this.timestamp,
  });

  DateTime? get date => null;

  String? get comment => null;

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'restaurantId': restaurantId,
      'userName': userName,
      'rating': rating,
      'review': review,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static MenuItemRating fromMap(Map<String, dynamic> map) {
    return MenuItemRating(
      menuItemId: map['menuItemId'],
      restaurantId: map['restaurantId'],
      userName: map['userName'],
      rating: map['rating'].toDouble(),
      review: map['review'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}