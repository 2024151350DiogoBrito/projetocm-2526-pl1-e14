import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;

  final List<Movie> _favoriteMovies = [];
  final List<String> _recentSearches = [];
  final FavoriteService _favoriteService = FavoriteService();
  bool _isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteService.getFavorites();

      if (!mounted) return;

      setState(() {
        _favoriteMovies
          ..clear()
          ..addAll(favorites);
        _isLoadingFavorites = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _addFavorite(Movie movie) async {
    if (_favoriteMovies.any((m) => m.id == movie.id)) {
      return;
    }

    setState(() {
      _favoriteMovies.add(movie);
    });

    try {
      await _favoriteService.addFavorite(movie);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoriteMovies.removeWhere((m) => m.id == movie.id);
      });
    }
  }

  Future<void> _removeFavorite(Movie movie) async {
    final removedIndex = _favoriteMovies.indexWhere((m) => m.id == movie.id);
    if (removedIndex == -1) {
      return;
    }

    final removedMovie = _favoriteMovies[removedIndex];

    setState(() {
      _favoriteMovies.removeWhere((m) => m.id == movie.id);
    });

    try {
      await _favoriteService.removeFavorite(movie);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoriteMovies.insert(removedIndex, removedMovie);
      });
    }
  }

  void _addRecentSearch(String text) {
    setState(() {
      final query = text.trim();

      if (query.isEmpty) {
        return;
      }

      _recentSearches.remove(query);
      _recentSearches.insert(0, query);

      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        favoriteMovies: _favoriteMovies,
        onAddFavorite: _addFavorite,
        onRemoveFavorite: _removeFavorite,
      ),
      SearchScreen(
        favoriteMovies: _favoriteMovies,
        recentSearches: _recentSearches,
        onAddFavorite: _addFavorite,
        onRemoveFavorite: _removeFavorite,
        onAddRecentSearch: _addRecentSearch,
        onClearRecentSearches: _clearRecentSearches,
      ),
      FavoritesScreen(
        favoriteMovies: _favoriteMovies,
        onRemoveFavorite: _removeFavorite,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: _isLoadingFavorites
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          : screens[_idx],
      bottomNavigationBar: _buildFloatingBar(),
    );
  }

  Widget _buildFloatingBar() => Container(
    height: 90,
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E26).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: BottomNavigationBar(
            currentIndex: _idx,
            onTap: (i) => setState(() => _idx = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryRed,
            unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
            selectedFontSize: 8,
            unselectedFontSize: 8,
            items: [
              _navItem(Icons.home_rounded, "HOME", 0),
              _navItem(Icons.search_rounded, "SEARCH", 1),
              _navItem(Icons.favorite_rounded, "SAVED", 2),
              _navItem(Icons.person_rounded, "PROFILE", 3),
            ],
          ),
        ),
      ),
    ),
  );

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) =>
      BottomNavigationBarItem(
        label: label,
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.only(bottom: 4),
          child: Icon(icon, size: _idx == index ? 28 : 22),
        ),
      );
}
