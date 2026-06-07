import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import 'movie_detail_screen.dart';

class PersonProfileScreen extends StatefulWidget {
  final int personId;
  final String fallbackName;
  final Future<void> Function(Movie)? onAddFavorite;
  final Future<void> Function(Movie)? onRemoveFavorite;

  const PersonProfileScreen({
    super.key,
    required this.personId,
    required this.fallbackName,
    this.onAddFavorite,
    this.onRemoveFavorite,
  });

  @override
  State<PersonProfileScreen> createState() => _PersonProfileScreenState();
}

class _PersonProfileScreenState extends State<PersonProfileScreen> {
  final TmdbService _service = TmdbService();
  late Future<PersonDetail> _personFuture;
  late Future<List<Movie>> _creditsFuture;

  @override
  void initState() {
    super.initState();
    _personFuture = _service.getPersonDetails(widget.personId);
    _creditsFuture = _service.getPersonMovieCredits(widget.personId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildCredits()),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    ),
  );

  Widget _networkImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) => Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryRed,
            ),
          ),
    errorBuilder: (_, _, _) => Container(
      color: Colors.black26,
      child: const Icon(Icons.broken_image_outlined, color: Colors.white30),
    ),
  );

  Widget _buildHeader() => FutureBuilder<PersonDetail>(
    future: _personFuture,
    builder: (context, snapshot) {
      final person = snapshot.data;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 120,
                    height: 170,
                    child: person?.profileUrl == null
                        ? Container(
                            color: AppTheme.darkCard,
                            child: const Icon(Icons.person, size: 44),
                          )
                        : _networkImage(person!.profileUrl!),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (person?.name ?? widget.fallbackName).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        person?.knownFor ?? '',
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((person?.birthday ?? '').isNotEmpty)
                        Text(
                          person!.birthday,
                          style: const TextStyle(color: Colors.white54),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if ((person?.biography ?? '').isNotEmpty) ...[
              const SizedBox(height: 28),
              _sectionHeader(Icons.article_outlined, 'BIOGRAPHY'),
              const SizedBox(height: 12),
              Text(
                person!.biography,
                maxLines: 9,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _buildCredits() => FutureBuilder<List<Movie>>(
    future: _creditsFuture,
    builder: (context, snapshot) {
      final movies = snapshot.data ?? [];
      if (movies.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _sectionHeader(Icons.movie_filter_rounded, 'KNOWN FOR'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                itemCount: movies.length.clamp(0, 12),
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
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
                      width: 120,
                      margin: const EdgeInsets.only(right: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _networkImage(
                              movie.fullPosterPath,
                              height: 170,
                              width: 120,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            movie.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _sectionHeader(IconData icon, String label) => Row(
    children: [
      Icon(icon, color: AppTheme.primaryRed, size: 20),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    ],
  );
}
