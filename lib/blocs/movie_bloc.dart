import 'package:flutter_bloc/flutter_bloc.dart';
import 'movie_event.dart';
import 'movie_state.dart';
import '../repository/movie_repository.dart';

class MovieBloc extends Bloc<MoviesEvent, MovieState> {
  final MovieRepository repository;

  MovieBloc(this.repository) : super(MovieInitial()) {
    on<LoadPopularMovies>((event, emit) async {
      emit(MovieLoading());
      try {
        final movies = await repository.fetchPopularMovies();
        emit(MovieLoaded(movies));
      } catch (e) {
        emit(MovieError(e.toString()));
      }
    });

    on<SearchMovies>((event, emit) async {
      emit(MovieLoading());
      try {
        final movies = await repository.searchMovies(event.query);
        emit(MovieLoaded(movies));
      } catch (e) {
        emit(MovieError(e.toString()));
      }
    });
    on<GetMovieDetails>((event, emit) async {
      emit(MovieLoading());
      try {
        final movieDetails = await repository.getMovieDetails(event.movieId);
        emit(MovieDetailsLoaded(movieDetails));
      } catch (e) {
        emit(MovieError("Failed to load movie details"));
      }
    });

  }
}
