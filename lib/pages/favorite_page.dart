import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../data/product.dart';
import '../cubits/favorite_and_cart_cubit_management.dart';
import '../cubits/favorites_and_cart_state_manager.dart';
import '../main.dart';
import 'product_detail_Page.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FadyCardCubit, FavoritesAndCartState>(
      listener: (context, state) {
        // Optionally, handle specific states here
      },
      builder: (context, state) {
        final themeNotifier = Provider.of<ThemeNotifier>(context);

        if (state is FavoritesAndCartUpdated) {
          final favoriteItemIds = state.favoriteItemIds;
          final shopItems = state.shopItems;

          // Filter favorite products based on favoriteItemIds
          final favoriteProducts = shopItems
              .where((product) => favoriteItemIds.contains(product.id))
              .toList();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Favorite Items'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: themeNotifier.themeMode == ThemeMode.light
                            ? Colors.black
                            : Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: Icon(
                        themeNotifier.themeMode == ThemeMode.light
                            ? Icons.nightlight_round
                            : Icons.wb_sunny,
                      ),
                      onPressed: () {
                        themeNotifier.toggleTheme();
                      },
                    ),
                  ),
                ),
              ],
            ),
            body: favoriteProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 100,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No favorite items yet!',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.75,
                    ),
                    padding: const EdgeInsets.all(12.0),
                    itemCount: favoriteProducts.length,
                    itemBuilder: (context, index) {
                      final product = favoriteProducts[index];
                      return FavoriteProductCard(
                        product: product,
                        onRemoveFavorite: () {
                          context.read<FadyCardCubit>().toggleFavorite(product);
                        },
                      );
                    },
                  ),
          );
        } else {
          // Show a loading indicator or handle other states
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class FavoriteProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRemoveFavorite;

  const FavoriteProductCard({
    super.key,
    required this.product,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final double originalPrice = product.price;
    final double discountPercentage = product.discountPercentage;
    final double discountedPrice =
        originalPrice * (1 - discountPercentage / 100);
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeNotifier.themeMode == ThemeMode.light
              ? [Colors.blue.shade50, Colors.white]
              : [
                  Colors.grey[750] ?? Colors.grey.shade700,
                  Colors.black54,
                  Colors.grey[850] ?? Colors.grey.shade900,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: product),
                    ),
                  );
                },
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty
                        ? product.images[0]
                        : 'https://via.placeholder.com/150',
                    fit: BoxFit.cover,
                    placeholder: (BuildContext context, String url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget:
                        (BuildContext context, String url, dynamic error) =>
                            Center(
                      child: Image.network('https://via.placeholder.com/150',
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            product.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Row(
                  children: [
                    Text(
                      '\$${discountedPrice.toStringAsFixed(2)}  ',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.red),
                    ),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 12,
                            color: Colors.grey[700],
                            decoration: TextDecoration.lineThrough,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white),
                onPressed: onRemoveFavorite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
