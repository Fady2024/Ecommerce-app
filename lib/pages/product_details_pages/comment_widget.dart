import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../main.dart';

class CommentWidget extends StatefulWidget {
  final String reviewerName;
  final String reviewerEmail;
  final String comment;
  final double rating;
  final DateTime date;

  const CommentWidget({
    Key? key,
    required this.reviewerName,
    required this.reviewerEmail,
    required this.comment,
    required this.rating,
    required this.date,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  final DatabaseReference _repliesRef = FirebaseDatabase.instance.ref('replies');
  final _replyController = TextEditingController();
  final _nameController = TextEditingController();
  final selectedLanguage = AppState().selectedLanguage; // Get the current language
  bool _isReplying = false;
  bool _showReplies = false;
  List<Map<String, dynamic>> _replies = [];
  late StreamSubscription<DatabaseEvent> _repliesSubscription;

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy hh:mm a');
    return formatter.format(date);
  }

  Future<void> _loadReplies() async {
    try {
      final repliesSnapshot = await _repliesRef
          .orderByChild('comment')
          .equalTo(widget.comment)
          .get();

      if (repliesSnapshot.exists) {
        final repliesList = repliesSnapshot.children.map((child) {
          final replyData = child.value as Map<Object?, Object?>;
          return {
            'name': replyData['name'] as String?,
            'reply': replyData['reply'] as String?,
            'timestamp': replyData['timestamp'] as String?,
          };
        }).toList();

        setState(() {
          _replies = repliesList;
        });
      }
    } catch (e) {
      print('Error loading replies: $e');
    }
  }

  Future<void> _submitReply() async {
    final reply = _replyController.text.trim();
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (selectedLanguage == 'Français' ? 'Anonyme' : 'Anonymous');

    if (reply.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(selectedLanguage == 'Français'
              ? 'La réponse ne peut pas être vide'
              : 'Reply cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final newReplyRef = _repliesRef.push();
      await newReplyRef.set({
        'comment': widget.comment,
        'name': name,
        'reply': reply,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(selectedLanguage == 'Français'
              ? 'Réponse soumise avec succès'
              : 'Reply submitted successfully'),
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
          content: Text(selectedLanguage == 'Français'
              ? 'Échec de la soumission de la réponse.'
              : 'Failed to submit reply.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReplies();

    // Create a query to listen to changes in the replies
    final query = _repliesRef.orderByChild('comment').equalTo(widget.comment);
    _repliesSubscription = query.onValue.listen((event) {
      if (event.snapshot.exists) {
        _loadReplies(); // Refresh replies list
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _nameController.dispose();
    _repliesSubscription.cancel();
    super.dispose();
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                  initialRating: widget.rating,
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
                  widget.reviewerEmail,
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
                    widget.reviewerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFE67E22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDate(widget.date),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: themeNotifier.themeMode == ThemeMode.light
                        ? Color(0xFF878080)
                        : Color(0xCAE3DCE4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.comment,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: themeNotifier.themeMode == ThemeMode.light
                    ? Colors.black
                    : Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            if (_isReplying) ...[
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: selectedLanguage == 'Français'
                      ? 'Votre nom (facultatif)'
                      : 'Your Name (optional)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  labelText: selectedLanguage == 'Français'
                      ? 'Écrivez votre réponse'
                      : 'Write your reply',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submitReply,
                child: Text(
                  selectedLanguage == 'Français'
                      ? 'Soumettre la réponse'
                      : 'Submit Reply',
                ),
              ),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    if (_replies.isNotEmpty) ...[
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showReplies = !_showReplies;
                          });
                        },
                        child: Text(
                          _showReplies
                              ? (selectedLanguage == 'Français' ? 'Masquer les réponses' : 'Hide Replies')
                              : (selectedLanguage == 'Français'
                              ? 'Afficher les réponses (${_replies.length})'
                              : 'Show Replies (${_replies.length})'),
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      if (_showReplies) ...[
                        const SizedBox(height: 8),
                        ..._replies.map((reply) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: themeNotifier.themeMode == ThemeMode.light
                                      ? [Colors.blue.shade50, Colors.white]
                                      : [
                                    Colors.black54,
                                    Colors.black54,
                                    Colors.black54,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reply['name'] ?? (selectedLanguage == 'Français' ? 'Anonyme' : 'Anonymous'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(DateTime.parse(reply['timestamp'])),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    reply['reply'] ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: themeNotifier.themeMode == ThemeMode.light
                                        ? Colors.black
                                        : Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
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
                    child: Text(_isReplying ?  (selectedLanguage == 'Français' ? 'Annuler' : 'Cancel')
                        : (selectedLanguage == 'Français' ? 'Répondre' : 'Reply'),
                    ),
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
