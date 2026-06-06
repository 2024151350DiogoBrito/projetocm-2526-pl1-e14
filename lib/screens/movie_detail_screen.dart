import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import 'person_profile_screen.dart';

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
  final TmdbService _service = TmdbService();
  late Future<MovieDetail> _detailFuture;
  late Future<MovieCredits> _creditsFuture;
  late Future<List<WatchProvider>> _providersFuture;
  late Future<List<String>> _imagesFuture;
  late Future<List<Movie>> _similarFuture;
  late Future<String?> _trailerFuture;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.getMovieDetails(widget.movie.id);
    _creditsFuture = _service.getMovieCredits(widget.movie.id);
    _providersFuture = _service.getWatchProviders(widget.movie.id);
    _imagesFuture = _service.getMovieImages(widget.movie.id);
    _similarFuture = _service.getSimilarMovies(widget.movie.id);
    _trailerFuture = _service.getMovieTrailerKey(widget.movie.id);
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
    body: FutureBuilder<MovieDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero(detail)),
            SliverToBoxAdapter(child: _buildActions()),
            SliverToBoxAdapter(child: _buildProviders()),
            SliverToBoxAdapter(child: _buildCast()),
            SliverToBoxAdapter(child: _buildSynopsis()),
            if (detail != null)
              SliverToBoxAdapter(child: _buildTechnicalInfo(detail)),
            SliverToBoxAdapter(child: _buildGallery()),
            SliverToBoxAdapter(child: _buildRecommendations()),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    ),
  );

  Widget _buildHero(MovieDetail? detail) => SizedBox(
    height: 410,
    child: Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: widget.movie.fullBackdropPath,
          fit: BoxFit.cover,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.65),
                AppTheme.deepBlack,
              ],
            ),
          ),
        ),
        Positioned(
          top: 42,
          left: 18,
          child: _iconButton(Icons.close_rounded, () => Navigator.pop(context)),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: widget.movie.fullPosterPath,
                  width: 112,
                  height: 168,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ratingBadge(),
                    const SizedBox(height: 6),
                    Text(
                      widget.movie.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniMeta(
                          Icons.calendar_month_rounded,
                          _year(widget.movie.releaseDate),
                        ),
                        const SizedBox(width: 12),
                        if (detail != null)
                          _miniMeta(
                            Icons.schedule_rounded,
                            detail.runtimeFormatted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildActions() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
    child: Row(
      children: [
        Expanded(
          child: FutureBuilder<String?>(
            future: _trailerFuture,
            builder: (context, snapshot) => _largeButton(
              icon: Icons.play_arrow_rounded,
              label: 'TRAILER',
              isPrimary: true,
              onTap: () => _showTrailer(snapshot.data),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _largeButton(
            icon: _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: _isFavorite ? 'SAVED' : 'SAVE',
            isPrimary: false,
            onTap: _toggleFavorite,
          ),
        ),
      ],
    ),
  );

  Widget _buildProviders() => FutureBuilder<List<WatchProvider>>(
    future: _providersFuture,
    builder: (context, snapshot) {
      final providers = snapshot.data ?? [];
      if (providers.isEmpty) return const SizedBox.shrink();

      return _sectionCard(
        icon: Icons.tv_rounded,
        title: 'WHERE TO WATCH',
        child: SizedBox(
          height: 78,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Container(
                width: 66,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: provider.logoUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      provider.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );

  Widget _buildCast() => FutureBuilder<MovieCredits>(
    future: _creditsFuture,
    builder: (context, snapshot) {
      final cast = snapshot.data?.cast.take(12).toList() ?? [];
      if (cast.isEmpty) return const SizedBox.shrink();

      return _sectionBlock(
        icon: Icons.groups_rounded,
        title: 'MAIN CAST',
        child: SizedBox(
          height: 142,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final actor = cast[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonProfileScreen(
                      personId: actor.id,
                      fallbackName: actor.name,
                      onAddFavorite: widget.onAddFavorite,
                      onRemoveFavorite: widget.onRemoveFavorite,
                    ),
                  ),
                ),
                child: Container(
                  width: 88,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: actor.profileUrl!,
                          width: 88,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        actor.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        actor.character.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );

  Widget _buildSynopsis() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _redLineTitle('SYNOPSIS'),
        const SizedBox(height: 14),
        Text(
          widget.movie.overview.isEmpty
              ? 'No description available.'
              : widget.movie.overview,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.25,
          ),
        ),
      ],
    ),
  );

  Widget _buildTechnicalInfo(MovieDetail detail) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _redLineTitle('TECHNICAL INFORMATION'),
        const SizedBox(height: 16),
        _infoPill('GENRE', detail.genres.join(' • ').toUpperCase()),
        const SizedBox(height: 14),
        FutureBuilder<MovieCredits>(
          future: _creditsFuture,
          builder: (context, snapshot) {
            final director = snapshot.data?.director;
            if (director == null) return const SizedBox.shrink();
            return _crewPill(director);
          },
        ),
      ],
    ),
  );

  Widget _buildGallery() => FutureBuilder<List<String>>(
    future: _imagesFuture,
    builder: (context, snapshot) {
      final images = snapshot.data ?? [];
      if (images.isEmpty) return const SizedBox.shrink();

      return _sectionBlock(
        icon: Icons.image_outlined,
        title: 'GALLERY',
        top: 34,
        child: SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: images.length,
            itemBuilder: (context, index) => Container(
              width: 210,
              margin: const EdgeInsets.only(right: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _buildRecommendations() => FutureBuilder<List<Movie>>(
    future: _similarFuture,
    builder: (context, snapshot) {
      final movies = snapshot.data ?? [];
      if (movies.isEmpty) return const SizedBox.shrink();

      return _sectionBlock(
        icon: Icons.local_movies_outlined,
        title: 'RECOMMENDATIONS',
        top: 34,
        child: SizedBox(
          height: 176,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(
                      movie: movie,
                      onAddFavorite: widget.onAddFavorite,
                      onRemoveFavorite: widget.onRemoveFavorite,
                    ),
                  ),
                ),
                child: Container(
                  width: 112,
                  margin: const EdgeInsets.only(right: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: movie.fullPosterPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) => Container(
    margin: const EdgeInsets.fromLTRB(18, 24, 18, 0),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(icon, title),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _sectionBlock({
    required IconData icon,
    required String title,
    required Widget child,
    double top = 26,
  }) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _sectionHeader(icon, title),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _sectionHeader(IconData icon, String title) => Row(
    children: [
      Icon(icon, color: AppTheme.primaryRed, size: 21),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white30,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    ],
  );

  Widget _redLineTitle(String title) => Row(
    children: [
      Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.primaryRed,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white30,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _infoPill(String label, String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryRed,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );

  Widget _crewPill(CrewMember crew) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: crew.profileUrl == null
                ? Container(color: Colors.black26)
                : CachedNetworkImage(
                    imageUrl: crew.profileUrl!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              crew.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              crew.job.toUpperCase(),
              style: const TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _largeButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 30),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.black : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _ratingBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1E26).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppTheme.primaryRed, size: 15),
        const SizedBox(width: 4),
        Text(
          widget.movie.voteAverage.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _miniMeta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppTheme.primaryRed, size: 14),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );

  Widget _iconButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white),
    ),
  );

  void _showTrailer(String? key) {
    final message = key == null
        ? 'Trailer indisponível.'
        : 'YouTube: https://www.youtube.com/watch?v=$key';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primaryRed),
    );
  }

  String _year(String date) => date.length >= 4 ? date.substring(0, 4) : 'N/A';
}

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

  String get runtimeFormatted {
    if (runtime <= 0) return 'N/A';
    final h = runtime ~/ 60;
    final m = runtime % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

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
