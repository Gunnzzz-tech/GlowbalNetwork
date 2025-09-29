class Movie {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;

  Movie({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? "No Title",
      overview: json['overview'],
      posterPath: json['poster_path'],
    );
  }
}
class MovieDetails {
  final int id;
  final String title;
  final String overview;
  final String posterUrl;
  final String releaseYear;
  final String runtime;
  final double rating;
  final String ageRating;
  final List<String> genres;

  MovieDetails({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.releaseYear,
    required this.runtime,
    required this.rating,
    required this.ageRating,
    required this.genres,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? "No Title",
      overview: json['overview'] ?? "No overview available",
      posterUrl: json['poster_path'] != null
          ? "https://image.tmdb.org/t/p/w500${json['poster_path']}"
          : "",
      releaseYear: (json['release_date'] ?? "").isNotEmpty
          ? json['release_date'].substring(0, 4)
          : "N/A",
      runtime: json['runtime'] != null ? "${json['runtime']} min" : "N/A",
      rating: (json['vote_average'] ?? 0).toDouble(),
      ageRating: (json['adult'] ?? false) ? "18+" : "16+",
      genres: (json['genres'] as List<dynamic>?)
          ?.map((g) => g['name'].toString())
          .toList() ??
          [],
    );
  }
}
