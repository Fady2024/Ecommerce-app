import 'package:circular_bottom_navigation/circular_bottom_navigation.dart';
import 'package:circular_bottom_navigation/tab_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../cubits/favorite_and_cart_cubit_management.dart';
import '../cubits/favorites_and_cart_state_manager.dart';
import 'account_page.dart';
import 'favorite_page.dart';
import 'horizontal_preview_page.dart';
import 'page_of_card.dart';
import '../main.dart'; // Import ThemeNotifier

class Ecommerce extends StatefulWidget {
  final int selectedPos; // Add this parameter

  const Ecommerce({super.key, this.selectedPos = 0}); // Default to 0

  @override
  EcommerceState createState() => EcommerceState();
}

class EcommerceState extends State<Ecommerce> {
  late int _selectedPos;
  final double _bottomNavBarHeight = 60;
  final selectedLanguage = AppState().selectedLanguage; // Get the current language
  late final CircularBottomNavigationController _navigationController;

  @override
  void initState() {
    super.initState();
    _selectedPos = widget.selectedPos; // Use the passed parameter
    _navigationController = CircularBottomNavigationController(_selectedPos);
    _openAndCloseCardPage();
  }

  @override
  void dispose() {
    _navigationController.dispose();
    super.dispose();
  }

  Future<void> _openAndCloseCardPage() async {
    await Future.delayed(const Duration(seconds: 10)); // 10-second delay before opening CardPage

    if (!mounted) return; // Check if the widget is still mounted

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CardPage()),
    );

    // Close CardPage after a short delay
    await Future.delayed(const Duration(milliseconds: 10)); // Duration for how long CardPage will be visible

    if (!mounted) return; // Check if the widget is still mounted before popping
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    String homeLabel = selectedLanguage == 'Français' ? 'Accueil' : 'Home';
    String favoriteLabel = selectedLanguage == 'Français' ? 'Favoris' : 'Favorite';
    String accountLabel = selectedLanguage == 'Français' ? 'Compte' : 'Account';

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              bottom: _selectedPos == 2 ? 80 : 50, // Adjust padding based on the selected tab
            ),
            child: IndexedStack(
              index: _selectedPos,
              children: const [
                HorizontalPreviewPage(),
                FavoritePage(),
                AccountPage(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNav(themeNotifier.themeMode, homeLabel, favoriteLabel, accountLabel),
          ),
        ],
      ),
      floatingActionButton: AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.only(
          bottom: _selectedPos == 2 ? 80 : 50, // Adjust padding based on the selected tab
        ),
        child: BlocBuilder<FadyCardCubit, FavoritesAndCartState>(
          builder: (context, state) {
            int cartItemCount = 0;
            if (state is FavoritesAndCartUpdated) {
              cartItemCount = state.cartItems.length;
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton(
                    key: ValueKey<int>(_selectedPos), // Unique key for animation
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CardPage()),
                      );
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white,
                    ),
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      bottom: 35,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNav(ThemeMode themeMode, String homeLabel, String favoriteLabel, String accountLabel) {
    Color barBackgroundColor = themeMode == ThemeMode.light ? Colors.white : Colors.black;

    return CircularBottomNavigation(
      _tabItems(homeLabel, favoriteLabel, accountLabel),
      controller: _navigationController,
      selectedPos: _selectedPos,
      barHeight: _bottomNavBarHeight,
      barBackgroundColor: barBackgroundColor,
      backgroundBoxShadow: <BoxShadow>[
        BoxShadow(color: themeMode == ThemeMode.light ? Colors.black : Colors.grey, blurRadius: themeMode == ThemeMode.light ? 10.0 : 3.0),
      ],
      animationDuration: const Duration(milliseconds: 300),
      selectedCallback: (int? selectedPos) {
        setState(() {
          _selectedPos = selectedPos ?? 0;
        });
      },
    );
  }

  List<TabItem> _tabItems(String homeLabel, String favoriteLabel, String accountLabel) {
    return [
      TabItem(
        Icons.shopping_bag,
        homeLabel,
        Colors.blue,
      ),
      TabItem(
        Icons.favorite,
        favoriteLabel,
        Colors.red,
      ),
      TabItem(
        Icons.account_circle,
        accountLabel,
        Colors.green,
      ),
    ];
  }
}
