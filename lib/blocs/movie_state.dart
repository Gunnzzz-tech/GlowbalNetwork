import '../models/movie_model.dart';
abstract class MovieState {}

class MovieInitial extends MovieState {}

class MovieLoading extends MovieState {}

class MovieLoaded extends MovieState {
  final List<Movie> movies;
  MovieLoaded(this.movies);
}

class MovieDetailsLoaded extends MovieState {
  final MovieDetails movieDetails;
  MovieDetailsLoaded(this.movieDetails);
}

class MovieError extends MovieState {
  final String message;
  MovieError(this.message);
}
