import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loginpage/main.dart';
import 'package:loginpage/pages/product_detail_Page.dart';

import '../cubits/favorite_and_cart_cubit_management.dart';
import '../cubits/favorites_and_cart_state_manager.dart';
import '../data/product.dart';
import 'items_title_pages.dart';

class SortingPage extends StatelessWidget {
  final String selectedCategory; // Add this
  final String selectedFilter; // Add this
  final ScrollController productScrollController; // Pass the scroll controller
  final ThemeNotifier themeNotifier;
  final String name; // Add this

  const SortingPage({
    super.key,
    required this.selectedCategory,
    required this.selectedFilter,
    required this.productScrollController,
    required this.themeNotifier,
    required this.name,
  });
  @override
  Widget build(BuildContext context) {
    void _toggleFavorite(Product product) {
      final cubit = context.read<FadyCardCubit>();
      cubit.toggleFavorite(product);
    }

    return BlocBuilder<FadyCardCubit, FavoritesAndCartState>(
      builder: (context, state) {
        if (state is FavoritesAndCartUpdated) {
          var filteredProducts = state.shopItems.where((product) {
            return selectedCategory == 'all' ||
                product.category.toLowerCase() == selectedCategory;
          }).toList();
          if (name == 'FS') {
            // Apply the selected filter
            if (selectedFilter == 'Price Low to High') {
              filteredProducts.sort((a, b) => a.price.compareTo(b.price));
            } else if (selectedFilter == 'Price High to Low') {
              filteredProducts.sort((a, b) => b.price.compareTo(a.price));
            } else if (selectedFilter == 'Rating Low to High') {
              filteredProducts.sort((a, b) => a.rating.compareTo(b.rating));
            } else if (selectedFilter == 'Rating High to Low') {
              filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
            } else if (selectedFilter == 'Name A-Z') {
              filteredProducts.sort((a, b) => a.title.compareTo(b.title));
            } else if (selectedFilter == 'Name Z-A') {
              filteredProducts.sort((a, b) => b.title.compareTo(a.title));
            }
          }
          if (name == 'BDA') {
            // Sort by discounted price from high to low
            filteredProducts.sort((a, b) {
              double discountedPriceA = (a.discountPercentage);
              double discountedPriceB = (b.discountPercentage);
              return discountedPriceB
                  .compareTo(discountedPriceA); // Descending order
            });
          }
          if (name == 'BS') {
            filteredProducts.sort((a, b) {
              double discountedPriceA =
              (a.price * (a.discountPercentage / 100));
              double discountedPriceB =
              (b.price * (b.discountPercentage / 100));
              return discountedPriceB
                  .compareTo(discountedPriceA); // Descending order
            });
          }

            return SizedBox(
            height: 320.0,
            child: ListView.builder(
              controller: productScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final cartItem = state.cartItems.firstWhere(
                  (item) => item['item'] == product,
                  orElse: () => {'quantity': 0},
                );
                final int quantityInCart = cartItem['quantity'] as int;
                final int remainingStock = product.stock - quantityInCart;
                final isFavorite = state.favoriteItemIds.contains(product.id);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  width: 250.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailPage(product: product),
                              ),
                            );
                          },
                          child: ItemsTitle(
                            product: product,
                            onPressed: () {
                              final cartItems =
                                  context.read<FadyCardCubit>().cartItems;
                              final isInCart = cartItems
                                  .any((item) => item['item'] == product);

                              // Get the current user
                              final user = FirebaseAuth.instance.currentUser;

                              if (user == null) {
                                // User is not logged in
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      '🌟 You need to be logged in to add items to your cart! 🛒✨ Please sign up or log in to start shopping and enjoy exclusive benefits! 🎉',
                                      style: TextStyle(
                                          fontSize:
                                              16), // Adjust font size if needed
                                    ),
                                    backgroundColor: const Color(
                                        0xFF175E19), // Use a solid color for background
                                    duration: const Duration(
                                        seconds: 2), // Set duration to 1 second
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          12), // Rounded corners
                                    ),
                                    behavior: SnackBarBehavior
                                        .floating, // Make the SnackBar float above the content
                                  ),
                                );
                              } else if (isInCart) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      remainingStock > 0
                                          ? "This item is already in your cart."
                                          : "No more stock available for this item.",
                                    ),
                                  ),
                                );
                              } else if (remainingStock > 0) {
                                context
                                    .read<FadyCardCubit>()
                                    .addItemToCart(product.id - 1);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "No more stock available for this item."),
                                  ),
                                );
                              }
                            },
                            onFavoritePressed: () => _toggleFavorite(product),
                            buttonText: remainingStock > 0
                                ? 'Add to Cart'
                                : 'Out of Stock',
                          )),
                      Positioned(
                        top: 265,
                        right: 18,
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () => _toggleFavorite(product),
                        ),
                      ),
                      Positioned(
                        top: 13,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                8.0), // Optional: for rounded corners
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 30.0, // Adjust size as needed
                                    height: 30.0, // Adjust size as needed
                                    child: CircularProgressIndicator(
                                      value:
                                          product.rating / 5, // Rating out of 5
                                      strokeWidth: 2.0, // Border width
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.yellow[700]!),
                                      backgroundColor: Colors
                                          .transparent, // Hide background color
                                    ),
                                  ),
                                  Icon(
                                    Icons.star,
                                    color: Colors.yellow[700],
                                    size: 25,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                  height:
                                      4), // Space between the star and the text
                              Text(
                                '${product.rating}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: themeNotifier.themeMode ==
                                              ThemeMode.light
                                          ? Colors.black
                                          : Colors
                                              .white, // Text color for contrast
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: remainingStock > 10
                                ? Colors.green // In stock
                                : remainingStock > 0
                                    ? Colors.orange // Low stock
                                    : Colors.red, // No stock left
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            remainingStock > 10
                                ? 'In Stock: $remainingStock'
                                : remainingStock > 0
                                    ? 'Low Stock: $remainingStock'
                                    : 'Out of Stock',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ),
                      Positioned(
                          bottom: 100,
                          left: 0,
                          child: Image.asset(
                            "assets/sales.png",
                            width: 100,
                          )),
                      Positioned(
                          bottom: product.discountPercentage >= 10 ? 160 : 164,
                          left: 4,
                          child: Text(
                            '${product.discountPercentage >= 10 ? product.discountPercentage.toStringAsFixed(0) : product.discountPercentage.toStringAsFixed(1)}%  ',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: product.discountPercentage >= 10
                                  ? 14.0
                                  : 12.0, // Adjust sizes as needed
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
