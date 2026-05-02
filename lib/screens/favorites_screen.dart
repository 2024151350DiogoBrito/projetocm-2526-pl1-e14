import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ecrã de filmes favoritados
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // dados simulados da lista
  final List<Map<String, String>> _savedMovies = [
    {
      "title": "INTERSTELLAR",
      "year": "(2014)",
      "rating": "8.5",
      "img":
          "https://image.tmdb.org/t/p/original/yQvGrMoipbRoddT0ZR8tPoR7NfX.jpg",
    },
    {
      "title": "HACKSAW RIDGE",
      "year": "(2016)",
      "rating": "8.2",
      "img":
          "https://image.tmdb.org/t/p/original/fnOMP6mjmOmZwmlC1n0K7ivrzt1.jpg",
    },
    {
      "title": "GAME OF THRONES",
      "year": "(2011-2019)",
      "rating": "8.5",
      "img":
          "https://image.tmdb.org/t/p/original/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg",
    },
    {
      "title": "MR. ROBOT",
      "year": "(2015-2019)",
      "rating": "8.3",
      "img":
          "https://image.tmdb.org/t/p/original/kv1nRqgebSsREnd7vdC2pSGjpLo.jpg",
    },
  ];

  // constrói a interface principal
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

  // cabeçalho com título e contador
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
            "YOU HAVE ${_savedMovies.length} ITEMS SAVED",
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

  // botão para ordenar a lista
  Widget _buildFilterBtn() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF16171D),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(
      children: [
        Icon(Icons.swap_vert_rounded, color: Colors.grey, size: 20),
        SizedBox(width: 4),
        Text(
          "Recent",
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  // grelha de exibição dos filmes
  Widget _buildGrid() => Expanded(
    child: GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 15,
        mainAxisSpacing: 25,
      ),
      itemCount: _savedMovies.length,
      itemBuilder: (context, i) => _MovieGridItem(movie: _savedMovies[i]),
    ),
  );
}

// componente individual de cada filme
class _MovieGridItem extends StatelessWidget {
  final Map<String, String> movie;
  const _MovieGridItem({required this.movie});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Stack(
          children: [
            _buildPoster(),
            _buildOverlayIcon(
              top: 8,
              right: 8,
              icon: Icons.favorite_rounded,
              color: AppTheme.primaryRed,
              alpha: 0.5,
            ),
            _buildRatingBadge(),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        movie['title']!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        movie['year']!,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  // imagem do filme
  Widget _buildPoster() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      image: DecorationImage(
        image: NetworkImage(movie['img']!),
        fit: BoxFit.cover,
      ),
    ),
  );

  // ícone sobreposto na imagem
  Widget _buildOverlayIcon({
    required double top,
    required double right,
    required IconData icon,
    required Color color,
    required double alpha,
  }) => Positioned(
    top: top,
    right: right,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );

  // etiqueta com a nota do filme
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
            movie['rating']!,
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
