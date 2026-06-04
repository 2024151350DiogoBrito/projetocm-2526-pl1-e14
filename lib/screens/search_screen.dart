import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  final List<Movie> favoriteMovies;
  final List<String> recentSearches;
  final Function(Movie) onAddFavorite;
  final Function(String) onAddRecentSearch;

  const SearchScreen({
    super.key,
    required this.favoriteMovies,
    required this.recentSearches,
    required this.onAddFavorite,
    required this.onAddRecentSearch,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final TmdbService _service = TmdbService();

  List<Movie> _movies = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _searchMovies(String text) async {
    final query = text.trim();

    if (query.isEmpty) {
      return;
    }

    widget.onAddRecentSearch(query);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.searchMovies(query);

      setState(() {
        _movies = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erro ao carregar filmes.";
        _isLoading = false;
      });
    }
  }

  bool _isFavorite(Movie movie) {
    return widget.favoriteMovies.any((m) => m.id == movie.id);
  }

  void _favoriteMovie(Movie movie) {
    widget.onAddFavorite(movie);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${movie.title} adicionado aos favoritos"),
        backgroundColor: AppTheme.primaryRed,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.deepBlack,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildRecent(),
              const SizedBox(height: 25),
              _buildContent(),
            ],
          ),
        ),
      );

  Widget _buildSearchBar() => Row(
        children: [
          Expanded(
            child: Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF16171D),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: _searchMovies,
                      decoration: const InputDecoration(
                        hintText: "Movies, series, actors...",
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () => _searchMovies(_controller.text),
            child: Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF16171D),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.search, color: Colors.white),
            ),
          ),
        ],
      );

  Widget _buildRecent() {
    if (widget.recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.recentSearches
            .map((text) => _recentChip(text))
            .toList(),
      ),
    );
  }

  Widget _recentChip(String text) => GestureDetector(
        onTap: () {
          _controller.text = text;
          _searchMovies(text);
        },
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.grey, size: 14),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            "Pesquisa por um filme.",
            style: TextStyle(color: Colors.white24),
          ),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 15,
          mainAxisSpacing: 25,
        ),
        itemBuilder: (context, index) {
          final movie = _movies[index];

          return _MovieSearchItem(
            movie: movie,
            isFavorite: _isFavorite(movie),
            onFavorite: () => _favoriteMovie(movie),
          );
        },
      ),
    );
  }
}

class _MovieSearchItem extends StatelessWidget {
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const _MovieSearchItem({
    required this.movie,
    required this.isFavorite,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: NetworkImage(movie.fullPosterPath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: AppTheme.primaryRed,
                        size: 18,
                      ),
                    ),
                  ),
                ),
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
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      );
}