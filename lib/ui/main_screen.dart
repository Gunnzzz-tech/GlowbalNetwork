import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/movie_bloc.dart';
import '../blocs/movie_event.dart';
import '../blocs/movie_state.dart';
import '../repository/movie_repository.dart';

class MainScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MovieBloc(MovieRepository())..add(LoadPopularMovies()),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CupertinoSearchTextField(
                  controller: _controller,
                  padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
                  backgroundColor: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                  placeholder: "Search Movies",
                  prefixIcon: Icon(CupertinoIcons.search, color: Colors.grey[600], size: 20),
                  cursorColor: Colors.grey[400],
                  onSubmitted: (query) {
                    if (query.isEmpty) {
                      context.read<MovieBloc>().add(LoadPopularMovies());
                    } else {
                      context.read<MovieBloc>().add(SearchMovies(query));
                    }
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BlocBuilder<MovieBloc, MovieState>(
                    builder: (context, state) {
                      if (state is MovieLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is MovieLoaded) {
                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: state.movies.length,
                          itemBuilder: (context, index) {
                            final movie = state.movies[index];
                            final posterUrl = movie.posterPath != null
                                ? "https://image.tmdb.org/t/p/w500${movie.posterPath}"
                                : "https://via.placeholder.com/150";

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(posterUrl, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  movie.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            );
                          },
                        );
                      } else if (state is MovieError) {
                        return Center(
                          child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)),
                        );
                      }
                      return const Center(
                        child: Text("Search or browse movies...", style: TextStyle(color: Colors.white70)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
