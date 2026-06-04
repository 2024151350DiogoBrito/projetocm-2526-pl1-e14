import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/movie.dart';
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

  void _addFavorite(Movie movie) {
    setState(() {
      if (!_favoriteMovies.any((m) => m.id == movie.id)) {
        _favoriteMovies.add(movie);
      }
    });
  }

  void _removeFavorite(Movie movie) {
    setState(() {
      _favoriteMovies.removeWhere((m) => m.id == movie.id);
    });
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      SearchScreen(
        favoriteMovies: _favoriteMovies,
        recentSearches: _recentSearches,
        onAddFavorite: _addFavorite,
        onAddRecentSearch: _addRecentSearch,
      ),
      FavoritesScreen(
        favoriteMovies: _favoriteMovies,
        onRemoveFavorite: _removeFavorite,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: screens[_idx],
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