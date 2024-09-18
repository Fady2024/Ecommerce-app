import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/product.dart';

class ProductDetailHeader extends StatelessWidget {
  final Product product;
  final bool isFavorite; // Pass the favorite status
  final void Function(Product) onFavoriteToggle; // Callback for favorite toggle

  const ProductDetailHeader({
    super.key,
    required this.product,
    required this.isFavorite, // Accept favorite status
    required this.onFavoriteToggle, // Accept callback
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: product.images.isNotEmpty ? product.images[0] : '',
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 16, // Position the icon in the upper right corner
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: () => onFavoriteToggle(product), // Call callback
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 30.0,
                      height: 30.0,
                      child: CircularProgressIndicator(
                        value: product.rating / 5, // Rating out of 5
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.yellow[700]!),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow[700],
                      size: 25,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.rating}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
