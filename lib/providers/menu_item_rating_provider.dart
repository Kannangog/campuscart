// providers/menu_item_rating_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_rating_model.dart';

class MenuItemRatingProvider extends StateNotifier<List<MenuItemRating>> {
  MenuItemRatingProvider() : super([]);

  void addRating(MenuItemRating rating) {
    // Remove existing rating for this menu item by same user
    state = state.where((r) => 
      !(r.menuItemId == rating.menuItemId && r.userName == rating.userName)
    ).toList();
    
    state = [...state, rating];
  }

  double getAverageRating(String menuItemId) {
    final ratings = state.where((r) => r.menuItemId == menuItemId).toList();
    if (ratings.isEmpty) return 0.0;
    
    final total = ratings.fold(0.0, (sum, rating) => sum + rating.rating);
    return total / ratings.length;
  }

  MenuItemRating? getUserRating(String menuItemId, String userName) {
    try {
      return state.firstWhere((r) => 
        r.menuItemId == menuItemId && r.userName == userName
      );
    } catch (e) {
      return null;
    }
  }

  List<MenuItemRating> getMenuItemRatings(String menuItemId) {
    return state.where((r) => r.menuItemId == menuItemId).toList();
  }

  List<MenuItemRating> getRestaurantMenuItemRatings(String restaurantId) {
    return state.where((r) => r.restaurantId == restaurantId).toList();
  }

  int getRatingCount(String menuItemId) {
    return state.where((r) => r.menuItemId == menuItemId).length;
  }

  Map<String, double> getRestaurantAverageRatings(String restaurantId) {
    final ratings = getRestaurantMenuItemRatings(restaurantId);
    final Map<String, List<double>> itemRatings = {};
    
    for (final rating in ratings) {
      if (!itemRatings.containsKey(rating.menuItemId)) {
        itemRatings[rating.menuItemId] = [];
      }
      itemRatings[rating.menuItemId]!.add(rating.rating);
    }
    
    final Map<String, double> averages = {};
    itemRatings.forEach((itemId, ratingsList) {
      final total = ratingsList.fold(0.0, (sum, rating) => sum + rating);
      averages[itemId] = total / ratingsList.length;
    });
    
    return averages;
  }

  Map<int, int> getRatingDistribution(String menuItemId) {
    final ratings = getMenuItemRatings(menuItemId);
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

final menuItemRatingProvider = StateNotifierProvider<MenuItemRatingProvider, List<MenuItemRating>>((ref) {
  return MenuItemRatingProvider();
});