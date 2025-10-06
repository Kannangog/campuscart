// models/restaurant_rating_model.dart
class RestaurantRating {
  final String restaurantId;
  final String userName;
  final double rating;
  final String? review;
  final DateTime timestamp;

  RestaurantRating({
    required this.restaurantId,
    required this.userName,
    required this.rating,
    this.review,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'userName': userName,
      'rating': rating,
      'review': review,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static RestaurantRating fromMap(Map<String, dynamic> map) {
    return RestaurantRating(
      restaurantId: map['restaurantId'],
      userName: map['userName'],
      rating: map['rating'].toDouble(),
      review: map['review'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}