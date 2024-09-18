import 'package:flutter/material.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import cached_network_image
import 'package:lottie/lottie.dart'; // Import the Lottie package
import 'dart:async';
import '../data/product.dart';
import '../main.dart';
import 'product_detail_page.dart';

class SearchPage extends StatefulWidget {
  final List<Product> allProducts;

  const SearchPage({
    Key? key,
    required this.allProducts,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';
  final FloatingSearchBarController _searchBarController = FloatingSearchBarController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchBarController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FloatingSearchBar(
                controller: _searchBarController,
                hint: 'Search for products...',
                scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
                transitionDuration: const Duration(milliseconds: 800),
                transitionCurve: Curves.easeInOut,
                physics: const BouncingScrollPhysics(),
                axisAlignment: 0.0,
                openAxisAlignment: 0.0,
                debounceDelay: const Duration(milliseconds: 500),
                onQueryChanged: _onSearchQueryChanged,
                onSubmitted: _onSearchQueryChanged,
                transition: CircularFloatingSearchBarTransition(),
                builder: (context, transition) {
                  return _buildAutocompleteDropdown();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteDropdown() {
    final filteredProducts = widget.allProducts.where((product) {
      final searchQueryLower = _searchQuery.toLowerCase();
      return product.title.toLowerCase().contains(searchQueryLower) ||
          product.tags.any((tag) => tag.toLowerCase().contains(searchQueryLower)) ||
          product.description.toLowerCase().contains(searchQueryLower);
    }).toList();

    if (filteredProducts.isEmpty) {
      final themeNotifier = Provider.of<ThemeNotifier>(context);
      return Container(
        padding: const EdgeInsets.all(8.0),
        color: themeNotifier.themeMode == ThemeMode.light
            ? Colors.white
            : Colors.black,
        child: const Center(
          child: Text(
            'No results found 😢',
            style: TextStyle(fontSize: 23),
          ),
        ),
      );
    }

    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeNotifier.themeMode == ThemeMode.light
              ? [Colors.blue.shade50, Colors.white]
              : [
            Colors.grey.shade700,
            Colors.black54,
            Colors.grey.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(12.0),
        child: SizedBox(
          height: 350.0, // Set a fixed height for the dropdown
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty ? product.images[0] : 'https://via.placeholder.com/150',
                    placeholder: (context, url) => Lottie.asset(
                      'lib/data/Animation - 1725548259633.json',
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: 20,
                      backgroundImage: imageProvider,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.contain, // Use BoxFit.cover to fill the avatar and maintain aspect ratio
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                title: Text(product.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$${product.price.toStringAsFixed(2)}'),
                    Text('Rating: ${product.rating} ⭐'),
                    Text('Stock: ${product.stock}'),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: product),
                    ),
                  );
                  _searchBarController.close();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
