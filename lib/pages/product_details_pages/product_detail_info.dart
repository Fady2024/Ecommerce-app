import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/product.dart';
import '../../main.dart';
import '../../theme/text_glow.dart';
import 'ProductDetailItem.dart';

class ProductDetailInfo extends StatelessWidget {
  final Product product;
  final int remainingStock;

  const ProductDetailInfo({super.key, required this.product, required this.remainingStock});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowingText(
          text: product.title,
          intensity: 1, // Adjust intensity between 0.0 and 1.0 as needed
        ),


        Text("Description:",
            style: TextStyle(
                color: themeNotifier.themeMode == ThemeMode.light
                    ? Colors.black
                    : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(product.description,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[800])),
        const SizedBox(height: 16),
        ProductDetailItem(
            title: 'Category', value: product.category),
        ProductDetailItem(title: 'Brand', value: product.brand),
        ProductDetailItem(title: 'SKU', value: product.sku),
        ProductDetailItem(
            title: 'Weight', value: '${product.weight} kg'),
        ProductDetailItem(
            title: 'Dimensions', value: '${product.dimensions.depth}"D x ${product.dimensions.width}"W x ${product.dimensions.height}"H'),//Product Dimensions
        ProductDetailItem(
            title: 'Stock', value: '$remainingStock units'),
        ProductDetailItem(
            title: 'Warranty', value: product.warrantyInformation),
        ProductDetailItem(
            title: 'Shipping Info',
            value: product.shippingInformation),
        ProductDetailItem(
            title: 'Return Policy', value: product.returnPolicy),
      ],
    );
  }
}
