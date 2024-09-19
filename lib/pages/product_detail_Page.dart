import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../cubits/favorite_and_cart_cubit_management.dart';
import '../cubits/favorites_and_cart_state_manager.dart';
import '../data/product.dart';
import '../main.dart';
import 'dart:async';
import 'product_details_pages/PriceSection.dart';
import 'product_details_pages/ReviewWidget.dart';
import 'product_details_pages/product_detail_header.dart';
import 'product_details_pages/product_detail_info.dart';
import 'product_details_pages/comment_widget.dart'; // Import CommentWidget

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _commentController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  double _rating = 5.0; // Default rating

  late final DatabaseReference _commentsRef;
  StreamSubscription<DatabaseEvent>? _commentsSubscription;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _commentsRef = FirebaseDatabase.instance.ref('comments');
    _subscribeToComments();
  }

  void _subscribeToComments() {
    _commentsSubscription = _commentsRef
        .orderByChild('productId')
        .equalTo(widget.product.id)
        .onValue
        .listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final commentsList = snapshot.children.map((child) {
          final commentData = child.value as Map<Object?, Object?>;
          return {
            'name': commentData['name'] as String?,
            'email': commentData['email'] as String?,
            'comment': commentData['comment'] as String?,
            'rating': (commentData['rating'] as num?)?.toDouble(),
            'timestamp': commentData['timestamp'] as String?,
          };
        }).toList();

        setState(() {
          _comments = commentsList;
        });
      } else {
        setState(() {
          _comments = []; // No comments found
        });
      }
    });
  }

  @override
  void dispose() {
    _commentsSubscription?.cancel();
    super.dispose();
  }

  void _addToCart(Product product) {
    final cubit = context.read<FadyCardCubit>();

    final cartItem = cubit.cartItems.firstWhere(
          (item) => item['item'] == product,
      orElse: () => {'quantity': 0},
    );
    final int quantityInCart = cartItem['quantity'] as int;
    final int remainingStock = product.stock - quantityInCart;

    if (cubit.cartItems.any((item) => item['item'] == product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remainingStock > 0
                ? 'This product is already in your cart!'
                : 'No more stock available for this product!',
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: remainingStock > 0 ? const Color(0xFFE7E725) : Colors.red,
        ),
      );
    } else if (remainingStock > 0) {
      cubit.addItemToCart(product.id - 1); // Pass the product ID - 1
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added to cart!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more stock available for this product!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleFavorite(Product product) {
    final cubit = context.read<FadyCardCubit>();
    cubit.toggleFavorite(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cubit.favoriteItems.contains(product)
              ? 'Added to favorites!'
              : 'Removed from favorites!',
        ),
        backgroundColor: Colors.pink,
      ),
    );
  }

  Future<void> _submitComment() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If an email is provided, validate it
    if (email.isNotEmpty && !EmailValidator.validate(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final newCommentRef = _commentsRef.push();
      await newCommentRef.set({
        'productId': widget.product.id,
        'name': name.isEmpty ? 'Anonymous' : name, // Default to 'Anonymous' if no name is provided
        'email': email.isEmpty ? 'No email' : email, // Default to 'No email' if no email is provided
        'comment': comment,
        'rating': _rating,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _commentController.clear();
      _nameController.clear();
      _emailController.clear();
      setState(() {
        _rating = 3.0;
        // No need to call _loadComments() as we're already listening to updates
      });
    } catch (e) {
      print('Error submitting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit comment.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double originalPrice = widget.product.price;
    final double discountPercentage = widget.product.discountPercentage;
    final double discountedPrice = originalPrice * (1 - discountPercentage / 100);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Implement share functionality if needed
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
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
          ),
        ],
      ),
      body: BlocBuilder<FadyCardCubit, FavoritesAndCartState>(
        builder: (context, state) {
          final cubit = context.read<FadyCardCubit>();
          final cartItem = cubit.cartItems.firstWhere(
                (item) => item['item'] == widget.product,
            orElse: () => {'quantity': 0},
          );
          final int quantityInCart = cartItem['quantity'] as int;
          final int remainingStock = widget.product.stock - quantityInCart;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductDetailHeader(
                  product: widget.product,
                  isFavorite: context.read<FadyCardCubit>().favoriteItems.contains(widget.product),
                  onFavoriteToggle: _toggleFavorite, // Pass callback
                ),
                const SizedBox(height: 16),
                PriceSection(
                  originalPrice: originalPrice,
                  discountedPrice: discountedPrice,
                  product: widget.product,
                  onAddToCart: _addToCart,
                  remainingStock: remainingStock,
                ),
                const SizedBox(height: 16),
                ProductDetailInfo(product: widget.product, remainingStock: remainingStock),
                const SizedBox(height: 16),
                if (widget.product.reviews.isNotEmpty) ...[
                  const Text('Reviews',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  ...widget.product.reviews
                      .map((review) => ReviewWidget(review: review, productId: widget.product.id,)),
                ],
                if (_comments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._comments.map((comment) {
                    return CommentWidget(
                      reviewerName: comment['name'],
                      reviewerEmail: comment['email'],
                      comment: comment['comment'],
                      rating: (comment['rating'] as num).toDouble(),
                      date: DateTime.parse(comment['timestamp']),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 16),
                const Text('Add a Comment',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Rating:'),
                    const SizedBox(width: 8),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      itemCount: 5,
                      itemSize: 24,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Color(0xFFF39C12),
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitComment,
                  child: const Text('Submit Comment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
