class Show {
  final String name;
  final String posterPath;
  final String overview;
  final int rating;

  Show({
    required this.name,
    required this.posterPath,
    required this.overview,
    required this.rating
  });

  factory Show.fromJson(Map<String, dynamic> json) {
    return Show(
      name: json['name'],
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      rating: ((json['vote_average'] ?? 0).toDouble() * 10).toInt(),
    );
  }
}