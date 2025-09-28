// favorite_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu_item_model.dart';

final favoriteProvider = NotifierProvider<FavoriteNotifier, Map<String, MenuItemModel>>(
  FavoriteNotifier.new,
);

class FavoriteNotifier extends Notifier<Map<String, MenuItemModel>> {
  @override
  Map<String, MenuItemModel> build() {
    return {};
  }

  void toggleFavorite(MenuItemModel item) {
    final isFavorite = state.containsKey(item.id);
    
    if (isFavorite) {
      state = {...state}..remove(item.id);
    } else {
      state = {...state, item.id: item};
    }
  }

  bool isFavorite(String itemId) {
    return state.containsKey(itemId);
  }

  void clearFavorites() {
    state = {};
  }
}