import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'blocs/movie_bloc.dart';
import 'blocs/movie_event.dart';
import 'blocs/movie_state.dart';
import 'repository/movie_repository.dart';
import '../models/movie_model.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final MovieRepository repository = MovieRepository();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieBloc(repository)..add(LoadPopularMovies()),
      child: MaterialApp(
        title: "Movie App",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          useMaterial3: true,
        ),
        initialRoute: "/splash",
        routes: {
          "/splash": (context) => const SplashScreen(),
          "/home": (context) => const MainScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller for both fade + scale
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Fade from 0 → 1
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Scale from 0.8 → 1.2 (slight zoom-in)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation
    _controller.forward();

    // Navigate to home after 5s
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, "/home");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              "N", // Replace with Image.asset("assets/logo.png") if you add a logo
              style: const TextStyle(
                color: Colors.red,
                fontSize: 120,
                fontWeight: FontWeight.bold,
                fontFamily: "ArialBlack", // close to Netflix look
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CupertinoSearchTextField(
                padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
                backgroundColor: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
                placeholder: "Search Movies",
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: Colors.grey[600],
                  size: 20,
                ),
                controller: _controller,
                cursorColor: Colors.grey[400],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                onSubmitted: (query) {
                  if (query.trim().isEmpty) {
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
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    } else if (state is MovieLoaded) {
                      final movies = state.movies;
                      return GridView.builder(
                        shrinkWrap: true, // let grid shrink inside column
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.65, // keep ratio for portrait posters
                        ),
                        itemCount: movies.length,
                        itemBuilder: (context, index) {
                          final movie = movies[index];
                          final posterUrl = movie.posterPath != null
                              ? "https://image.tmdb.org/t/p/w500${movie.posterPath}"
                              : "assets/image.jpg";

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MovieDetailScreen(movieId: movie.id),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      );
                    } else if (state is MovieError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class MovieDetailScreen extends StatelessWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isLargeScreen = MediaQuery.of(context).size.width > 768;

    return BlocProvider(
      create: (context) =>
      MovieBloc(MovieRepository())..add(GetMovieDetails(movieId)),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: isIOS // 👈 show AppBar only on iOS
            ? AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        )
            : null,
        body: BlocBuilder<MovieBloc, MovieState>(
          builder: (context, state) {
            if (state is MovieLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (state is MovieDetailsLoaded) {
              final details = state.movieDetails;

              // 📱 Normal layout (mobile, smaller screens)
              if (!isLargeScreen) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: screenWidth * 0.9,
                        child: Stack(
                          children: [
                            Image.network(
                              details.posterUrl,
                              width: double.infinity,
                              height: screenWidth * 1.0,
                              fit: BoxFit.cover,
                            ),
                            // Gradient overlay
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent, // top
                                      Colors.black87,     // bottom
                                    ],
                                    stops: [0.6, 1.0], // adjust gradient height
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDetails(context, details, screenWidth),
                    ],
                  ),
                );
              }

              // 💻 iPad / Large screen layout
              return Column(
                children: [
                  SizedBox(
                    height: screenHeight * 0.6, // top half = image
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Image.network(
                          details.posterUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent, // start transparent
                                Colors.black87,     // fade into black
                              ],
                              stops: [0.6, 1.0], // adjust transition
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildDetails(context, details, screenWidth),
                    ),
                  ),
                ],
              );
            } else if (state is MovieError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, dynamic details, double screenWidth) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isLargeScreen = MediaQuery.of(context).size.width > 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            details.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tags
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTag(details.ageRating),
            _buildTag("${details.runtime} min"),
            _buildTag("HD"),
            _buildTag(details.rating.toStringAsFixed(1)),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          "${details.releaseYear} • ${details.genres.join(" • ")}",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),

        const SizedBox(height: 20),

        // Play Button
        SizedBox(
          width: isLargeScreen ? screenWidth * 0.5 : screenWidth * 0.65,
          height: isLargeScreen ?45 : 35,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () {},
            icon: Icon(
              Icons.play_arrow,
              color: Colors.black,
              size: isLargeScreen ? 34 : 28,
            ),
            label: Text(
              "Play",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: isLargeScreen ? 22 : 18,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Bottom icons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAction(Icons.add, "Watchlist"),
              SizedBox(width: 60),
              _buildAction(Icons.play_circle, "Trailer"),
              SizedBox(width: 60),
              _buildAction(Icons.download, "Download"),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Overview
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            details.overview,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}