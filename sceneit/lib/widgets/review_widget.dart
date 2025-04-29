import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/Review.dart';
import '../screens/active_chat_screen.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isMine;
  final VoidCallback onUpdate;

  const ReviewCard({
    Key? key,
    required this.review,
    required this.onUpdate,
    this.isMine = false,
  }) : super(key: key);

  // we decided to let users start chats from reviews after this widget was made...
  // would be good to reorganize this with more time
  Future<void> _startOrOpenChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final firestore = FirebaseFirestore.instance;
    final existingChats =
        await firestore
            .collection('chats')
            .where('users', arrayContains: currentUser.uid)
            .get();

    String chatId = '';
    for (final doc in existingChats.docs) {
      final usersInChat = List<String>.from(doc['users']);
      if (usersInChat.contains(review.userId)) {
        chatId = doc.id;
        break;
      }
    }
    if (chatId == '') {
      final newChatDoc = await firestore.collection('chats').add({
        'users': [currentUser.uid, review.userId],
        'lastMessage': 'No Messages Yet',
        'lastMessageTimestamp': DateTime.timestamp()
      });
      chatId = newChatDoc.id;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ActiveChatScreen(
              chatId: chatId,
              otherUserId: review.userId!,
              otherUserPhoto:
                  review.userProfilePhoto ??
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRmK71ObBifzt00f_UVxSxZrB8tB9YxnKjB7Q&s',
              otherUsername: review.username!,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    review.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
                if (isMine)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(context);
                      } else if (value == 'delete') {
                        _deleteReview(context);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                  ),
                if (!isMine)
                  IconButton(
                    onPressed: () => _startOrOpenChat(context),
                    icon: Icon(Icons.message),
                  ),
              ],
            ),
            if (review.username != null) ...[
              Text(
                'From ${review.username!}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 6),
            Text(review.reviewText, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            Text(
              'Rating: ${review.rating.toInt()} / 100',
              style: TextStyle(fontSize: 13, color: Colors.amber[800]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReview(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Review'),
            content: const Text('Are you sure you want to delete this review?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reviews')
            .doc(review.title)
            .delete();
        onUpdate();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review deleted')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController reviewController = TextEditingController(
      text: review.reviewText,
    );
    double newRating = review.rating.toDouble();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                title: const Text('Edit Review'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Edit your review...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Rating: ${newRating.toInt()} / 100"),
                    Slider(
                      value: newRating,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: newRating.toInt().toString(),
                      onChanged: (newVal) {
                        setModalState(() {
                          newRating = newVal;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('reviews')
                            .doc(review.title)
                            .update({
                              'review': reviewController.text,
                              'rating': newRating,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                        onUpdate();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review updated!')),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e')),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
