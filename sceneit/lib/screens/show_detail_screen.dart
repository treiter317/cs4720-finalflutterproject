import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sceneit/widgets/button_widget.dart';
import '../constants/colors.dart';
import '../data/Review.dart';
import '../data/Show.dart';
import '../widgets/review_dialog.dart';
import '../widgets/review_widget.dart';

class ShowDetailsScreen extends StatefulWidget {
  final Show show;

  const ShowDetailsScreen({super.key, required this.show});

  @override
  State<ShowDetailsScreen> createState() => _ShowDetailsScreenState();
}

class ReviewWithAuthor {
  final String username;
  final String userId;
  final String review;
  final double rating;

  ReviewWithAuthor({
    required this.username,
    required this.userId,
    required this.review,
    required this.rating,
  });
}

class _ShowDetailsScreenState extends State<ShowDetailsScreen> {
  List<ReviewWithAuthor> reviews = [];
  bool loadingReviews = true;
  double sceneItAvgRating = 0.0;
  int sceneItReviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final usersSnapshot = await firestore.collection('users').get();

    List<ReviewWithAuthor> allReviews = [];
    double totalRating = 0;
    int reviewCount = 0;

    for (final userDoc in usersSnapshot.docs) {
      final username = userDoc.data()['username'] ?? 'Anonymous';
      final reviewSnapshot = await firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('reviews')
          .doc(widget.show.name)
          .get();

      if (reviewSnapshot.exists) {
        final data = reviewSnapshot.data();
        double reviewRating = (data?['rating'] ?? 0).toDouble();
        allReviews.add(
          ReviewWithAuthor(
            username: username,
            userId: userDoc.id,
            review: data?['review'] ?? '',
            rating: reviewRating,
          ),
        );
        totalRating += reviewRating;
        reviewCount++;
      }
    }

    setState(() {
      reviews = allReviews;
      loadingReviews = false;
      sceneItAvgRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
      sceneItReviewCount = reviewCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/SceneItLogo.png'),
        backgroundColor: AppColors.lightBlue,
        centerTitle: true,
      ),
      backgroundColor: AppColors.lightBlue,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://image.tmdb.org/t/p/w200${widget.show.posterPath}',
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 180,
                        color: Colors.grey,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.show.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amberAccent),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.show.rating.toStringAsFixed(1)} (TMDB)',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.movie, color: Colors.blueAccent),
                                const SizedBox(width: 4),
                                Text(
                                  sceneItReviewCount > 0
                                      ? '${sceneItAvgRating.toStringAsFixed(1)} (SceneIt, $sceneItReviewCount reviews)'
                                      : 'No SceneIt Ratings',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Text(
                          widget.show.overview ?? 'No description available.',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ButtonWidget(
                text: 'Add to Watchlist',
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You must be logged in to add to watchlist'),
                      ),
                    );
                    return;
                  }

                  try {
                    final watchlistRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('watchlist')
                        .doc(widget.show.name);

                    await watchlistRef.set({
                      'title': widget.show.name,
                      'posterPath': widget.show.posterPath,
                      'rating': widget.show.rating,
                      'addedAt': DateTime.now(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.show.name} added to Watchlist'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add to Watchlist: $e')),
                    );
                  }
                },
                color: AppColors.darkBlue,
                fullWidth: true,
              ),
              const SizedBox(height: 12),
              ButtonWidget(
                text: 'Leave A Review',
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You must be logged in to leave a review'),
                      ),
                    );
                    return;
                  }

                  await showReviewModal(
                    context: context,
                    showName: widget.show.name,
                    showPosterPath: widget.show.posterPath ?? '',
                    onSubmit: () async {
                      await _loadReviews();
                    },
                  );
                },
                color: AppColors.blueLink,
                fullWidth: true,
              ),
              const SizedBox(height: 32),
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              loadingReviews
                  ? const Center(child: CircularProgressIndicator())
                  : reviews.isEmpty
                  ? const Text("No reviews yet.")
                  : const SizedBox(height: 10),
              ...reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: ReviewCard(
                  review: Review(
                    title: widget.show.name,
                    posterPath: widget.show.posterPath ?? '',
                    reviewText: r.review,
                    rating: r.rating,
                    username: r.username,
                  ),
                  isMine: FirebaseAuth.instance.currentUser?.uid == r.userId,
                  onUpdate: _loadReviews,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
