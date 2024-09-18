import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:provider/provider.dart';
import '../cubits/favorite_and_cart_cubit_management.dart';
import '../cubits/favorites_and_cart_state_manager.dart';
import '../data/product.dart';
import '../main.dart';
import '../widgets/category_circle.dart';
import 'items_title_pages.dart';
import 'product_detail_page.dart';
import 'search_page.dart'; // Import the SearchPage

class HorizontalPreviewPage extends StatefulWidget {
  const HorizontalPreviewPage({super.key});

  @override
  HorizontalPreviewPageState createState() => HorizontalPreviewPageState();
}

class HorizontalPreviewPageState extends State<HorizontalPreviewPage> {
  late final List<Product> products;
  String _selectedCategory = 'all'; // Default category
  String _selectedFilter = 'None'; // Default filter
  final ScrollController _categoryScrollController =
      ScrollController(); // ScrollController to control the categories ListView
  final ScrollController _productScrollController =
      ScrollController(); // ScrollController to control the products ListView

  void _toggleFavorite(Product product) {
    final cubit = context.read<FadyCardCubit>();
    cubit.toggleFavorite(product);
  }

  void _scrollToCategory(int index) {
    final double offset =
        index * 170.0; // Adjust the offset based on the category item width
    _categoryScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToFirstProduct() {
    _productScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  final List<Map<String, String>> _categoryImages = [
    {'label': 'All Items', 'image': 'assets/b-all.png'},
    {'label': 'Beauty', 'image': 'assets/make-up.png'},
    {'label': 'Fragrances', 'image': 'assets/perfume.png'},
    {'label': 'Furniture', 'image': 'assets/armchair.png'},
    {'label': 'Groceries', 'image': 'assets/basket.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),Text(
                              'Find anything what you want!',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600], // Add grey color here
                              ),
                            ),

                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(border: Border.all(color: themeNotifier.themeMode == ThemeMode.light
                                  ? Colors.black
                                  : Colors.white,),borderRadius: BorderRadius.circular(15)),
                              child: IconButton(
                                icon: const Icon(Icons.search, size: 30),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchPage(
                                        allProducts: (context
                                            .read<FadyCardCubit>()
                                            .state as FavoritesAndCartUpdated)
                                            .shopItems,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                             SizedBox(width: 5,),
                             Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    color: themeNotifier.themeMode == ThemeMode.light
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(15)),
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
                          ],
                        ),

                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              BlocBuilder<FadyCardCubit, FavoritesAndCartState>(
                builder: (context, state) {
                  if (state is FavoritesAndCartUpdated) {
                    return SizedBox(
                      height: 250, // Adjust height as needed
                      child: FlutterCarousel(
                        options: CarouselOptions(
                          height: 200.0, // This height should match the SizedBox height if needed
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 5),
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.8,
                        ),
                        items: _categoryImages.map((category) {
                          final isAllItems = category['label'] == 'All Items';
                          final categoryProducts = isAllItems
                              ? state.shopItems
                              : state.shopItems.where((product) =>
                          product.category.toLowerCase() ==
                              category['label']!.toLowerCase()).toList();

                          final maxDiscount = isAllItems
                              ? 0
                              : categoryProducts.isNotEmpty
                              ? categoryProducts
                              .map((product) => product.discountPercentage)
                              .reduce((a, b) => a > b ? a : b)
                              : 0;

                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(category['image']!),
                                    fit: BoxFit.scaleDown,
                                  ),
                                ),
                              ),
                              if (!isAllItems)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      '${maxDiscount}% OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _onCategorySelected(category['label']!, _categoryImages.indexOf(category));
                                  },
                                  child: Text(category['label']!),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white, // Customize button color
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Customize padding
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0), // Customize border radius
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  } else if (state is FavoritesAndCartInitial) {
                    return const Center(child: Text('Loading...'));
                  } else {
                    return const Center(child: Text('Error loading content'));
                  }
                },
              ),
              SizedBox(height: 15,),
              SizedBox(
                height: 60,
                child: ListView(
                  clipBehavior: Clip.none,
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryItem(
                      label: 'All Items',
                      image: "assets/shopping-bag.png",
                      onTap: () => _onCategorySelected('all', 0),
                      isSelected: _selectedCategory == 'all',
                    ),
                    CategoryItem(
                      label: 'Beauty',
                      image: "assets/make-up.png",
                      onTap: () => _onCategorySelected('beauty', 1),
                      isSelected: _selectedCategory == 'beauty',
                    ),
                    CategoryItem(
                      label: 'Fragrances',
                      image: "assets/perfume.png",
                      onTap: () => _onCategorySelected('fragrances', 2),
                      isSelected: _selectedCategory == 'fragrances',
                    ),
                    CategoryItem(
                      label: 'Furniture',
                      image: "assets/armchair.png",
                      onTap: () => _onCategorySelected('furniture', 3),
                      isSelected: _selectedCategory == 'furniture',
                    ),
                    CategoryItem(
                      label: 'Groceries',
                      image: "assets/basket.png",
                      onTap: () => _onCategorySelected('groceries', 4),
                      isSelected: _selectedCategory == 'groceries',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Flash sale',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color:themeNotifier.themeMode == ThemeMode.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list, size: 30),
                      onSelected: (String value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(
                            value: 'None',
                            child: Text('No Filter'),
                          ),
                          const PopupMenuItem(
                            value: 'Price Low to High',
                            child: Text('Price Low to High'),
                          ),
                          const PopupMenuItem(
                            value: 'Price High to Low',
                            child: Text('Price High to Low'),
                          ),
                          const PopupMenuItem(
                            value: 'Rating Low to High',
                            child: Text('Rating Low to High'),
                          ),
                          const PopupMenuItem(
                            value: 'Rating High to Low',
                            child: Text('Rating High to Low'),
                          ),
                          const PopupMenuItem(
                            value: 'Name A-Z',
                            child: Text('Name A-Z'),
                          ),
                          const PopupMenuItem(
                            value: 'Name Z-A',
                            child: Text('Name Z-A'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  BlocBuilder<FadyCardCubit, FavoritesAndCartState>(
                    builder: (context, state) {
                      if (state is FavoritesAndCartUpdated) {
                        var filteredProducts = state.shopItems.where((product) {
                          return _selectedCategory == 'all' ||
                              product.category.toLowerCase() == _selectedCategory;
                        }).toList();

                        // Apply the selected filter
                        // In the _selectedFilter logic within the BlocBuilder
                        if (_selectedFilter == 'Price Low to High') {
                          filteredProducts
                              .sort((a, b) => a.price.compareTo(b.price));
                        } else if (_selectedFilter == 'Price High to Low') {
                          filteredProducts
                              .sort((a, b) => b.price.compareTo(a.price));
                        } else if (_selectedFilter == 'Rating Low to High') {
                          filteredProducts
                              .sort((a, b) => a.rating.compareTo(b.rating));
                        } else if (_selectedFilter == 'Rating High to Low') {
                          filteredProducts
                              .sort((a, b) => b.rating.compareTo(a.rating));
                        } else if (_selectedFilter == 'Name A-Z') {
                          filteredProducts
                              .sort((a, b) => a.title.compareTo(b.title));
                        } else if (_selectedFilter == 'Name Z-A') {
                          filteredProducts
                              .sort((a, b) => b.title.compareTo(a.title));
                        }

                        return SizedBox(
                          height: 320.0,
                          child: ListView.builder(
                            controller: _productScrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final cartItem = state.cartItems.firstWhere(
                                (item) => item['item'] == product,
                                orElse: () => {'quantity': 0},
                              );
                              final int quantityInCart =
                                  cartItem['quantity'] as int;
                              final int remainingStock =
                                  product.stock - quantityInCart;
                              final isFavorite =
                                  state.favoriteItemIds.contains(product.id);

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
                                          final cartItems = context
                                              .read<FadyCardCubit>()
                                              .cartItems;
                                          final isInCart = cartItems.any(
                                              (item) => item['item'] == product);

                                          if (isInCart) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
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
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "No more stock available for this item."),
                                              ),
                                            );
                                          }
                                        },
                                        onFavoritePressed: () =>
                                            _toggleFavorite(product),
                                        buttonText: remainingStock > 0
                                            ? 'Add to Cart'
                                            : 'Out of Stock',
                                      ),
                                    ),
                                    Positioned(
                                      top: 265,
                                      right: 18,
                                      child: IconButton(
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width:
                                                      30.0, // Adjust size as needed
                                                  height:
                                                      30.0, // Adjust size as needed
                                                  child: CircularProgressIndicator(
                                                    value: product.rating /
                                                        5, // Rating out of 5
                                                    strokeWidth:
                                                        2.0, // Border width
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
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
                                                    color: themeNotifier.themeMode == ThemeMode.light
                                                        ? Colors.black
                                                        : Colors.white,// Text color for contrast
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
                                                fontWeight: FontWeight.w500,fontSize: 10,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        bottom:100,
                                        left: 0,
                                        child: Image.asset("assets/sales.png",width: 100,)
                                    ),
                                    Positioned(
                                        bottom:product.discountPercentage >= 10 ?160:164,
                                        left: 4,
                                        child: Text(
                                          '${product.discountPercentage >= 10 ? product.discountPercentage.toStringAsFixed(0) : product.discountPercentage.toStringAsFixed(1)}%  ',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: product.discountPercentage >= 10 ? 14.0 : 12.0, // Adjust sizes as needed
                                          ),
                                        )

                                    ),
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
                  ),
                  SizedBox(height:10 ,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Best Discounts Available',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.themeMode == ThemeMode.light
                              ? Colors.black
                              : Colors.white, // Add grey color here
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height:10 ,),

                  BlocBuilder<FadyCardCubit, FavoritesAndCartState>(
                    builder: (context, state) {
                      if (state is FavoritesAndCartUpdated) {
                        var filteredProducts = state.shopItems.where((product) {
                          return _selectedCategory == 'all' ||
                              product.category.toLowerCase() == _selectedCategory;
                        }).toList();

                        // Sort by discounted price from high to low
                        filteredProducts.sort((a, b) {
                          double discountedPriceA = (a.discountPercentage);
                          double discountedPriceB = (b.discountPercentage);
                          return discountedPriceB.compareTo(discountedPriceA); // Descending order
                        });

                        return SizedBox(
                          height: 320.0,
                          child: ListView.builder(
                            controller: _productScrollController,
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
                                            builder: (context) => ProductDetailPage(product: product),
                                          ),
                                        );
                                      },
                                      child: ItemsTitle(
                                        product: product,
                                        onPressed: () {
                                          final cartItems = context.read<FadyCardCubit>().cartItems;
                                          final isInCart = cartItems.any((item) => item['item'] == product);

                                          if (isInCart) {
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
                                            context.read<FadyCardCubit>().addItemToCart(product.id - 1);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("No more stock available for this item."),
                                              ),
                                            );
                                          }
                                        },
                                        onFavoritePressed: () => _toggleFavorite(product),
                                        buttonText: remainingStock > 0 ? 'Add to Cart' : 'Out of Stock',
                                      ),
                                    ),
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
                                                    value: product.rating / 5,
                                                    strokeWidth: 2.0,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[700]!),
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
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: themeNotifier.themeMode == ThemeMode.light
                                                    ? Colors.black
                                                    : Colors.white,
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
                                              ? Colors.green
                                              : remainingStock > 0
                                              ? Colors.orange
                                              : Colors.red,
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Text(
                                          remainingStock > 10
                                              ? 'In Stock: $remainingStock'
                                              : remainingStock > 0
                                              ? 'Low Stock: $remainingStock'
                                              : 'Out of Stock',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        bottom:100,
                                        left: 0,
                                        child: Image.asset("assets/sales.png",width: 100,)
                                    ),
                                    Positioned(
                                        bottom:product.discountPercentage >= 10 ?160:164,
                                        left: 4,
                                        child: Text(
                                          '${product.discountPercentage >= 10 ? product.discountPercentage.toStringAsFixed(0) : product.discountPercentage.toStringAsFixed(1)}%  ',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: product.discountPercentage >= 10 ? 14.0 : 12.0, // Adjust sizes as needed
                                          ),
                                        )

                                    ),
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
                  ),SizedBox(height:10 ,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Big Saving',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.themeMode == ThemeMode.light
                              ? Colors.black
                              : Colors.white, // Add grey color here
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height:10 ,),

                  BlocBuilder<FadyCardCubit, FavoritesAndCartState>(
                    builder: (context, state) {
                      if (state is FavoritesAndCartUpdated) {
                        var filteredProducts = state.shopItems.where((product) {
                          return _selectedCategory == 'all' ||
                              product.category.toLowerCase() == _selectedCategory;
                        }).toList();

                        // Sort by discounted price from high to low
                        filteredProducts.sort((a, b) {
                          double discountedPriceA = (  a.price*(a.discountPercentage/100));
                          double discountedPriceB = (b.price*(b.discountPercentage/100));
                          return discountedPriceB.compareTo(discountedPriceA); // Descending order
                        });

                        return SizedBox(
                          height: 320.0,
                          child: ListView.builder(
                            controller: _productScrollController,
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
                                            builder: (context) => ProductDetailPage(product: product),
                                          ),
                                        );
                                      },
                                      child: ItemsTitle(
                                        product: product,
                                        onPressed: () {
                                          final cartItems = context.read<FadyCardCubit>().cartItems;
                                          final isInCart = cartItems.any((item) => item['item'] == product);

                                          if (isInCart) {
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
                                            context.read<FadyCardCubit>().addItemToCart(product.id - 1);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("No more stock available for this item."),
                                              ),
                                            );
                                          }
                                        },
                                        onFavoritePressed: () => _toggleFavorite(product),
                                        buttonText: remainingStock > 0 ? 'Add to Cart' : 'Out of Stock',
                                      ),
                                    ),
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
                                                    value: product.rating / 5,
                                                    strokeWidth: 2.0,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[700]!),
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
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: themeNotifier.themeMode == ThemeMode.light
                                                    ? Colors.black
                                                    : Colors.white,
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
                                              ? Colors.green
                                              : remainingStock > 0
                                              ? Colors.orange
                                              : Colors.red,
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Text(
                                          remainingStock > 10
                                              ? 'In Stock: $remainingStock'
                                              : remainingStock > 0
                                              ? 'Low Stock: $remainingStock'
                                              : 'Out of Stock',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        bottom:100,
                                        left: 0,
                                        child: Image.asset("assets/sales.png",width: 100,)
                                    ),
                                    Positioned(
                                        bottom:product.discountPercentage >= 10 ?160:164,
                                        left: 4,
                                        child: Text(
                                          '${product.discountPercentage >= 10 ? product.discountPercentage.toStringAsFixed(0) : product.discountPercentage.toStringAsFixed(1)}%  ',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: product.discountPercentage >= 10 ? 14.0 : 12.0, // Adjust sizes as needed
                                          ),
                                        )

                                    ),
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
                  ),

                ],
              ),
              SizedBox(
                height: 50,
              )

            ],
          ),
        ),
      ),
    );
  }

  void _onCategorySelected(String category, int index) {
    setState(() {
      _selectedCategory = category == 'All Items' ? 'all' : category.toLowerCase();
      _scrollToCategory(index);
      _scrollToFirstProduct(); // Scroll to the top of the product list when the category changes
    });
  }


}
