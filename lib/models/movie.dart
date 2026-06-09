// modelo de dados para filmes e series vindos do TMDB
class Movie {
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p';

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final String overview;
  final List<int> genreIds;
  final String mediaType;
  final double popularity;
  final String originalLanguage;

  // cria um filme ou série
  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.overview,
    required this.genreIds,
    this.mediaType = 'movie',
    this.popularity = 0,
    this.originalLanguage = '',
  });

  // cria um filme a partir do json
  factory Movie.fromJson(Map<String, dynamic> json) {
    final type =
        json['media_type'] ??
        (json['name'] != null || json['first_air_date'] != null
            ? 'tv'
            : 'movie');

    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Sem Titulo',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num? ?? 0.0).toDouble(),
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      overview: json['overview'] ?? 'Nenhuma descricao disponivel.',
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      mediaType: type == 'tv' ? 'tv' : 'movie',
      popularity: (json['popularity'] as num? ?? 0.0).toDouble(),
      originalLanguage: json['original_language'] ?? '',
    );
  }

  // cria um filme a partir do firestore
  factory Movie.fromMap(Map<String, dynamic> map) => Movie(
    id: map['id'],
    title: map['title'] ?? 'Sem Titulo',
    posterPath: map['posterPath'],
    backdropPath: map['backdropPath'],
    voteAverage: (map['voteAverage'] as num? ?? 0.0).toDouble(),
    releaseDate: map['releaseDate'] ?? '',
    overview: map['overview'] ?? 'Nenhuma descricao disponivel.',
    genreIds: List<int>.from(map['genreIds'] ?? []),
    mediaType: map['mediaType'] ?? 'movie',
    popularity: (map['popularity'] as num? ?? 0.0).toDouble(),
    originalLanguage: map['originalLanguage'] ?? '',
  );

  // converte o filme para firestore
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'posterPath': posterPath,
    'backdropPath': backdropPath,
    'voteAverage': voteAverage,
    'releaseDate': releaseDate,
    'overview': overview,
    'genreIds': genreIds,
    'mediaType': mediaType,
    'popularity': popularity,
    'originalLanguage': originalLanguage,
  };

  // chave única para os favoritos
  String get favoriteKey => '${mediaType}_$id';

  // compara dois filmes ou séries
  bool sameAs(Movie other) => id == other.id && mediaType == other.mediaType;

  // devolve o poster completo
  String get fullPosterPath => posterPath != null
      ? '$_imageBaseUrl/w500$posterPath'
      : 'https://via.placeholder.com/500x750?text=sem+poster';

  // devolve o backdrop completo
  String get fullBackdropPath => backdropPath != null
      ? '$_imageBaseUrl/w780$backdropPath'
      : 'https://via.placeholder.com/1280x720?text=sem+backdrop';
}
