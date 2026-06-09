import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import 'movie_detail_screen.dart';

// ecrã dos filmes de um género
class GenreMoviesScreen extends StatefulWidget {
  final int genreId;
  final String genreName;
  final List<Movie> favoriteMovies;
  final Function(Movie) onAddFavorite;
  final Future<void> Function(Movie) onRemoveFavorite;

  const GenreMoviesScreen({
    super.key,
    required this.genreId,
    required this.genreName,
    required this.favoriteMovies,
    required this.onAddFavorite,
    required this.onRemoveFavorite,
  });

  @override
  State<GenreMoviesScreen> createState() => _GenreMoviesScreenState();
}

class _GenreMoviesScreenState extends State<GenreMoviesScreen> {
  final TmdbService _service = TmdbService();
  late Future<List<Movie>> _moviesFuture;

  // carrega os filmes do género
  @override
  void initState() {
    super.initState();
    _moviesFuture = _service.getMoviesByGenre(widget.genreId);
  }

  // constrói a página do género
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 58),
          _buildHeader(context),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Erro ao carregar filmes.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final movies = snapshot.data ?? [];
                if (movies.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sem filmes encontrados.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 110),
                  itemCount: movies.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 25,
                  ),
                  itemBuilder: (context, index) => _GenreMovieCard(
                    movie: movies[index],
                    isFavorite: _isFavorite(movies[index]),
                    onAddFavorite: widget.onAddFavorite,
                    onRemoveFavorite: widget.onRemoveFavorite,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  // constrói o cabeçalho
  Widget _buildHeader(BuildContext context) => Row(
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
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          widget.genreName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ],
  );

  // verifica se está nos favoritos
  bool _isFavorite(Movie movie) {
    return widget.favoriteMovies.any((m) => m.sameAs(movie));
  }
}

// cartão de um filme do género
class _GenreMovieCard extends StatelessWidget {
  final Movie movie;
  final bool isFavorite;
  final Function(Movie) onAddFavorite;
  final Future<void> Function(Movie) onRemoveFavorite;

  const _GenreMovieCard({
    required this.movie,
    required this.isFavorite,
    required this.onAddFavorite,
    required this.onRemoveFavorite,
  });

  // constrói o cartão do filme
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(
          movie: movie,
          isFavorite: isFavorite,
          onAddFavorite: (movie) async => onAddFavorite(movie),
          onRemoveFavorite: onRemoveFavorite,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              movie.fullPosterPath,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
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
          style: const TextStyle(color: Colors.white24, fontSize: 10),
        ),
      ],
    ),
  );
}
