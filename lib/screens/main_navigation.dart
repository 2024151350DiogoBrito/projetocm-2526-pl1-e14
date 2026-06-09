import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/favorite_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

// navegação principal da app
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
  final NotificationService _notificationService = NotificationService();
  bool _isLoadingFavorites = true;
  int _unreadNotifications = 0;

  // carrega os dados iniciais
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // carrega os favoritos guardados
  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteService.getFavorites().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        _favoriteMovies
          ..clear()
          ..addAll(favorites);
        _isLoadingFavorites = false;
      });
      unawaited(_refreshNotifications());
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingFavorites = false);
    }
  }

  // adiciona um favorito
  Future<void> _addFavorite(Movie movie) async {
    if (_favoriteMovies.any((m) => m.sameAs(movie))) {
      return;
    }

    setState(() {
      _favoriteMovies.add(movie);
    });

    try {
      await _favoriteService.addFavorite(movie);
      await _notificationService.prepareFavorite(movie);
      await _refreshNotifications();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoriteMovies.removeWhere((m) => m.sameAs(movie));
      });
    }
  }

  // remove um favorito
  Future<void> _removeFavorite(Movie movie) async {
    final removedIndex = _favoriteMovies.indexWhere((m) => m.sameAs(movie));
    if (removedIndex == -1) {
      return;
    }

    final removedMovie = _favoriteMovies[removedIndex];

    setState(() {
      _favoriteMovies.removeWhere((m) => m.sameAs(movie));
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

  // adiciona uma pesquisa recente
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

  // limpa as pesquisas recentes
  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  // atualiza o contador de notificações
  Future<void> _refreshNotifications() async {
    try {
      await _notificationService.checkSavedItems();
      final unread = await _notificationService.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadNotifications = unread);
    } catch (_) {}
  }

  // abre o ecrã de notificações
  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    await _refreshNotifications();
  }

  // constrói a navegação principal
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        favoriteMovies: _favoriteMovies,
        onAddFavorite: _addFavorite,
        onRemoveFavorite: _removeFavorite,
        onOpenNotifications: _openNotifications,
        unreadNotifications: _unreadNotifications,
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
        onAddFavorite: _addFavorite,
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

  // constrói a barra inferior flutuante
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

  // constrói um item da barra inferior
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
