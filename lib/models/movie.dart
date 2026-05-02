// modelo de dados para um filme
class Movie {
  // link base para carregar as imagens
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p';

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final String overview;
  final List<int> genreIds;

  // construtor da classe
  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.overview,
    required this.genreIds,
  });

  // cria o objeto a partir dos dados da API
  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
    id: json['id'],
    // verifica se é filme ou série para escolher o nome
    title: json['title'] ?? json['name'] ?? 'Sem Título',
    posterPath: json['poster_path'],
    backdropPath: json['backdrop_path'],
    // garante que a nota é um número decimal
    voteAverage: (json['vote_average'] as num? ?? 0.0).toDouble(),
    releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
    overview: json['overview'] ?? 'Nenhuma descrição disponível.',
    genreIds: List<int>.from(json['genre_ids'] ?? []),
  );

  // gera a URL completa para o poster
  String get fullPosterPath => posterPath != null
      ? '$_imageBaseUrl/w500$posterPath'
      : 'https://via.placeholder.com/500x750?text=sem+poster';

  // gera a URL completa para a imagem de fundo
  String get fullBackdropPath => backdropPath != null
      ? '$_imageBaseUrl/w780$backdropPath'
      : 'https://via.placeholder.com/1280x720?text=sem+backdrop';
}
