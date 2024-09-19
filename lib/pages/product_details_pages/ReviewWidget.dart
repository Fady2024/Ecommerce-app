import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../../data/product.dart';
import '../../main.dart';

class ReviewWidget extends StatefulWidget {
  final Review review;
  final int productId; // Add productId to link replies to the specific product

  const ReviewWidget({
    Key? key,
    required this.review,
    required this.productId,
  }) : super(key: key);

  @override
  _ReviewWidgetState createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  final DatabaseReference _repliesRef =
      FirebaseDatabase.instance.ref('replies');
  final _replyController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isReplying = false;
  bool _showReplies = false;

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd h:mm a');
    return formatter.format(date);
  }

  Future<void> _submitReply() async {
    final reply = _replyController.text.trim();
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Anonymous';

    if (reply.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final newReplyRef = _repliesRef.push();
      await newReplyRef.set({
        'productId': widget.productId,
        'comment': widget.review.comment,
        'name': name,
        'reply': reply,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _replyController.clear();
      _nameController.clear();
      setState(() {
        _isReplying = false;
      });
    } catch (e) {
      print('Error submitting reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit reply.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: themeNotifier.themeMode == ThemeMode.light
                ? [Colors.blue.shade50, Colors.white]
                : [
                    Colors.grey[750] ?? Colors.grey.shade700,
                    Colors.black54,
                    Colors.grey[850] ?? Colors.grey.shade900,
                  ],
          ),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RatingBar.builder(
                  initialRating: widget.review.rating.toDouble(),
                  minRating: 1,
                  itemCount: 5,
                  itemSize: 20,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Color(0xFFF39C12),
                  ),
                  onRatingUpdate: (rating) {},
                  ignoreGestures: true,
                ),
                Text(
                  widget.review.reviewerEmail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFE67E22),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.review.reviewerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFE67E22),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _formatDate(DateTime.parse(widget.review.date)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeNotifier.themeMode == ThemeMode.light
                            ? Color(0xFF878080)
                            : Color(0xCAE3DCE4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.review.comment,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: themeNotifier.themeMode == ThemeMode.light
                          ? Colors.black
                          : Colors.white,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isReplying) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _replyController,
                decoration: const InputDecoration(
                  labelText: 'Write your reply',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submitReply,
                child: const Text('Submit Reply'),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    StreamBuilder(
                      stream: _repliesRef
                          .orderByChild('comment')
                          .equalTo(widget.review.comment)
                          .onValue,
                      builder:
                          (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        final data = snapshot.data?.snapshot.value
                            as Map<Object?, Object?>?;
                        final repliesList = data != null
                            ? data.values.map((reply) {
                                final replyData =
                                    reply as Map<Object?, Object?>;
                                return {
                                  'name': replyData['name'] as String?,
                                  'reply': replyData['reply'] as String?,
                                  'timestamp':
                                      replyData['timestamp'] as String?,
                                };
                              }).toList()
                            : [];

                        return Column(
                          children: [
                            if (repliesList.isNotEmpty) ...[
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showReplies = !_showReplies;
                                  });
                                },
                                child: Text(
                                  _showReplies
                                      ? 'Hide Replies'
                                      : 'Show Replies (${repliesList.length})',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                              if (_showReplies) ...[
                                const SizedBox(height: 8),
                                ...repliesList.map((reply) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: themeNotifier.themeMode ==
                                                  ThemeMode.light
                                              ? [
                                                  Colors.blue.shade50,
                                                  Colors.white
                                                ]
                                              : [
                                                  Colors.black54,
                                                  Colors.black54,
                                                  Colors.black54,
                                                ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reply['name'] ?? 'Anonymous',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.blueAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            _formatDate(DateTime.parse(
                                                reply['timestamp'])),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                    color: Colors.grey[600]),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            reply['reply'] ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color:
                                                      themeNotifier.themeMode ==
                                                              ThemeMode.light
                                                          ? Colors.black
                                                          : Colors.white,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isReplying = !_isReplying;
                      });
                    },
                    child: Text(_isReplying ? 'Cancel' : 'Reply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
