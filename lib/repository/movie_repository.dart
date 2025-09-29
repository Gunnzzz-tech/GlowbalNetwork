import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';

class MovieRepository{
  final String apiKey="0feb1c6a0c48a8f281df074545dc0891";

  Future<List<Movie>> fetchPopularMovies() async{
    final url="https://api.themoviedb.org/3/movie/popular?api_key=$apiKey&page=1";
    final response=await http.get(Uri.parse(url));
    if(response.statusCode==200){
      final data=jsonDecode(response.body);
      final List results=data["results"];
      return results.map((json)=>Movie.fromJson(json)).toList();
    }
    else{
      throw Exception("Failed to load popular movies");
    }
  }
  Future<List<Movie>> searchMovies(String query) async{
    final url="https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query&page=1";
    final response=await http.get(Uri.parse(url));
    if(response.statusCode==200){
      final data=jsonDecode(response.body);
      final List results=data["results"];
      return results.map((json)=>Movie.fromJson(json)).toList();
    }
    else{
      throw Exception("Failed to search movies");
    }
  }
  Future<MovieDetails> getMovieDetails(int id) async {
    final response = await http.get(
      Uri.parse("https://api.themoviedb.org/3/movie/$id?api_key=$apiKey&language=en-US"),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return MovieDetails.fromJson(json);
    } else {
      throw Exception("Failed to load movie details");
    }
  }



}
