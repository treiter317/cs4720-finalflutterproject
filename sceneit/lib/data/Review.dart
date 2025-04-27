class Review {
  final String title;
  final String posterPath;
  final String reviewText;
  final double rating;
  final String? username;

  Review({
    required this.title,
    required this.posterPath,
    required this.reviewText,
    required this.rating,
    this.username,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      title: map['title'] ?? '',
      posterPath: map['posterPath'] ?? '',
      reviewText: map['review'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      username: map['username'],
    );
  }
}
