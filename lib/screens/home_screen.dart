import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Movie> favoriteMovies;
  final Future<void> Function(Movie) onAddFavorite;
  final Future<void> Function(Movie) onRemoveFavorite;
  final VoidCallback onOpenNotifications;
  final int unreadNotifications;

  const HomeScreen({
    super.key,
    required this.favoriteMovies,
    required this.onAddFavorite,
    required this.onRemoveFavorite,
    required this.onOpenNotifications,
    required this.unreadNotifications,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService _service = TmdbService();
  final List<_HomeCategory> _categories = const [
    _HomeCategory("ALL", null, "✨"),
    _HomeCategory("ACTION", 28, "💥"),
    _HomeCategory("ADVENTURE", 12, "🧭"),
    _HomeCategory("ANIMATION", 16, "🎨"),
    _HomeCategory("COMEDY", 35, "😂"),
    _HomeCategory("CRIME", 80, "🕵️"),
    _HomeCategory("DOCUMENTARY", 99, "🌍"),
    _HomeCategory("DRAMA", 18, "🎭"),
    _HomeCategory("FAMILY", 10751, "👪"),
  ];

  String _selectedCategory = "ALL";
  late Future<List<Movie>> _trending;
  late Future<List<Movie>> _popular;
  late Future<List<Movie>> _upcoming;
  late Future<List<Movie>> _genreMovies;

  @override
  void initState() {
    super.initState();
    _trending = _service.getTrendingMovies();
    _popular = _service.getPopularMovies();
    _upcoming = _service.getUpcomingMovies();
    _genreMovies = Future.value([]);
  }

  Future<List<Movie>> get _heroMovies =>
      _selectedCategory == "ALL" ? _trending : _genreMovies;

  void _selectCategory(_HomeCategory category) {
    setState(() {
      _selectedCategory = category.name;
      if (category.id != null) {
        _genreMovies = _service.getMoviesByGenre(category.id!);
      }
    });
  }

  bool _isFavorite(Movie movie) {
    return widget.favoriteMovies.any((m) => m.sameAs(movie));
  }

  Future<void> _toggleFavorite(Movie movie) async {
    if (_isFavorite(movie)) {
      await widget.onRemoveFavorite(movie);
    } else {
      await widget.onAddFavorite(movie);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.deepBlack,
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildHero()),
        SliverToBoxAdapter(child: _buildCategories()),
        SliverToBoxAdapter(child: _buildMovieSections()),
      ],
    ),
  );

  Widget _buildAppBar() => SliverAppBar(
    backgroundColor: AppTheme.deepBlack.withValues(alpha: 0.9),
    floating: true,
    leadingWidth: 150,
    leading: Padding(
      padding: const EdgeInsets.only(left: 20, top: 15),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1,
          ),
          children: [
            TextSpan(
              text: 'MOVIE',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'NEST',
              style: TextStyle(color: AppTheme.primaryRed),
            ),
          ],
        ),
      ),
    ),
    actions: [_notificationButton(), const SizedBox(width: 10)],
  );

  Widget _notificationButton() => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        onPressed: widget.onOpenNotifications,
        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
      ),
      if (widget.unreadNotifications > 0)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.unreadNotifications > 9
                  ? '9+'
                  : widget.unreadNotifications.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _buildHero() => FutureBuilder<List<Movie>>(
    future: _heroMovies,
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Container(
          height: 550,
          color: const Color(0xFF0F1014),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          ),
        );
      }

      final hero = snapshot.data!.first;
      return Stack(
        children: [
          Image.network(
            hero.fullBackdropPath,
            height: 550,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          _buildHeroGradient(),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildHeroContent(hero),
          ),
        ],
      );
    },
  );

  Widget _buildHeroGradient() => Positioned.fill(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 0.95],
          colors: [
            AppTheme.deepBlack.withValues(alpha: 0.3),
            Colors.transparent,
            AppTheme.deepBlack,
          ],
        ),
      ),
    ),
  );

  Widget _buildHeroContent(Movie hero) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _badge(
            _selectedCategory == "ALL" ? "TRENDING #1" : _selectedCategory,
          ),
          const SizedBox(width: 10),
          const Icon(Icons.star_rounded, color: AppTheme.primaryRed, size: 16),
          const SizedBox(width: 4),
          Text(
            hero.voteAverage.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        hero.title.toUpperCase(),
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: Colors.white,
          height: 0.9,
          letterSpacing: -1.5,
        ),
      ),
      const SizedBox(height: 30),
      Row(
        children: [
          Expanded(
            child: _actionBtn(
              "VIEW DETAILS",
              onTap: () => _openDetail(context, hero),
            ),
          ),
          const SizedBox(width: 15),
          _favBtn(hero),
        ],
      ),
    ],
  );

  Widget _buildCategories() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Row(
      children: _categories.map((cat) {
        final isSel = _selectedCategory == cat.name;
        return GestureDetector(
          onTap: () => _selectCategory(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: isSel ? AppTheme.primaryRed : const Color(0xFF16171D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSel
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.05),
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryRed.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              "${cat.emoji} ${cat.name}",
              style: TextStyle(
                color: isSel ? Colors.white : Colors.grey.shade500,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.2,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _buildMovieSections() {
    if (_selectedCategory != "ALL") {
      return Column(
        children: [
          _sectionTitle(
            "${_selectedCategoryEmoji()} $_selectedCategory Movies",
          ),
          _movieList(_genreMovies, 'poster'),
          const SizedBox(height: 120),
        ],
      );
    }

    return Column(
      children: [
        _sectionTitle("✨ Global Trending"),
        _movieList(_trending, 'backdrop'),
        _sectionTitle("🔥 Hot Hits"),
        _movieList(_popular, 'poster'),
        _sectionTitle("🎬 Upcoming Releases"),
        _movieList(_upcoming, 'backdrop'),
        const SizedBox(height: 120),
      ],
    );
  }

  String _selectedCategoryEmoji() => _categories
      .firstWhere((category) => category.name == _selectedCategory)
      .emoji;

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
    child: Row(
      children: [
        Container(width: 3, height: 15, color: AppTheme.primaryRed),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );

  Widget _movieList(Future<List<Movie>> future, String layout) => SizedBox(
    height: layout == 'backdrop' ? 160 : 220,
    child: FutureBuilder<List<Movie>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No movies found.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) => layout == 'poster'
              ? MovieCard(
                  movie: snapshot.data![i],
                  onTap: () => _openDetail(context, snapshot.data![i]),
                )
              : _backdropItem(snapshot.data![i]),
        );
      },
    ),
  );

  void _openDetail(BuildContext ctx, Movie movie) => Navigator.push(
    ctx,
    MaterialPageRoute(
      builder: (_) => MovieDetailScreen(
        movie: movie,
        isFavorite: _isFavorite(movie),
        onAddFavorite: widget.onAddFavorite,
        onRemoveFavorite: widget.onRemoveFavorite,
      ),
    ),
  );

  Widget _backdropItem(Movie movie) => GestureDetector(
    onTap: () => _openDetail(context, movie),
    child: Container(
      width: 240,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(movie.fullBackdropPath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            movie.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _badge(String txt) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.primaryRed,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      txt,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ),
  );

  Widget _actionBtn(String txt, {VoidCallback? onTap}) => SizedBox(
    height: 56,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.info_outline_rounded, color: Colors.black),
      label: Text(txt),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
  );

  Widget _favBtn(Movie movie) => GestureDetector(
    onTap: () => _toggleFavorite(movie),
    child: Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Icon(
        _isFavorite(movie)
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        color: _isFavorite(movie) ? AppTheme.primaryRed : Colors.white,
      ),
    ),
  );
}

class _HomeCategory {
  final String name;
  final int? id;
  final String emoji;

  const _HomeCategory(this.name, this.id, this.emoji);
}
