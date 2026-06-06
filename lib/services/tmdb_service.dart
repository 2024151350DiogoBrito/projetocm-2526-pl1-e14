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

  // vai buscar os filmes mais populares de um género específico sem conteúdo +18
  Future<List<Movie>> getMoviesByGenre(int genreId) =>
      _fetchMovies('discover/movie', {
        'with_genres': genreId.toString(),
        'sort_by': 'popularity.desc',
        'vote_count.gte': '300',
        'certification_country': 'US',
        'certification.lte': 'PG-13',
      });

  // vai buscar as próximas estreias com filtros
  Future<List<Movie>> getUpcomingMovies() {
    final today = DateTime.now().toString().split(' ').first;
    return _fetchMovies('discover/movie', {
      'region': 'PT',
      'sort_by': 'popularity.desc',
      'primary_release_date.gte': today,
      'primary_release_date.lte': '2026-12-31',
      'with_release_type': '2|3',
      'certification_country': 'US',
      'certification.lte': 'PG-13',
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

  Future<MovieCredits> getMovieCredits(int movieId) async {
    final data = await _getJson('movie/$movieId/credits');
    return MovieCredits.fromJson(data);
  }

  Future<List<WatchProvider>> getWatchProviders(int movieId) async {
    final data = await _getJson('movie/$movieId/watch/providers');
    final results = data['results'] as Map<String, dynamic>? ?? {};
    final region = results['PT'] ?? results['US'];
    final providers = region?['flatrate'] as List? ?? [];

    return providers
        .take(6)
        .map((provider) => WatchProvider.fromJson(provider))
        .toList();
  }

  Future<List<String>> getMovieImages(int movieId) async {
    final data = await _getJson('movie/$movieId/images', {
      'include_image_language': 'en,null',
    });
    final backdrops = data['backdrops'] as List? ?? [];

    return backdrops
        .take(8)
        .map((image) => image['file_path'] as String?)
        .whereType<String>()
        .map((path) => 'https://image.tmdb.org/t/p/w780$path')
        .toList();
  }

  Future<String?> getMovieTrailerKey(int movieId) async {
    final data = await _getJson('movie/$movieId/videos');
    final videos = data['results'] as List? ?? [];

    for (final video in videos) {
      if (video['site'] == 'YouTube' && video['type'] == 'Trailer') {
        return video['key'] as String?;
      }
    }

    return null;
  }

  Future<PersonDetail> getPersonDetails(int personId) async {
    final data = await _getJson('person/$personId');
    return PersonDetail.fromJson(data);
  }

  Future<List<Movie>> getPersonMovieCredits(int personId) async {
    final data = await _getJson('person/$personId/movie_credits');
    final cast = data['cast'] as List? ?? [];

    return cast
        .where(
          (movie) =>
              movie['poster_path'] != null &&
              movie['backdrop_path'] != null &&
              movie['adult'] != true &&
              _looksSafeTitle(movie['title'] ?? ''),
        )
        .map((movie) => Movie.fromJson(movie))
        .toList();
  }

  // vai buscar filmes semelhantes
  Future<List<Movie>> getSimilarMovies(int movieId) =>
      _fetchMovies('movie/$movieId/similar');

  Future<Map<String, dynamic>> _getJson(
    String endpoint, [
    Map<String, String>? params,
  ]) async {
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: {'api_key': _apiKey, 'language': 'en-US', ...?params},
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Erro na API: ${response.statusCode}');
  }

  // função que faz o pedido à rede e trata os dados
  Future<List<Movie>> _fetchMovies(
    String endpoint, [
    Map<String, String>? params,
  ]) async {
    // monta o link com a chave e parâmetros
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(
      queryParameters: {
        'api_key': _apiKey,
        'language': 'en-US',
        'include_adult': 'false',
        ...?params,
      },
    );

    // faz o pedido get
    final response = await http.get(uri);

    // verifica se a ligação foi bem sucedida
    if (response.statusCode == 200) {
      final List results = json.decode(response.body)['results'];

      // filtra filmes sem imagem, conteúdo adulto e títulos claramente +18
      return results
          .where(
            (m) =>
                m['poster_path'] != null &&
                m['backdrop_path'] != null &&
                m['adult'] != true &&
                _looksSafeTitle(m['title'] ?? m['name'] ?? ''),
          )
          .map((m) => Movie.fromJson(m))
          .toList();
    }

    // erro se a api falhar
    throw Exception('Erro na API: ${response.statusCode}');
  }

  bool _looksSafeTitle(String title) {
    final text = title.toLowerCase();
    const blockedWords = [
      'porn',
      'pornhub',
      'sex',
      'erotic',
      'nude',
      'naked',
      'xxx',
    ];

    return !blockedWords.any(text.contains);
  }
}

class MovieCredits {
  final List<CastMember> cast;
  final List<CrewMember> crew;

  MovieCredits({required this.cast, required this.crew});

  factory MovieCredits.fromJson(Map<String, dynamic> json) => MovieCredits(
    cast: (json['cast'] as List? ?? [])
        .map((member) => CastMember.fromJson(member))
        .where((member) => member.profileUrl != null)
        .toList(),
    crew: (json['crew'] as List? ?? [])
        .map((member) => CrewMember.fromJson(member))
        .toList(),
  );

  CrewMember? get director {
    for (final member in crew) {
      if (member.job.toLowerCase() == 'director') return member;
    }
    return crew.isEmpty ? null : crew.first;
  }
}

class CastMember {
  final int id;
  final String name;
  final String character;
  final String? profileUrl;

  CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profileUrl,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    character: json['character'] ?? '',
    profileUrl: json['profile_path'] == null
        ? null
        : 'https://image.tmdb.org/t/p/w300${json['profile_path']}',
  );
}

class CrewMember {
  final String name;
  final String job;
  final String? profileUrl;

  CrewMember({required this.name, required this.job, this.profileUrl});

  factory CrewMember.fromJson(Map<String, dynamic> json) => CrewMember(
    name: json['name'] ?? '',
    job: json['job'] ?? '',
    profileUrl: json['profile_path'] == null
        ? null
        : 'https://image.tmdb.org/t/p/w300${json['profile_path']}',
  );
}

class WatchProvider {
  final String name;
  final String logoUrl;

  WatchProvider({required this.name, required this.logoUrl});

  factory WatchProvider.fromJson(Map<String, dynamic> json) => WatchProvider(
    name: json['provider_name'] ?? '',
    logoUrl: 'https://image.tmdb.org/t/p/w185${json['logo_path']}',
  );
}

class PersonDetail {
  final String name;
  final String biography;
  final String? profileUrl;
  final String knownFor;
  final String birthday;
  final String placeOfBirth;

  PersonDetail({
    required this.name,
    required this.biography,
    this.profileUrl,
    required this.knownFor,
    required this.birthday,
    required this.placeOfBirth,
  });

  factory PersonDetail.fromJson(Map<String, dynamic> json) => PersonDetail(
    name: json['name'] ?? '',
    biography: json['biography'] ?? '',
    profileUrl: json['profile_path'] == null
        ? null
        : 'https://image.tmdb.org/t/p/w500${json['profile_path']}',
    knownFor: json['known_for_department'] ?? '',
    birthday: json['birthday'] ?? '',
    placeOfBirth: json['place_of_birth'] ?? '',
  );
}
