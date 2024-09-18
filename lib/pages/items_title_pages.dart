import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product.dart';
import '../main.dart';
import 'product_detail_page.dart'; // Import your product detail page
class ItemsTitle extends StatelessWidget {
  final Product product;
  final VoidCallback onPressed;
  final VoidCallback onFavoritePressed;
  final String buttonText; // New parameter for button text

  const ItemsTitle({
    super.key,
    required this.product,
    required this.onPressed,
    required this.onFavoritePressed,
    required this.buttonText, // Required for conditional text
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final double originalPrice = product.price;
    final double discountPercentage = product.discountPercentage;
    final double discountedPrice = originalPrice * ( 1-discountPercentage / 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          );
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeNotifier.themeMode == ThemeMode.light
                      ? [Colors.blue.shade50, Colors.white]
                      : [Colors.black54, Colors.grey[850]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200.0,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child:
                          CachedNetworkImage(
                            imageUrl: product.images.isNotEmpty ? product.images[0] : 'https://via.placeholder.com/150',
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) {
                              if (kDebugMode) {
                                print('Image load error: $error');
                              }
                              return const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      product.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,color: themeNotifier.themeMode == ThemeMode.light
                          ? Colors.black
                          : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Text(
                          '\$${discountedPrice.toStringAsFixed(2)}  ',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 14,fontWeight: FontWeight.w700,color: Colors.red
                          ),
                        ),Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 12,color: Colors.grey[700],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(buttonText), // Use buttonText parameter
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
