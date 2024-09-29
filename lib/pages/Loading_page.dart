import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'ecommerce_page.dart'; // Import Ecommerce page
import '../data/data_service.dart'; // Import DataService

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late Future<void> _loadProductsFuture;

  @override
  void initState() {
    super.initState();
    // Load products using DataService based on the selected language
    _loadProductsFuture = _loadProducts();

    // Navigate to the main app after products are loaded
    _loadProductsFuture.then((_) {
      AppState().setLoading(false); // Change loading state
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Ecommerce(selectedPos: 2), // Navigate to main app
        ),
      );
    }).catchError((error) {
      // Handle error if necessary
      print('Error loading products: $error');
      // Show an error message to the user based on the selected language
      final selectedLanguage = AppState().selectedLanguage;
      final errorMessage = selectedLanguage == 'Français'
          ? 'Échec du chargement des produits. Veuillez réessayer plus tard.'
          : 'Failed to load products. Please try again later.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    });
  }

  Future<void> _loadProducts() async {
    final language = AppState().selectedLanguage; // Get the selected language
    try {
      await DataService().loadProducts(language); // Load products based on the language
    } catch (e) {
      throw Exception('Failed to load products: $e'); // Throw exception to be caught in initState
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      backgroundColor: themeNotifier.themeMode == ThemeMode.dark
          ? Colors.black
          : Colors.white,
      body: Center(
        child: Lottie.asset(
          'lib/data/Animation - 1727129114642.json', // Path to your Lottie file
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
