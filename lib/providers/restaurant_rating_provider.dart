// providers/restaurant_rating_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_rating_model.dart';

class RestaurantRatingProvider extends StateNotifier<List<RestaurantRating>> {
  RestaurantRatingProvider() : super([]);

  void addRating(RestaurantRating rating) {
    // Remove existing rating for this restaurant by same user
    state = state.where((r) => 
      !(r.restaurantId == rating.restaurantId && r.userName == rating.userName)
    ).toList();
    
    state = [...state, rating];
  }

  double getAverageRating(String restaurantId) {
    final ratings = state.where((r) => r.restaurantId == restaurantId).toList();
    if (ratings.isEmpty) return 0.0;
    
    final total = ratings.fold(0.0, (sum, rating) => sum + rating.rating);
    return total / ratings.length;
  }

  RestaurantRating? getUserRating(String restaurantId, String userName) {
    try {
      return state.firstWhere((r) => 
        r.restaurantId == restaurantId && r.userName == userName
      );
    } catch (e) {
      return null;
    }
  }

  List<RestaurantRating> getRestaurantRatings(String restaurantId) {
    return state.where((r) => r.restaurantId == restaurantId).toList();
  }

  int getRatingCount(String restaurantId) {
    return state.where((r) => r.restaurantId == restaurantId).length;
  }

  Map<int, int> getRatingDistribution(String restaurantId) {
    final ratings = getRestaurantRatings(restaurantId);
    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    for (final rating in ratings) {
      final star = rating.rating.floor();
      if (distribution.containsKey(star)) {
        distribution[star] = distribution[star]! + 1;
      }
    }
    
    return distribution;
  }
}

final restaurantRatingProvider = StateNotifierProvider<RestaurantRatingProvider, List<RestaurantRating>>((ref) {
  return RestaurantRatingProvider();
});