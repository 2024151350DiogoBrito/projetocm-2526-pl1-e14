import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import 'genre_movies_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Movie> favoriteMovies;
  final List<String> recentSearches;
  final Function(Movie) onAddFavorite;
  final Function(String) onAddRecentSearch;
  final VoidCallback onClearRecentSearches;

  const SearchScreen({
    super.key,
    required this.favoriteMovies,
    required this.recentSearches,
    required this.onAddFavorite,
    required this.onAddRecentSearch,
    required this.onClearRecentSearches,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final TmdbService _service = TmdbService();

  final List<_GenreItem> _genres = const [
    _GenreItem(
      id: 28,
      name: 'ACTION',
      imageUrl:
          'https://image.tmdb.org/t/p/w780/7dzngS8pLkGJpyeskCFcjPO9qLF.jpg',
    ),
    _GenreItem(
      id: 12,
      name: 'ADVENTURE',
      imageUrl:
          'https://image.tmdb.org/t/p/w780/57JocxmicOoAMhkUSmdKBlpZWMT.jpg',
    ),
    _GenreItem(
      id: 16,
      name: 'ANIMATION',
      imageUrl:
          'https://image.tmdb.org/t/p/w780/8mnXR9rey5uQ08rZAvzojKWbDQS.jpg',
    ),
    _GenreItem(
      id: 35,
      name: 'COMEDY',
      imageUrl:
          'https://image.tmdb.org/t/p/w780/mLyW3UTgi2lsMdtueYODcfAB9Ku.jpg',
    ),
    _GenreItem(
      id: 80,
      name: 'CRIME',
      imageUrl:
          'https://image.tmdb.org/t/p/w780/tSPT36ZKlP2WVHJLM4cQPLSzv3b.jpg',
    ),
    _GenreItem(
      id: 99,
      name: 'DOCUMENTARY',
      imageUrl:
          'https://image.tmdb.org/t/p/w780/m6bIek9WBacbpx6flktKHMSaUqX.jpg',
    ),
    _GenreItem(
      id: 18,
      name: 'DRAMA',
      imageUrl:
          'https://image.tmdb.org/t/p/w780/neeNHeXjMF5fXoCJRsOmkNGC7q.jpg',
    ),
    _GenreItem(
      id: 10751,
      name: 'FAMILY',
      imageUrl:
          'https://image.tmdb.org/t/p/w780/3Rfvhy1Nl6sSGJwyjb0QiZzZYlB.jpg',
    ),
  ];

  List<Movie> _movies = [];
  List<Movie> _trending = [];
  bool _isLoading = false;
  bool _isLoadingTrending = true;
  bool _hasSearched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrendingSearches();
  }

  Future<void> _loadTrendingSearches() async {
    try {
      final movies = await _service.getTrendingMovies();
      if (!mounted) return;
      setState(() {
        _trending = movies.take(5).toList();
        _isLoadingTrending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _searchMovies(String text) async {
    final query = text.trim();

    if (query.isEmpty) {
      return;
    }

    widget.onAddRecentSearch(query);

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final results = await _service.searchMovies(query);

      if (!mounted) return;
      setState(() {
        _movies = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar filmes.';
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() {
      _movies = [];
      _hasSearched = false;
      _isLoading = false;
      _error = null;
    });
  }

  bool _isFavorite(Movie movie) {
    return widget.favoriteMovies.any((m) => m.id == movie.id);
  }

  void _favoriteMovie(Movie movie) {
    widget.onAddFavorite(movie);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${movie.title} adicionado aos favoritos'),
        backgroundColor: AppTheme.primaryRed,
      ),
    );
  }

  void _openGenre(_GenreItem genre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GenreMoviesScreen(genreId: genre.id, genreName: genre.name),
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
    body: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          _buildSearchBar(),
          const SizedBox(height: 14),
          _buildRecent(),
          const SizedBox(height: 30),
          if (_hasSearched) _buildSearchContent() else _buildDiscoverContent(),
          const SizedBox(height: 120),
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
              const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _searchMovies,
                  decoration: const InputDecoration(
                    hintText: 'Movies, series, actors...',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                    isCollapsed: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_hasSearched) ...[
        const SizedBox(width: 15),
        GestureDetector(onTap: _clearSearch, child: _searchActionBtn()),
      ],
    ],
  );

  Widget _searchActionBtn() => Container(
    height: 55,
    width: 55,
    decoration: BoxDecoration(
      color: const Color(0xFF16171D),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    ),
    child: const Icon(Icons.close_rounded, color: Colors.white),
  );

  Widget _buildRecent() {
    if (widget.recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.recentSearches
                  .map((text) => _recentChip(text))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.onClearRecentSearches,
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.grey,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentChip(String text) => GestureDetector(
    onTap: () {
      _controller.text = text;
      _searchMovies(text);
    },
    child: Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.grey, size: 13),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    ),
  );

  Widget _buildDiscoverContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_buildTrending(), const SizedBox(height: 36), _buildGenreGrid()],
  );

  Widget _buildTrending() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.trending_up_rounded, color: AppTheme.primaryRed, size: 20),
          SizedBox(width: 10),
          Text(
            'TRENDING SEARCHES',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (_isLoadingTrending)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(
            color: AppTheme.primaryRed,
            strokeWidth: 2,
          ),
        )
      else
        for (int i = 0; i < _trending.length; i++)
          _trendingRow(i, _trending[i].title),
    ],
  );

  Widget _trendingRow(int index, String title) => GestureDetector(
    onTap: () {
      _controller.text = title;
      _searchMovies(title);
    },
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '0${index + 1}',
            style: const TextStyle(
              color: Color(0xFF30415D),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildGenreGrid() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'EXPLORE GENRES',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 12) / 2;
          final cardHeight = cardWidth.clamp(86.0, 112.0);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: cardHeight,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            itemCount: _genres.length,
            itemBuilder: (_, i) => _genreCard(_genres[i]),
          );
        },
      ),
    ],
  );

  Widget _genreCard(_GenreItem genre) => GestureDetector(
    onTap: () => _openGenre(genre),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(genre.imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.darken,
          ),
        ),
      ),
      child: Center(
        child: Text(
          genre.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
  );

  Widget _buildSearchContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 360,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 360,
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const SizedBox(
        height: 360,
        child: Center(
          child: Text(
            'Sem resultados.',
            style: TextStyle(color: Colors.white24),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
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
    );
  }
}

class _GenreItem {
  final int id;
  final String name;
  final String imageUrl;

  const _GenreItem({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
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
