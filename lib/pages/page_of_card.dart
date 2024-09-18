import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../cubits/favorite_and_cart_cubit_management.dart';
import '../cubits/favorites_and_cart_state_manager.dart';
import '../data/product.dart';
import '../main.dart';
import '../pages/product_detail_Page.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  @override
  void initState() {
    super.initState();
    // Load cart data when the page initializes
    context.read<FadyCardCubit>().loadCartProducts();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: themeNotifier.themeMode == ThemeMode.light
                      ? Colors.black
                      : Colors.white,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
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
          ),
        ],
      ),
      body: BlocConsumer<FadyCardCubit, FavoritesAndCartState>(
        listener: (context, state) {
          if (state is FavoritesAndCartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FavoritesAndCartUpdated) {
            final cartItems = context.read<FadyCardCubit>().cartItems;

            if (cartItems.isNotEmpty) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartItems[index];
                        final product = cartItem['item'] as Product;
                        final quantity = cartItem['quantity'];

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: themeNotifier.themeMode == ThemeMode.light
                                  ? [Colors.blue.shade50, Colors.white]
                                  : [
                                      Colors.grey[750] ?? Colors.grey.shade700,
                                      Colors.black54,
                                      Colors.grey[850] ?? Colors.grey.shade900,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailPage(product: product),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: CachedNetworkImage(
                                  imageUrl: product.images.isNotEmpty
                                      ? product.images.first
                                      : '',
                                  width: 50,
                                  height: 100,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                              title: Text(product.title),
                              subtitle: Text(
                                  '\$${(product.price * (1 - (product.discountPercentage / 100))).toStringAsFixed(2)} x $quantity'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 36.0,
                                    height: 36.0,
                                    decoration: BoxDecoration(
                                      color: themeNotifier.themeMode ==
                                              ThemeMode.light
                                          ? Colors.blueGrey[100]
                                          : Colors.blueGrey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon:
                                          const Icon(Icons.remove, size: 20.0),
                                      onPressed: () {
                                        context
                                            .read<FadyCardCubit>()
                                            .decrementItemQuantity(index);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Container(
                                    width: 36.0,
                                    height: 36.0,
                                    decoration: BoxDecoration(
                                      color: themeNotifier.themeMode ==
                                              ThemeMode.light
                                          ? Colors.blueGrey[100]
                                          : Colors.blueGrey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add, size: 20.0),
                                      onPressed: () {
                                        final availableStock = (context
                                                .read<FadyCardCubit>()
                                                .shopItems
                                                .firstWhere((item) =>
                                                    item == cartItem['item']))
                                            .stock;
                                        if (quantity < availableStock) {
                                          context
                                              .read<FadyCardCubit>()
                                              .incrementItemQuantity(index);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Cannot add more than $availableStock items to the cart.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.lightBlue, Colors.blueGrey],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Pay Now button pressed")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total amount\n \$${state.totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Pay Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 100, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      "Your cart is empty!",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Looks like you haven't added anything yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Start shopping and fill your cart with fresh items!",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
