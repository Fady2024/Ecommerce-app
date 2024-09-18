import '../data/product.dart';
abstract class FavoritesAndCartState {
  const FavoritesAndCartState();

  List<Object> get props => [];
}

class FavoritesAndCartInitial extends FavoritesAndCartState {}

class FavoritesAndCartUpdated extends FavoritesAndCartState {
  final List<Product> shopItems;
  final List<Map<String, dynamic>> cartItems;
  final List<int> favoriteItemIds; // Use product IDs instead of Product objects
  final double totalPrice;

  const FavoritesAndCartUpdated({
    required this.shopItems,
    required this.cartItems,
    required this.favoriteItemIds,
    required this.totalPrice,
  });

  @override
  List<Object> get props => [shopItems, cartItems, favoriteItemIds, totalPrice,];
}

class FavoritesAndCartError extends FavoritesAndCartState {
  final String message;

  const FavoritesAndCartError(this.message);

  @override
  List<Object> get props => [message];
}
