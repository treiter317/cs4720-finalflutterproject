class Review {
  final String title;
  final String posterPath;
  final String reviewText;
  final double rating;

  Review({
    required this.title,
    required this.posterPath,
    required this.reviewText,
    required this.rating,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      title: map['title'] ?? '',
      posterPath: map['posterPath'] ?? '',
      reviewText: map['review'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
    );
  }
}
