import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:loginpage/pages/day_night_switch.dart';
import 'package:loginpage/pages/sorting_page.dart';
import 'package:provider/provider.dart';
import '../cubits/favorite_and_cart_cubit_management.dart';
import '../cubits/favorites_and_cart_state_manager.dart';
import '../data/product.dart';
import '../main.dart';
import '../widgets/category_Shape.dart';
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
  bool _isDarkMode = false; // Initialize based on your app's logic or provider
  final ScrollController _categoryScrollController = ScrollController(); // ScrollController to control the categories ListView
  final ScrollController _productScrollController = ScrollController(); // ScrollController to control the products ListView
  final selectedLanguage = AppState().selectedLanguage; // Get the current language

  void _toggleTheme(bool value) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    setState(() {
      print(selectedLanguage);
      _isDarkMode = value;
      themeNotifier
          .toggleTheme(); // Assuming this method switches the theme in your provider
    });
  }
  void _scrollToCategory(int index) {
    final selectedLanguage =
        AppState().selectedLanguage; // Get the current language
    final double offset = selectedLanguage == 'Français'
        ? index * 225.0
        : index * 195.0; // 170 to en and to fr
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
                              selectedLanguage == 'Français' ? 'Découvrez' : 'Discover',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              selectedLanguage == 'Français' ? 'Trouvez tout ce que vous voulez !' : 'Find anything what you want!',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                fontSize:selectedLanguage == 'Français' ? 14: 16,
                                fontWeight: FontWeight.w400,
                                color:
                                Colors.grey[600], // Add grey color here
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    color: themeNotifier.themeMode ==
                                        ThemeMode.light
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(15)),
                              child: IconButton(
                                icon: const Icon(Icons.search, size: 30),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchPage(
                                        allProducts:
                                        (context.read<FadyCardCubit>().state
                                        as FavoritesAndCartUpdated)
                                            .shopItems,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: DayNightSwitch(
                                value: _isDarkMode,
                                onChanged: _toggleTheme,
                                moonImage: AssetImage('assets/moon.png'),
                                sunImage: AssetImage('assets/sun.png'),
                                sunColor: Colors.yellow,
                                moonColor: Colors.white,
                                dayColor: Colors.blue,
                                nightColor: Color(0xFF393939),
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
                          height:
                          200.0, // This height should match the SizedBox height if needed
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
                              : state.shopItems
                              .where((product) =>
                          product.category.toLowerCase() ==
                              category['label']!.toLowerCase())
                              .toList();

                          final maxDiscount = isAllItems
                              ? 0
                              : categoryProducts.isNotEmpty
                              ? categoryProducts
                              .map((product) =>
                          product.discountPercentage)
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
                                      selectedLanguage == 'Français' ? '${maxDiscount}% REMISE' : '${maxDiscount}% OFF',
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
                                    _onCategorySelected(category['label']!,
                                        _categoryImages.indexOf(category));
                                  },
                                  child: Text(category['label']!),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Colors.white, // Customize button color
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0), // Customize padding
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          8.0), // Customize border radius
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
                    return Center(child: Text(      selectedLanguage == 'Français' ? 'Chargement...' : 'Loading...',
                    ));
                  } else {
                    return Center(child: Text(      selectedLanguage == 'Français' ? 'Erreur lors du chargement du contenu' : 'Error loading content',
                    ));
                  }
                },
              ),
              SizedBox(
                height: 15,
              ),
              SizedBox(
                height: 60,
                child: ListView(
                  clipBehavior: Clip.none,
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryItem(
                      label: selectedLanguage == 'Français'
                          ? 'Tous les articles'
                          : 'All Items',
                      image: "assets/shopping-bag.png",
                      onTap: () => _onCategorySelected('all', 0),
                      isSelected: _selectedCategory ==
                          (selectedLanguage == 'Français' ? 'all' : 'all'),
                      selectedLanguage:
                      selectedLanguage, // Pass the selected language here
                    ),
                    CategoryItem(
                      label:
                      selectedLanguage == 'Français' ? 'Beauté' : 'Beauty',
                      image: "assets/make-up.png",
                      onTap: () => _onCategorySelected(
                          selectedLanguage == 'Français' ? 'beauty' : 'beauty',
                          1),
                      isSelected: _selectedCategory ==
                          (selectedLanguage == 'Français'
                              ? 'beauty'
                              : 'beauty'),
                      selectedLanguage:
                      selectedLanguage, // Pass the selected language here
                    ),
                    CategoryItem(
                      label: selectedLanguage == 'Français'
                          ? 'Parfums'
                          : 'Fragrances',
                      image: "assets/perfume.png",
                      onTap: () => _onCategorySelected(
                          selectedLanguage == 'Français'
                              ? 'fragrances'
                              : 'fragrances',
                          2),
                      isSelected: _selectedCategory ==
                          (selectedLanguage == 'Français'
                              ? 'fragrances'
                              : 'fragrances'),
                      selectedLanguage:
                      selectedLanguage, // Pass the selected language here
                    ),
                    CategoryItem(
                      label: selectedLanguage == 'Français'
                          ? 'Meubles'
                          : 'Furniture',
                      image: "assets/armchair.png",
                      onTap: () => _onCategorySelected(
                          selectedLanguage == 'Français'
                              ? 'furniture'
                              : 'furniture',
                          3),
                      isSelected: _selectedCategory ==
                          (selectedLanguage == 'Français'
                              ? 'furniture'
                              : 'furniture'),
                      selectedLanguage:
                      selectedLanguage, // Pass the selected language here
                    ),
                    CategoryItem(
                      label: selectedLanguage == 'Français'
                          ? 'Épicerie'
                          : 'Groceries',
                      image: "assets/basket.png",
                      onTap: () => _onCategorySelected(
                          selectedLanguage == 'Français'
                              ? 'groceries'
                              : 'groceries',
                          4),
                      isSelected: _selectedCategory ==
                          (selectedLanguage == 'Français'
                              ? 'groceries'
                              : 'groceries'),
                      selectedLanguage:
                      selectedLanguage, // Pass the selected language here
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedLanguage == 'Français' ?'Vente flash':'Flash sale',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: themeNotifier.themeMode == ThemeMode.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                    PopupMenuButton<String>(icon: const Icon(Icons.filter_list, size: 30),
                      onSelected: (String value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                            value: 'None',
                            child: Text(selectedLanguage == 'Français' ? 'Aucun filtre' : 'No Filter'),
                          ),
                          PopupMenuItem(
                            value: 'Price Low to High',
                            child: Text(selectedLanguage == 'Français' ? 'Prix croissant' : 'Price Low to High'),
                          ),
                          PopupMenuItem(
                            value: 'Price High to Low',
                            child: Text(selectedLanguage == 'Français' ? 'Prix décroissant' : 'Price High to Low'),
                          ),
                          PopupMenuItem(
                            value: 'Rating Low to High',
                            child: Text(selectedLanguage == 'Français' ? 'Note croissante' : 'Rating Low to High'),
                          ),
                          PopupMenuItem(
                            value: 'Rating High to Low',
                            child: Text(selectedLanguage == 'Français' ? 'Note décroissante' : 'Rating High to Low'),
                          ),
                          PopupMenuItem(
                            value: 'Name A-Z',
                            child: Text(selectedLanguage == 'Français' ? 'Nom A-Z' : 'Name A-Z'),
                          ),
                          PopupMenuItem(
                            value: 'Name Z-A',
                            child: Text(selectedLanguage == 'Français' ? 'Nom Z-A' : 'Name Z-A'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  SortingPage(
                    selectedCategory: _selectedCategory,
                    selectedFilter: _selectedFilter,
                    productScrollController: _productScrollController,
                    themeNotifier: themeNotifier, name: 'FS',
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        selectedLanguage == 'Français' ? 'Meilleures réductions disponibles' : 'Best Discounts Available',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.themeMode == ThemeMode.light
                              ? Colors.black
                              : Colors.white, // Add grey color here
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SortingPage(
                    selectedCategory: _selectedCategory,
                    selectedFilter: _selectedFilter,
                    productScrollController: _productScrollController,
                    themeNotifier: themeNotifier, name: 'BDA',
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        selectedLanguage == 'Français' ? 'Économies importantes' : 'Big Saving',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.themeMode == ThemeMode.light
                              ? Colors.black
                              : Colors.white, // Add grey color here
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SortingPage(
                    selectedCategory: _selectedCategory,
                    selectedFilter: _selectedFilter,
                    productScrollController: _productScrollController,
                    themeNotifier: themeNotifier, name: 'BS',
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
      _selectedCategory =
      category == 'All Items' ? 'all' : category.toLowerCase();
      _scrollToCategory(index);
      _scrollToFirstProduct(); // Scroll to the top of the product list when the category changes
    });
  }
}
