import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ecrã de pesquisa
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // dados simulados para a interface
  final List<String> _recent = ["Interstellar", "The Batman", "The Odyssey"];
  final List<String> _trending = [
    "Apex",
    "The Boys",
    "Michael",
    "FROM",
    "Euphoria",
  ];

  // lista de géneros com imagens da API
  final List<Map<String, String>> _genres = [
    {
      "name": "ACTION",
      "img":
          "https://image.tmdb.org/t/p/original/7dzngS8pLkGJpyeskCFcjPO9qLF.jpg",
    },
    {
      "name": "ADVENTURE",
      "img":
          "https://image.tmdb.org/t/p/original/57JocxmicOoAMhkUSmdKBlpZWMT.jpg",
    },
    {
      "name": "ANIMATION",
      "img":
          "https://image.tmdb.org/t/p/original/8mnXR9rey5uQ08rZAvzojKWbDQS.jpg",
    },
    {
      "name": "COMEDY",
      "img":
          "https://image.tmdb.org/t/p/original/mLyW3UTgi2lsMdtueYODcfAB9Ku.jpg",
    },
    {
      "name": "CRIME",
      "img":
          "https://image.tmdb.org/t/p/original/tSPT36ZKlP2WVHJLM4cQPLSzv3b.jpg",
    },
    {
      "name": "DOCUMENTARY",
      "img":
          "https://image.tmdb.org/t/p/original/m6bIek9WBacbpx6flktKHMSaUqX.jpg",
    },
    {
      "name": "DRAMA",
      "img":
          "https://image.tmdb.org/t/p/original/neeNHeXjMF5fXoCJRsOmkNGC7q.jpg",
    },
    {
      "name": "FAMILY",
      "img":
          "https://image.tmdb.org/t/p/original/3Rfvhy1Nl6sSGJwyjb0QiZzZYlB.jpg",
    },
  ];

  // constrói a interface principal
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
          const SizedBox(height: 20),
          _buildRecent(),
          const SizedBox(height: 35),
          _buildTrending(),
          const SizedBox(height: 40),
          _buildGenreGrid(),
          const SizedBox(height: 120),
        ],
      ),
    ),
  );

  // barra de pesquisa
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
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.grey, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Movies, series, actors...",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 15),
      _filterBtn(),
    ],
  );

  // botão de filtros
  Widget _filterBtn() => Container(
    height: 55,
    width: 55,
    decoration: BoxDecoration(
      color: const Color(0xFF16171D),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    ),
    child: const Icon(Icons.tune_rounded, color: Colors.white),
  );

  // lista horizontal de pesquisas recentes
  Widget _buildRecent() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: _recent.map((s) => _recentChip(s)).toList()),
  );

  // etiqueta individual de pesquisa recente
  Widget _recentChip(String txt) => Container(
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
        Text(txt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );

  // secção de pesquisas populares
  Widget _buildTrending() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.trending_up_rounded, color: AppTheme.primaryRed, size: 20),
          SizedBox(width: 10),
          Text(
            "TRENDING SEARCHES",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      // gera a lista numerada
      for (int i = 0; i < _trending.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            children: [
              Text(
                "0${i + 1}",
                style: const TextStyle(
                  color: Color(0xFF1C1E26),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                _trending[i],
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
    ],
  );

  // grelha de géneros
  Widget _buildGenreGrid() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "EXPLORE GENRES",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 20),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _genres.length,
        itemBuilder: (_, i) => _genreCard(_genres[i]),
      ),
    ],
  );

  // cartão individual de género com imagem de fundo
  Widget _genreCard(Map<String, String> g) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      image: DecorationImage(
        image: NetworkImage(g['img']!),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.6),
          BlendMode.darken,
        ),
      ),
    ),
    child: Center(
      child: Text(
        g['name']!,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}
