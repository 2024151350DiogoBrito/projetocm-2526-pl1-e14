import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

// controla a navegação principal entre ecrãs
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // índice do ecrã selecionado
  int _idx = 0;

  // lista dos ecrãs da aplicação
  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  // constrói a estrutura com a barra inferior
  @override
  Widget build(BuildContext context) => Scaffold(
    // conteúdo passa por trás da barra
    extendBody: true,
    body: _screens[_idx],
    bottomNavigationBar: _buildFloatingBar(),
  );

  // cria a barra de navegação flutuante
  Widget _buildFloatingBar() => Container(
    height: 90,
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        // efeito de vidro fosco
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E26).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: BottomNavigationBar(
            currentIndex: _idx,
            // muda o estado ao clicar no ícone
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

  // gera cada item da barra com animação
  BottomNavigationBarItem _navItem(IconData icon, String label, int index) =>
      BottomNavigationBarItem(
        label: label,
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.only(bottom: 4),
          // aumenta o tamanho se estiver selecionado
          child: Icon(icon, size: _idx == index ? 28 : 22),
        ),
      );
}
