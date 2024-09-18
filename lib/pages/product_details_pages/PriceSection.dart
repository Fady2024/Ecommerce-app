import 'package:flutter/material.dart';
import '../../data/product.dart';
import 'DiagonalLinePainter.dart';

class PriceSection extends StatelessWidget {
  final double originalPrice;
  final double discountedPrice;
  final Product product;
  final void Function(Product) onAddToCart; // Callback function
  final int remainingStock; // Add remainingStock parameter

  const PriceSection({
    super.key,
    required this.originalPrice,
    required this.discountedPrice,
    required this.product,
    required this.onAddToCart,
    required this.remainingStock, // Initialize remainingStock
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Original Price
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                topLeft: Radius.circular(12),
              )),
          child: Column(
            children: [
              const Text(
                'Original Price',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Text(
                    '\$${originalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DiagonalLinePainter(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // New Price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${discountedPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Add to Cart Button
        GestureDetector(
          onTap: () => onAddToCart(product),
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(12),
                  topRight: Radius.circular(12),
                )),
            child: Center(
              child: remainingStock > 0
                  ? const Icon(
                Icons.check,
                color: Colors.yellow,
                size: 30,
              )
                  : const Text(
                '😢', // Sad emoji
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
