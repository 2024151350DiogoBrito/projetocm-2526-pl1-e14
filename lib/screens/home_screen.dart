import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';

// ecrã principal da aplicação
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // instacia o serviço e prepara as listas
  final _service = TmdbService();
  String _selectedCategory = "ALL";
  late Future<List<Movie>> _trending, _popular, _upcoming;

  // executa as funções ao abrir o ecrã
  @override
  void initState() {
    super.initState();
    _trending = _service.getTrendingMovies();
    _popular = _service.getPopularMovies();
    _upcoming = _service.getUpcomingMovies();
  }

  // constrói a estrutura com scroll infinito
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

  // barra superior flutuante com logo
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
    actions: [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
      ),
      const SizedBox(width: 10),
    ],
  );

  // secção de grande destaque no topo
  Widget _buildHero() => Stack(
    children: [
      Image.network(
        'https://image.tmdb.org/t/p/original/8Tfys3mDZVp4tNoH2ktm06a0Tau.jpg',
        height: 550,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
      _buildHeroGradient(),
      Positioned(bottom: 40, left: 20, right: 20, child: _buildHeroContent()),
    ],
  );

  // sombreamento para leitura do texto
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

  // conteúdo e botões do destaque
  Widget _buildHeroContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _badge("CRITICS CHOICE"),
          const SizedBox(width: 10),
          const Icon(Icons.star_rounded, color: AppTheme.primaryRed, size: 16),
          const SizedBox(width: 4),
          const Text(
            "8.2",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        "PROJECT HAIL\nMARY",
        style: TextStyle(
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
          Expanded(child: _actionBtn("VIEW DETAILS")),
          const SizedBox(width: 15),
          _favBtn(),
        ],
      ),
    ],
  );

  // menu horizontal de categorias
  Widget _buildCategories() {
    final cats = [
      "ALL",
      "ACTION",
      "ADVENTURE",
      "ANIMATION",
      "COMEDY",
      "CRIME",
      "DOCUMENTARY",
      "DRAMA",
      "FAMILY",
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: cats.map((cat) {
          bool isSel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
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
                cat,
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
  }

  // organiza as diferentes filas de filmes
  Widget _buildMovieSections() => Column(
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

  // componente para o título de cada secção
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

  // constrói as listas horizontais com os dados da API
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
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) => layout == 'poster'
              ? MovieCard(movie: snapshot.data![i], onTap: () {})
              : _backdropItem(snapshot.data![i]),
        );
      },
    ),
  );

  // componente para item horizontal largo
  Widget _backdropItem(Movie m) => Container(
    width: 240,
    margin: const EdgeInsets.only(right: 15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      image: DecorationImage(
        image: NetworkImage(m.fullBackdropPath),
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
          m.title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ),
  );

  // widgets de apoio para botões e etiquetas
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
  Widget _actionBtn(String txt) => SizedBox(
    height: 56,
    child: ElevatedButton.icon(
      onPressed: () {},
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
  Widget _favBtn() => Container(
    height: 56,
    width: 56,
    decoration: BoxDecoration(
      color: const Color(0xFF1C1E26).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: const Icon(Icons.favorite_border_rounded, color: Colors.white),
  );
}
