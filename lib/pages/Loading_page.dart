import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'ecommerce_page.dart'; // Import Ecommerce page
import '../data/data_service.dart'; // Import DataService
import '../data/product.dart'; // Import Product model

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late Future<List<Product>> _loadProductsFuture;

  @override
  void initState() {
    super.initState();
    // Load products using DataService
    _loadProductsFuture = DataService().loadProducts();

    // Navigate to the main app after products are loaded
    _loadProductsFuture.then((products) {
      AppState().setLoading(false); // Change loading state
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Ecommerce(selectedPos: 2), // Navigate to main app
        ),
      );
    }).catchError((error) {
      // Handle error if necessary
      print('Error loading products: $error');
    });
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
