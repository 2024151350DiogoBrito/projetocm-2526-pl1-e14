import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'movie_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Movie> favoriteMovies;
  final Future<void> Function(Movie) onAddFavorite;
  final Function(Movie) onRemoveFavorite;

  const FavoritesScreen({
    super.key,
    required this.favoriteMovies,
    required this.onAddFavorite,
    required this.onRemoveFavorite,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _recentFirst = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 70),
          _buildHeader(),
          const SizedBox(height: 30),
          _buildGrid(),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1.5,
              ),
              children: [
                TextSpan(
                  text: 'MY ',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'LIST',
                  style: TextStyle(color: AppTheme.primaryRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "YOU HAVE ${widget.favoriteMovies.length} ITEMS SAVED",
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      _buildFilterBtn(),
    ],
  );

  Widget _buildFilterBtn() => GestureDetector(
    onTap: () {
      setState(() {
        _recentFirst = !_recentFirst;
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16171D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_vert_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text(
            _recentFirst ? "Recent" : "Oldest",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildGrid() {
    if (widget.favoriteMovies.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            "Ainda não tens filmes favoritos.",
            style: TextStyle(color: Colors.white24),
          ),
        ),
      );
    }

    final List<Movie> movies = _recentFirst
        ? widget.favoriteMovies.reversed.toList()
        : List<Movie>.from(widget.favoriteMovies);

    return Expanded(
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 15,
          mainAxisSpacing: 25,
        ),
        itemCount: movies.length,
        itemBuilder: (context, i) {
          final movie = movies[i];

          return _MovieGridItem(
            movie: movie,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(
                  movie: movie,
                  isFavorite: true,
                  onAddFavorite: widget.onAddFavorite,
                  onRemoveFavorite: (movie) async =>
                      widget.onRemoveFavorite(movie),
                ),
              ),
            ),
            onRemove: () => widget.onRemoveFavorite(movie),
          );
        },
      ),
    );
  }
}

class _MovieGridItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MovieGridItem({
    required this.movie,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              _buildPoster(),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.primaryRed,
                      size: 18,
                    ),
                  ),
                ),
              ),
              _buildRatingBadge(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          movie.title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          movie.releaseDate,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildPoster() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      image: DecorationImage(
        image: NetworkImage(movie.fullPosterPath),
        fit: BoxFit.cover,
      ),
    ),
  );

  Widget _buildRatingBadge() => Positioned(
    bottom: 8,
    left: 8,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppTheme.primaryRed, size: 12),
          const SizedBox(width: 4),
          Text(
            movie.voteAverage.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
