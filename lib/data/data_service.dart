import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:loginpage/data/product.dart';

class DataService {
  Future<List<Product>> loadProducts(String language) async {
    if (language == 'Français') {
      print('Loading products from local JSON (French)');
      return await loadProductsFromLocal();
    } else {
      print('Loading products from API (English)');
      return await loadProductsFromApi();
    }
  }

  Future<List<Product>> loadProductsFromApi() async {
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/products'));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final products = jsonResponse['products'] as List;
        return products.map((data) => Product.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }

  Future<List<Product>> loadProductsFromLocal() async {
    try {
      final jsonString = await rootBundle.loadString('lib/data/Translated_French_Products.json');
      final jsonResponse = json.decode(jsonString);
      final products = jsonResponse['products'] as List;
      return products.map((data) => Product.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to load local products: ${e.toString()}');
    }
  }
}
