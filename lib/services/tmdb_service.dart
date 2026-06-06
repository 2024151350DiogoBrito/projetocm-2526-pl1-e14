import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../screens/movie_detail_screen.dart';

// serviço para ligar à API do TMDB
class TmdbService {
  // chave e link base da API
  static const String _apiKey = 'af0ee5bf1f5c5f67fad644253370dae4';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // vai buscar os filmes em tendência
  Future<List<Movie>> getTrendingMovies() => _fetchMovies('trending/movie/day');

  // vai buscar os filmes populares
  Future<List<Movie>> getPopularMovies() => _fetchMovies('movie/popular');

  // pesquisa filmes por nome
  Future<List<Movie>> searchMovies(String query) => query.isEmpty
      ? Future.value([])
      : _fetchMovies('search/movie', {'query': query});

  // vai buscar filmes de um gÃ©nero especÃ­fico
  Future<List<Movie>> getMoviesByGenre(int genreId) => _fetchMovies(
    'discover/movie',
    {'with_genres': genreId.toString(), 'sort_by': 'popularity.desc'},
  );

  // vai buscar as próximas estreias com filtros
  Future<List<Movie>> getUpcomingMovies() {
    final today = DateTime.now().toString().split(' ').first;
    return _fetchMovies('discover/movie', {
      'region': 'PT',
      'sort_by': 'popularity.desc',
      'primary_release_date.gte': today,
      'primary_release_date.lte': '2026-12-31',
      'with_release_type': '2|3',
    });
  }

  // vai buscar os detalhes completos de um filme
  Future<MovieDetail> getMovieDetails(int movieId) async {
    final uri = Uri.parse(
      '$_baseUrl/movie/$movieId',
    ).replace(queryParameters: {'api_key': _apiKey, 'language': 'en-US'});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return MovieDetail.fromJson(json.decode(response.body));
    }
    throw Exception('Erro ao carregar detalhes: ${response.statusCode}');
  }

  // vai buscar filmes semelhantes
  Future<List<Movie>> getSimilarMovies(int movieId) =>
      _fetchMovies('movie/$movieId/similar');

  // função que faz o pedido à rede e trata os dados
  Future<List<Movie>> _fetchMovies(
    String endpoint, [
    Map<String, String>? params,
  ]) async {
    // monta o link com a chave e parâmetros
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: {'api_key': _apiKey, 'language': 'en-US', ...?params},
    );

    // faz o pedido get
    final response = await http.get(uri);

    // verifica se a ligação foi bem sucedida
    if (response.statusCode == 200) {
      final List results = json.decode(response.body)['results'];

      // filtra filmes sem imagem e converte para a lista
      return results
          .where((m) => m['poster_path'] != null && m['backdrop_path'] != null)
          .map((m) => Movie.fromJson(m))
          .toList();
    }

    // erro se a api falhar
    throw Exception('Erro na API: ${response.statusCode}');
  }
}
