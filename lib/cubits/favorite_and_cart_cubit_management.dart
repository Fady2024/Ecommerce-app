import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../data/product.dart';
import '../data/data_service.dart';
import '../main.dart';
import 'favorites_and_cart_state_manager.dart';
class FadyCardCubit extends Cubit<FavoritesAndCartState> {
  final DataService _dataService = DataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final selectedLanguage = AppState().selectedLanguage; // Get the current language
  // References to user data in Firebase
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');

  FadyCardCubit() : super(FavoritesAndCartInitial()) {
    loadProducts();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadFavoriteProducts(user.email!); // Load favorites for the authenticated user
        loadCartProducts(); // Load cart items for the authenticated user
        transferGuestFavoritesToUser(); // Transfer favorites from guest to user
        _listenForFavoritesChanges(user.email!);
        _listenForCartChanges(user.email!);
      } else {
        // Handle guest logic if necessary
        _loadGuestFavorites(); // Load favorites for guest
      }
    });
    // Listen for language changes
    AppState().addListener(() {
      loadProducts(); // Reload products when language changes
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

  Future<void> loadProducts() async {
    try {
      final language = AppState().selectedLanguage; // Get the current language
      final products = await _dataService.loadProducts(language);
      _shopItems = products;
      emit(FavoritesAndCartUpdated(
        shopItems: _shopItems,
        cartItems: _cartItems,
        favoriteItemIds: _favoriteItemIds.toList(),
        totalPrice: _calculateTotal(),
      ));
    } catch (e) {
      emit(FavoritesAndCartError(selectedLanguage == 'Français'
          ? 'Échec du chargement des produits: ${e.toString()}'
          : 'Failed to load products: ${e.toString()}'));
    }
  }

  Future<void> _loadFavoriteProducts(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);
    final userFavoritesRef = _userRef.child('accountUsers').child(sanitizedEmail).child('favorites');

    try {
      final snapshot = await userFavoritesRef.get();
      _updateFavoriteIds(snapshot);
    } catch (error) {
      emit(FavoritesAndCartError(selectedLanguage == 'Français'
          ? 'Échec du chargement des produits favoris: ${error.toString()}'
          : 'Failed to load user favorite products: ${error.toString()}'));
    }
  }

  Future<void> _loadGuestFavorites() async {
    final deviceId = await _getDeviceId(); // Get device ID for guest
    final guestFavoritesRef = _userRef.child('guestUsers').child(deviceId).child('favorites');

    try {
      final snapshot = await guestFavoritesRef.get();
      _updateFavoriteIds(snapshot);
    } catch (error) {
      emit(FavoritesAndCartError(selectedLanguage == 'Français'
          ? 'Échec du chargement des produits favoris des invités: ${error.toString()}'
          : 'Failed to load guest favorite products: ${error.toString()}'));
    }
  }

  Future<void> _updateFavoriteIds(DataSnapshot snapshot) async {
    _favoriteItemIds.clear(); // Clear previous data
    final favoriteIds = snapshot.value;

    if (favoriteIds is List) {
      _favoriteItemIds.addAll(favoriteIds.map((id) => id as int));
    } else if (favoriteIds != null) {
      _favoriteItemIds.addAll([favoriteIds].map((id) => id as int));
    }

    emit(FavoritesAndCartUpdated(
      shopItems: _shopItems,
      cartItems: _cartItems,
      favoriteItemIds: _favoriteItemIds.toList(),
      totalPrice: _calculateTotal(),
    ));
  }

  Future<void> _listenForFavoritesChanges(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);
    final userFavoritesRef = _userRef.child('accountUsers').child(sanitizedEmail).child('favorites');

    userFavoritesRef.onValue.listen((event) {
      _updateFavoriteIds(event.snapshot);
    });
  }

  Future<String> _loadThemeDataFromFirebase(String email) async {
    final deviceId = await _getDeviceId(); // Get device ID for guest
    final userThemeRef = _userRef.child('guestUsers').child(deviceId).child('Theme Mode');

    try {
      final snapshot = await userThemeRef.get();
      if (snapshot.exists) {
        return snapshot.value as String; // Adjust based on your theme data structure
      }
    } catch (error) {
      emit(FavoritesAndCartError(selectedLanguage == 'Français'
          ? 'Échec du chargement du thème: ${error.toString()}'
          : 'Failed to load theme: ${error.toString()}'));
    }
    return ''; // Return a default value if theme data is not found or an error occurs
  }

  Future<void> transferGuestFavoritesToUser() async {
    final user = _auth.currentUser;
    final deviceId = await _getDeviceId(); // Get device ID for guest

    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      final userFavoritesRef = _userRef.child('accountUsers').child(sanitizedEmail).child('favorites');
      final guestFavoritesRef = _userRef.child('guestUsers').child(deviceId).child('favorites');

      try {
        // Fetch existing user favorites
        final userSnapshot = await userFavoritesRef.get();
        final userFavorites = userSnapshot.value is List
            ? List<int>.from((userSnapshot.value as List).map((item) => item as int))
            : <int>[]; // Initialize as an empty list if null or not a list

        // Fetch guest favorites
        final guestSnapshot = await guestFavoritesRef.get();
        final guestFavorites = guestSnapshot.value is List
            ? List<int>.from((guestSnapshot.value as List).map((item) => item as int))
            : <int>[]; // Initialize as an empty list if null or not a list

        // Combine favorites
        final combinedFavorites = <int>{...userFavorites, ...guestFavorites}; // Use a Set to avoid duplicates
        final themeData = await _loadThemeDataFromFirebase(user.email!);

        // Save combined favorites to user account
        await userFavoritesRef.set(combinedFavorites.toList());

        // Optionally save the theme data to the user's profile if needed
        final userThemeRef = _userRef.child('accountUsers').child(sanitizedEmail).child('Theme Mode');
        await userThemeRef.set(themeData); // Save theme data if needed
        await _userRef.child('accountUsers').child(sanitizedEmail).child('language').set(AppState().selectedLanguage=="Français"?'fr':'en');

        // Remove guest favorites
        await guestFavoritesRef.remove();
      } catch (error) {
        emit(FavoritesAndCartError(selectedLanguage == 'Français'
            ? 'Échec du transfert des favoris: ${error.toString()}'
            : 'Failed to transfer favorites: ${error.toString()}'));
      }
    }
  }

  Future<void> _saveFavoriteProducts() async {
    final user = _auth.currentUser;
    final deviceId = await _getDeviceId(); // Get device ID for guest

    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      final userFavoritesRef = _userRef.child('accountUsers').child(sanitizedEmail).child('favorites');
      await userFavoritesRef.set(_favoriteItemIds.toList());
    } else {
      final guestFavoritesRef = _userRef.child('guestUsers').child(deviceId).child('favorites');
      await guestFavoritesRef.set(_favoriteItemIds.toList());
    }
  }


  Future<void> loadCartProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      final userCartRef = _userRef.child('accountUsers').child(sanitizedEmail).child('carts');

      try {
        final snapshot = await userCartRef.get();
        _updateCartItems(snapshot);
      } catch (error) {
        emit(FavoritesAndCartError(selectedLanguage == 'Français'
            ? 'Échec du chargement des articles du panier: ${error.toString()}'
            : 'Failed to load cart products: ${error.toString()}'));
      }
    }
  }

  Future<void> _updateCartItems(DataSnapshot snapshot) async {
    _cartItems.clear();
    final cartData = snapshot.value as List<dynamic>?;
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
    }

    emit(FavoritesAndCartUpdated(
      shopItems: _shopItems,
      cartItems: _cartItems,
      favoriteItemIds: _favoriteItemIds.toList(),
      totalPrice: _calculateTotal(),
    ));
  }

  Future<void> _listenForCartChanges(String email) async {
    final sanitizedEmail = _sanitizeEmail(email);
    final userCartRef = _userRef.child('accountUsers').child(sanitizedEmail).child('carts');

    userCartRef.onValue.listen((event) {
      _updateCartItems(event.snapshot);
    });
  }


  Future<void> _saveCartProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final sanitizedEmail = _sanitizeEmail(user.email!);
      final userCartRef = _userRef.child('accountUsers').child(sanitizedEmail).child('carts');

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
    final user = _auth.currentUser; // Check if the user is logged in

    if (user != null) {
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
        emit(FavoritesAndCartError(selectedLanguage == 'Français'
            ? 'Ce produit est déjà dans le panier.'
            : 'This product is already in the cart.'));
      }
    } else {
      // User is not logged in
      emit(FavoritesAndCartError(selectedLanguage == 'Français'
          ? '🌟 Vous devez vous connecter pour ajouter des articles à votre panier ! 🛒✨ Veuillez vous inscrire ou vous connecter pour commencer à magasiner et profiter des avantages exclusifs ! 🎉'
          : '🌟 You need to be logged in to add items to your cart! 🛒✨ Please sign up or log in to start shopping and enjoy exclusive benefits! 🎉'
      ));
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
        emit(FavoritesAndCartError(selectedLanguage == 'Français'
            ? 'Impossible d\'ajouter plus de $availableStock articles au panier.'
            : 'Cannot add more than $availableStock items to the cart.'));
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
    return email.replaceAll(RegExp(r'[.#$[\]]'), ',');
  }
  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId = '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceId = _sanitizeEmail(androidInfo.id); // Unique ID on Android
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosInfo.identifierForVendor!; // Unique ID on iOS
    }
    return deviceId;
  }
}


