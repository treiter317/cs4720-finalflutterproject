import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> showReviewModal({
  required BuildContext context,
  required String showName,
  required String showPosterPath,
  required VoidCallback onSubmit,
}) async {
  final TextEditingController commentController = TextEditingController();
  double rating = 0;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text("Leave a review and rating"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Write your review...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text("Rating: ${rating.toInt()} / 100"),
                Slider(
                  value: rating,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: rating.toInt().toString(),
                  onChanged: (newRating) {
                    setModalState(() {
                      rating = newRating;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(user.uid)
                          .collection("reviews")
                          .doc(showName)
                          .set({
                        "title": showName,
                        "posterPath": showPosterPath,
                        "review": commentController.text,
                        "rating": rating,
                        "timestamp": FieldValue.serverTimestamp(),
                      });
                      onSubmit();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Review submitted!")),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to submit review: $e")),
                      );
                    }
                  }
                },
                child: const Text("Submit Review"),
              ),
            ],
          );
        },
      );
    },
  );
}
