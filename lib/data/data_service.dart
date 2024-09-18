import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/product.dart';

class DataService {
  Future<List<Product>> loadProducts() async {
    try {
      final response = await http.get(Uri.parse('https://dummyjson.com/products'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (kDebugMode) {
          print('Response JSON: $jsonResponse');
        } // Log the response
        final products = jsonResponse['products'] as List;
        return products.map((data) => Product.fromJson(data)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to load products: ${response.statusCode}');
        } // Log error
        throw Exception('Failed to load products');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: ${e.toString()}');
      } // Log the exception
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }
}
