import 'package:flutter/material.dart';

class ProductDetailItem extends StatelessWidget {
  final String title;
  final String value;

  const ProductDetailItem({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
