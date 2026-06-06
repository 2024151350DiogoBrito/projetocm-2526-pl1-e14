import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';

// ecrã de detalhes de um filme
class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  final bool isFavorite;
  final Future<void> Function(Movie)? onAddFavorite;
  final Future<void> Function(Movie)? onRemoveFavorite;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    this.isFavorite = false,
    this.onAddFavorite,
    this.onRemoveFavorite,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _service = TmdbService();
  late Future<MovieDetail> _detailFuture;
  late Future<List<Movie>> _similarFuture;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.getMovieDetails(widget.movie.id);
    _similarFuture = _service.getSimilarMovies(widget.movie.id);
    _isFavorite = widget.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final nextValue = !_isFavorite;

    setState(() => _isFavorite = nextValue);

    try {
      if (nextValue) {
        await widget.onAddFavorite?.call(widget.movie);
      } else {
        await widget.onRemoveFavorite?.call(widget.movie);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFavorite = !nextValue);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar os favoritos.'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: FutureBuilder<MovieDetail>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  ),
                );
              }
              final detail = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaRow(detail),
                  _buildOverview(),
                  _buildGenres(detail),
                  _buildInfoGrid(detail),
                  _buildSimilarMovies(),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ],
    ),
    // botão flutuante de trailer
    bottomNavigationBar: _buildBottomBar(),
  );

  // app bar com backdrop e efeito parallax
  Widget _buildSliverAppBar() => SliverAppBar(
    expandedHeight: 420,
    pinned: true,
    backgroundColor: AppTheme.deepBlack,
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: _circleBtn(
          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          _toggleFavorite,
          iconColor: _isFavorite ? AppTheme.primaryRed : Colors.white,
        ),
      ),
      const SizedBox(width: 4),
    ],
    flexibleSpace: FlexibleSpaceBar(
      collapseMode: CollapseMode.parallax,
      background: Stack(
        fit: StackFit.expand,
        children: [
          // imagem de fundo
          CachedNetworkImage(
            imageUrl: widget.movie.fullBackdropPath,
            fit: BoxFit.cover,
          ),
          // gradiente em cima da imagem
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  AppTheme.deepBlack,
                ],
              ),
            ),
          ),
          // poster e título no fundo
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // poster pequeno — usa o poster da API; esconde se não disponível
                FutureBuilder<MovieDetail>(
                  future: _detailFuture,
                  builder: (context, snap) {
                    final posterUrl = snap.data?.fullPosterPath;
                    // enquanto carrega mostra placeholder; se não tiver poster esconde
                    if (!snap.hasData) {
                      return Container(
                        width: 90,
                        height: 130,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      );
                    }
                    if (posterUrl == null) return const SizedBox.shrink();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: posterUrl,
                        width: 90,
                        height: 130,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // título e nota
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ratingRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // linha com estrelas e nota
  Widget _ratingRow() {
    final rating = widget.movie.voteAverage;
    final stars = (rating / 2).round().clamp(0, 5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppTheme.primaryRed,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${rating.toStringAsFixed(1)} / 10',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // linha com duração, ano e idioma
  Widget _buildMetaRow(MovieDetail detail) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Row(
      children: [
        if (detail.runtime > 0) ...[
          _metaChip(Icons.schedule_rounded, detail.runtimeFormatted),
          const SizedBox(width: 10),
        ],
        if (widget.movie.releaseDate.isNotEmpty) ...[
          _metaChip(
            Icons.calendar_today_rounded,
            widget.movie.releaseDate.substring(0, 4),
          ),
          const SizedBox(width: 10),
        ],
        if (detail.originalLanguage.isNotEmpty)
          _metaChip(
            Icons.language_rounded,
            detail.originalLanguage.toUpperCase(),
          ),
        const Spacer(),
        // badge de classificação
        if (detail.status.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryRed.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              detail.status.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryRed,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    ),
  );

  // sinopse do filme
  Widget _buildOverview() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SYNOPSIS'),
        const SizedBox(height: 10),
        Text(
          widget.movie.overview.isEmpty
              ? 'No description available.'
              : widget.movie.overview,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    ),
  );

  // lista de géneros
  Widget _buildGenres(MovieDetail detail) {
    if (detail.genres.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('GENRES'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detail.genres
                .map(
                  (g) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16171D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      g.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // grelha com informação adicional
  Widget _buildInfoGrid(MovieDetail detail) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('DETAILS'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _infoCard('Budget', detail.budgetFormatted)),
            const SizedBox(width: 12),
            Expanded(child: _infoCard('Revenue', detail.revenueFormatted)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _infoCard('Votes', '${detail.voteCount} votes')),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                'Popularity',
                detail.popularity.toStringAsFixed(0),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // secção de filmes semelhantes
  Widget _buildSimilarMovies() => Padding(
    padding: const EdgeInsets.only(top: 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: [
              Container(width: 3, height: 15, color: AppTheme.primaryRed),
              const SizedBox(width: 10),
              const Text(
                'YOU MIGHT ALSO LIKE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<Movie>>(
            future: _similarFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRed),
                );
              }
              if (snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No similar movies found.',
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, i) {
                  final m = snapshot.data![i];
                  return GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailScreen(
                          movie: m,
                          onAddFavorite: widget.onAddFavorite,
                          onRemoveFavorite: widget.onRemoveFavorite,
                        ),
                      ),
                    ),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: m.fullPosterPath,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  // barra de baixo com botão de acção
  Widget _buildBottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    decoration: BoxDecoration(
      color: AppTheme.deepBlack,
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
    ),
    child: Row(
      children: [
        // botão de adicionar à lista
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF16171D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(Icons.playlist_add_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        // botão principal
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('WATCH TRAILER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // widgets auxiliares
  Widget _circleBtn(
    IconData icon,
    VoidCallback onTap, {
    Color iconColor = Colors.white,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    ),
  );

  Widget _metaChip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white38, size: 13),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
    ),
  );

  Widget _infoCard(String label, String value) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF16171D),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// modelo extra para os detalhes completos
class MovieDetail {
  final int runtime;
  final String status;
  final String originalLanguage;
  final List<String> genres;
  final int budget;
  final int revenue;
  final int voteCount;
  final double popularity;
  final String? posterPath;

  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p';

  MovieDetail({
    required this.runtime,
    required this.status,
    required this.originalLanguage,
    required this.genres,
    required this.budget,
    required this.revenue,
    required this.voteCount,
    required this.popularity,
    this.posterPath,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) => MovieDetail(
    runtime: json['runtime'] ?? 0,
    status: json['status'] ?? '',
    originalLanguage: json['original_language'] ?? '',
    genres: (json['genres'] as List? ?? [])
        .map((g) => g['name'] as String)
        .toList(),
    budget: json['budget'] ?? 0,
    revenue: json['revenue'] ?? 0,
    voteCount: json['vote_count'] ?? 0,
    popularity: (json['popularity'] as num? ?? 0).toDouble(),
    posterPath: json['poster_path'],
  );

  String? get fullPosterPath =>
      posterPath != null ? '$_imageBaseUrl/w500$posterPath' : null;

  // formata duração em horas e minutos
  String get runtimeFormatted {
    if (runtime <= 0) return 'N/A';
    final h = runtime ~/ 60;
    final m = runtime % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  // formata valores monetários
  String _formatMoney(int value) {
    if (value <= 0) return 'N/A';
    if (value >= 1000000000) {
      return '\$${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(0)}M';
    return '\$$value';
  }

  String get budgetFormatted => _formatMoney(budget);
  String get revenueFormatted => _formatMoney(revenue);
}
