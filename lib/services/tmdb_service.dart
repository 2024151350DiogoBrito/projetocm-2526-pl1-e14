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
  Future<List<Movie>> getTrendingMovies() => _fetchMovies('trending/all/day');

  // vai buscar os filmes populares
  Future<List<Movie>> getPopularMovies() async {
    final movies = await _fetchMovies('movie/popular');
    final series = await _fetchMovies('tv/popular');
    return _sortByPopularity([...movies, ...series]);
  }

  // pesquisa filmes por nome
  Future<List<Movie>> searchMovies(String query) => query.isEmpty
      ? Future.value([])
      : _fetchMovies('search/multi', {'query': query});

  // vai buscar os filmes mais populares de um género específico sem conteúdo +18
  Future<List<Movie>> getMoviesByGenre(int genreId) async {
    final movies = await _fetchMovies('discover/movie', {
      'with_genres': genreId.toString(),
      'sort_by': 'popularity.desc',
      'vote_count.gte': '300',
      'certification_country': 'US',
      'certification.lte': 'PG-13',
    });
    final series = await _fetchMovies('discover/tv', {
      'with_genres': genreId.toString(),
      'sort_by': 'popularity.desc',
      'vote_count.gte': '300',
    });

    return _sortByPopularity([...movies, ...series]);
  }

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
  Future<MovieDetail> getMovieDetails(
    int movieId, {
    String mediaType = 'movie',
  }) async {
    final endpoint = mediaType == 'tv' ? 'tv' : 'movie';
    final uri = Uri.parse(
      '$_baseUrl/$endpoint/$movieId',
    ).replace(queryParameters: {'api_key': _apiKey, 'language': 'en-US'});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return MovieDetail.fromJson(json.decode(response.body));
    }
    throw Exception('Erro ao carregar detalhes: ${response.statusCode}');
  }

  Future<MovieCredits> getMovieCredits(
    int movieId, {
    String mediaType = 'movie',
  }) async {
    final endpoint = mediaType == 'tv' ? 'tv' : 'movie';
    final data = await _getJson('$endpoint/$movieId/credits');
    return MovieCredits.fromJson(data);
  }

  Future<List<WatchProvider>> getWatchProviders(
    int movieId, {
    String mediaType = 'movie',
  }) async {
    final endpoint = mediaType == 'tv' ? 'tv' : 'movie';
    final data = await _getJson('$endpoint/$movieId/watch/providers');
    final results = data['results'] as Map<String, dynamic>? ?? {};
    final region = results['PT'] ?? results['US'];
    final providers = region?['flatrate'] as List? ?? [];

    return providers
        .take(6)
        .map((provider) => WatchProvider.fromJson(provider))
        .toList();
  }

  Future<List<String>> getMovieImages(
    int movieId, {
    String mediaType = 'movie',
  }) async {
    final endpoint = mediaType == 'tv' ? 'tv' : 'movie';
    final data = await _getJson('$endpoint/$movieId/images', {
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

  Future<String?> getMovieTrailerKey(
    int movieId, {
    String mediaType = 'movie',
  }) async {
    final endpoint = mediaType == 'tv' ? 'tv' : 'movie';
    final data = await _getJson('$endpoint/$movieId/videos');
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
    final data = await _getJson('person/$personId/combined_credits');
    final cast = data['cast'] as List? ?? [];

    return cast
        .where(
          (movie) =>
              movie['poster_path'] != null &&
              movie['backdrop_path'] != null &&
              movie['adult'] != true &&
              (movie['media_type'] == 'movie' || movie['media_type'] == 'tv') &&
              _looksSafeTitle(movie['title'] ?? movie['name'] ?? ''),
        )
        .map((movie) => Movie.fromJson(movie))
        .toList();
  }

  // vai buscar filmes semelhantes
  Future<List<Movie>> getSimilarMovies(
    int movieId, {
    String mediaType = 'movie',
  }) {
    final endpoint = mediaType == 'tv' ? 'tv' : 'movie';
    return _fetchMovies('$endpoint/$movieId/similar');
  }

  Future<List<Movie>> getSmartRecommendations(Movie source) async {
    final endpoint = source.mediaType == 'tv' ? 'tv' : 'movie';
    final detail = await _getJson('$endpoint/${source.id}');
    final sourceLanguage = detail['original_language'] as String? ?? 'en';
    final recommendations = <Movie>[];

    if (source.mediaType == 'movie') {
      final collection =
          detail['belongs_to_collection'] as Map<String, dynamic>?;
      final collectionId = collection?['id'];
      if (collectionId is int) {
        final collectionMovies = await _fetchCollectionMovies(
          collectionId,
          sourceLanguage,
        );
        recommendations.addAll(collectionMovies);
      }
    }

    recommendations.addAll(
      await _fetchMovies('$endpoint/${source.id}/recommendations'),
    );

    final keywords = await _getKeywords(source.id, source.mediaType);
    if (keywords.isNotEmpty) {
      recommendations.addAll(
        await _fetchMovies('discover/$endpoint', {
          'sort_by': 'popularity.desc',
          'vote_count.gte': '300',
          'with_keywords': keywords.take(4).join('|'),
          if (sourceLanguage == 'en') 'with_original_language': 'en',
        }),
      );
    }

    if (recommendations.length < 10 && source.genreIds.isNotEmpty) {
      recommendations.addAll(
        await _fetchMovies('discover/$endpoint', {
          'sort_by': 'popularity.desc',
          'vote_count.gte': '500',
          'with_genres': source.genreIds.take(2).join(','),
          if (sourceLanguage == 'en') 'with_original_language': 'en',
        }),
      );
    }

    return _rankRecommendations(
      recommendations,
      source,
      sourceLanguage,
    ).take(18).toList();
  }

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

  Future<List<Movie>> _fetchCollectionMovies(
    int collectionId,
    String sourceLanguage,
  ) async {
    final data = await _getJson('collection/$collectionId');
    final parts = data['parts'] as List? ?? [];

    return parts
        .where(
          (movie) =>
              movie['poster_path'] != null &&
              movie['backdrop_path'] != null &&
              movie['adult'] != true &&
              (sourceLanguage != 'en' || movie['original_language'] == 'en') &&
              _looksSafeTitle(movie['title'] ?? ''),
        )
        .map((movie) => Movie.fromJson({...movie, 'media_type': 'movie'}))
        .toList();
  }

  Future<List<String>> _getKeywords(int id, String mediaType) async {
    final endpoint = mediaType == 'tv' ? 'tv' : 'movie';
    final data = await _getJson('$endpoint/$id/keywords');
    final rawKeywords = mediaType == 'tv'
        ? data['results'] as List? ?? []
        : data['keywords'] as List? ?? [];

    return rawKeywords
        .where((keyword) {
          final name = (keyword['name'] ?? '').toString().toLowerCase();
          return name.isNotEmpty &&
              !name.contains('anime') &&
              !name.contains('based on manga');
        })
        .map((keyword) => keyword['id']?.toString())
        .whereType<String>()
        .toList();
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

  List<Movie> _rankRecommendations(
    List<Movie> items,
    Movie source,
    String sourceLanguage,
  ) {
    final seen = <String>{};
    final filtered = <Movie>[];

    for (final item in items) {
      if (item.sameAs(source)) continue;
      if (sourceLanguage == 'en' && item.originalLanguage == 'ja') continue;
      if (sourceLanguage == 'en' && item.mediaType == source.mediaType) {
        final suspiciousJapanese = item.title.contains(
          RegExp(r'[\u3040-\u30ff]'),
        );
        if (suspiciousJapanese) continue;
      }
      if (seen.add(item.favoriteKey)) filtered.add(item);
    }

    filtered.sort((a, b) {
      final aScore = _recommendationScore(a, source);
      final bScore = _recommendationScore(b, source);
      return bScore.compareTo(aScore);
    });

    return filtered;
  }

  double _recommendationScore(Movie item, Movie source) {
    final sharedGenres = item.genreIds
        .where((genreId) => source.genreIds.contains(genreId))
        .length;
    var score = item.popularity + (sharedGenres * 80);

    final sourceWords = source.title
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.length >= 4)
        .toSet();
    final itemWords = item.title
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.length >= 4)
        .toSet();
    score += sourceWords.intersection(itemWords).length * 120;

    return score;
  }

  List<Movie> _sortByPopularity(List<Movie> items) {
    final sorted = [...items];
    sorted.sort((a, b) => b.popularity.compareTo(a.popularity));
    return sorted;
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
