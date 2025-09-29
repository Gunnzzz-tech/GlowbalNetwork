abstract class MoviesEvent{}

class LoadPopularMovies extends MoviesEvent{}

class SearchMovies extends MoviesEvent{
  final String query;
  SearchMovies(this.query);
}
class GetMovieDetails extends MoviesEvent {
  final int movieId;
  GetMovieDetails(this.movieId);
}
