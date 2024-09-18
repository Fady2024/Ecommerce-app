import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../data/product.dart';
import '../data/data_service.dart';
import 'favorites_and_cart_state_manager.dart';

class FadyCardCubit extends Cubit<FavoritesAndCartState> {
  final DataService _dataService = DataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _favoritesRef =
      FirebaseDatabase.instance.ref().child('favorites');
  final DatabaseReference _cartRef =
      FirebaseDatabase.instance.ref().child('carts'); // Add this line

  FadyCardCubit() : super(FavoritesAndCartInitial()) {
    _loadProducts();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadFavoriteProducts(); // Load favorites for the new user
        loadCartProducts(); // Load cart items for the new user
      }
    });
  }

  List<Product> _shopItems = [];
  final List<Map<String, dynamic>> _cartItems = [];
  final Set<int> _favoriteItemIds = {};

  List<Product> get shopItems => _shopItems;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<Product> get favoriteItems => _shopItems
      .where((product) => _favoriteItemIds.contains(product.id))
      .toList();

  Future<void> _loadProducts() async {
    try {
      final products = await _dataService.loadProducts();
      _shopItems = products;
      emit(FavoritesAndCartUpdated(
        shopItems: _shopItems,
        cartItems: _cartItems,
        favoriteItemIds: _favoriteItemIds.toList(),
        totalPrice: _calculateTotal(),
      ));
    } catch (e) {
      emit(FavoritesAndCartError('Failed to load products: ${e.toString()}'));
    }
  }

  Future<void> _loadFavoriteProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      final userFavoritesRef = _favoritesRef.child(sanitizedEmail);

      try {
        final snapshot = await userFavoritesRef.get();
        final favoriteIds = snapshot.value;
        _favoriteItemIds.clear(); // Clear previous data

        if (favoriteIds is List) {
          _favoriteItemIds.addAll(favoriteIds.map((id) => id as int));
        } else if (favoriteIds != null) {
          _favoriteItemIds.addAll([favoriteIds].map((id) => id as int));
        }

        // Emit the updated state
        emit(FavoritesAndCartUpdated(
          shopItems: _shopItems,
          cartItems: _cartItems,
          favoriteItemIds: _favoriteItemIds.toList(),
          totalPrice: _calculateTotal(),
        ));
      } catch (error) {
        emit(FavoritesAndCartError(
            'Failed to load favorite products: ${error.toString()}'));
      }
    }
  }

  Future<void> _saveFavoriteProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      final userFavoritesRef = _favoritesRef.child(sanitizedEmail);

      await userFavoritesRef.set(_favoriteItemIds.toList());
    }
  }

  Future<void> loadCartProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      final userCartRef = _cartRef.child(sanitizedEmail);

      try {
        final snapshot = await userCartRef.get();
        final cartData = snapshot.value as List<dynamic>?;
        _cartItems.clear();
        if (cartData != null) {
          for (var item in cartData) {
            final itemData = item as Map<dynamic, dynamic>;
            final productId = itemData['productId'] as int;
            final quantity = itemData['quantity'] as int;

            final product = _shopItems.firstWhere(
                  (product) => product.id == productId,
            );
            _cartItems.add({
              'item': product,
              'quantity': quantity,
            });
          }
          print('Cart items loaded: $_cartItems'); // Add this for debugging
        } else {
          print('Cart is empty.');
        }

        emit(FavoritesAndCartUpdated(
          shopItems: _shopItems,
          cartItems: _cartItems,
          favoriteItemIds: _favoriteItemIds.toList(),
          totalPrice: _calculateTotal(),
        ));
      } catch (error) {
        emit(FavoritesAndCartError('Failed to load cart products: ${error.toString()}'));
      }
    }
  }

  Future<void> _saveCartProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      final userCartRef = _cartRef.child(sanitizedEmail);

      final cartData = _cartItems.map((item) {
        final product = item['item'] as Product;
        final quantity = item['quantity'] as int;
        return {
          'productId': product.id,
          'quantity': quantity,
        };
      }).toList();

      print('Saving cart data to Firebase: $cartData'); // Add this for debugging

      await userCartRef.set(cartData);
    }
  }


  void addItemToCart(int index) {
    final item = _shopItems[index];
    final existingItemIndex = _cartItems.indexWhere(
      (element) => element['item'] == item,
    );

    if (existingItemIndex == -1) {
      _cartItems.add({
        'item': item,
        'quantity': 1,
      });

      emit(FavoritesAndCartUpdated(
        shopItems: _shopItems,
        cartItems: _cartItems,
        favoriteItemIds: _favoriteItemIds.toList(),
        totalPrice: _calculateTotal(),
      ));

      _saveCartProducts(); // Save updated cart to Firebase
    } else {
      emit(FavoritesAndCartError('This product is already in the cart.'));
    }
  }

  void incrementItemQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      final cartItem = _cartItems[index];
      final product = cartItem['item'] as Product;
      final currentQuantity = cartItem['quantity'] as int;
      final availableStock =
          _shopItems.firstWhere((item) => item == product).stock;

      if (currentQuantity < availableStock) {
        _cartItems[index]['quantity'] = currentQuantity + 1;
        emit(FavoritesAndCartUpdated(
          shopItems: _shopItems,
          cartItems: _cartItems,
          favoriteItemIds: _favoriteItemIds.toList(),
          totalPrice: _calculateTotal(),
        ));

        _saveCartProducts(); // Save updated cart to Firebase
      } else {
        emit(FavoritesAndCartError(
            'Cannot add more than $availableStock items to the cart.'));
      }
    }
  }

  void decrementItemQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      final cartItem = _cartItems[index];
      final currentQuantity = cartItem['quantity'] as int;

      if (currentQuantity > 1) {
        _cartItems[index]['quantity'] = currentQuantity - 1;
      } else {
        _cartItems.removeAt(index);
      }

      emit(FavoritesAndCartUpdated(
        shopItems: _shopItems,
        cartItems: _cartItems,
        favoriteItemIds: _favoriteItemIds.toList(),
        totalPrice: _calculateTotal(),
      ));

      _saveCartProducts(); // Save updated cart to Firebase
    }
  }

  /* void removeItemFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      emit(FadyCardUpdated(
        shopItems: _shopItems,
        cartItems: _cartItems,
        favoriteItemIds: _favoriteItemIds.toList(),
        totalPrice: _calculateTotal(),
      ));

      _saveCartProducts(); // Save updated cart to Firebase
    }
  }
*/
  void clearCard() {
    _cartItems.clear();
    emit(FavoritesAndCartUpdated(
      shopItems: _shopItems,
      cartItems: _cartItems,
      favoriteItemIds: _favoriteItemIds.toList(),
      totalPrice: _calculateTotal(),
    ));
  }

  void toggleFavorite(Product product) {
    final productId = product.id;
    if (_favoriteItemIds.contains(productId)) {
      _favoriteItemIds.remove(productId);
    } else {
      _favoriteItemIds.add(productId);
    }

    emit(FavoritesAndCartUpdated(
      shopItems: _shopItems,
      cartItems: _cartItems,
      favoriteItemIds: _favoriteItemIds.toList(),
      totalPrice: _calculateTotal(),
    ));

    _saveFavoriteProducts(); // Save updated favorites to Firebase
  }

  void clearFavorites() {
    _favoriteItemIds.clear();
    emit(FavoritesAndCartUpdated(
      shopItems: _shopItems,
      cartItems: _cartItems,
      favoriteItemIds: _favoriteItemIds.toList(),
      totalPrice: _calculateTotal(),
    ));
  }

  double _calculateTotal() {
    double totalPrice = 0;
    for (var item in _cartItems) {
      final product = item['item'] as Product;
      final quantity = item['quantity'] as int;
      totalPrice +=
          (product.price * (1 - (product.discountPercentage / 100))) * quantity;
    }
    return totalPrice;
  }

  String _sanitizeEmail(String email) {
    // Replace invalid characters in the email
    return email.replaceAll(RegExp(r'[.#$[\]]'), '_');
  }
}
