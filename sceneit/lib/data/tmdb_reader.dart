// api key = dce07dc0f2c4f07fea8841fee75a35a1
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Show.dart';

class TMDBReader {
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // just keeping this here since its in a private repo. Would normally create .env or secrets manager.
  static const String _token = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJkY2UwN2RjMGYyYzRmMDdmZWE4ODQxZmVlNzVhMzVhMSIsIm5iZiI6MTc0NDIxNjI1OS4wMTgsInN1YiI6IjY3ZjZhMGMzMWJjNjM5NTY2YWQ5MmM2ZSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.q8ltNrO7Ge_4RIT-UcOzzX3JjxVL3kIO5Q69HCh7wBg';

  Future<List<Show>> getPopularShows() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/discover/tv?include_adult=false&language=en-US&page=1&sort_by=popularity.desc'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((json) => Show.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load TV shows: ${response.statusCode}');
    }
  }

  Future<List<Show>> getTopRatedShows() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tv/top_rated?include_adult=false&language=en-US&page=1&sort_by=popularity.desc'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((json) => Show.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load TV shows: ${response.statusCode}');
    }
  }


  
  Future<List<Show>> searchShowsByKeyword(String keyword) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search/tv?query=$keyword&include_adult=false&language=en-US&page=1'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      }
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((json) => Show.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load TV shows: ${response.statusCode}');
    }
  }
}