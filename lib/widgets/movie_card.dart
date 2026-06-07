import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

// componente do cartão de filme
class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  // desenha o widget do cartão
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 150,
        decoration: _cardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              _buildPoster(),
              _buildGradientOverlay(),
              _RatingBadge(rating: movie.voteAverage),
            ],
          ),
        ),
      ),
    ),
  );

  // decoração com sombra e bordas
  BoxDecoration _cardDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // carregamento da imagem da API
  Widget _buildPoster() => Image.network(
    movie.fullPosterPath,
    fit: BoxFit.cover,
    height: double.infinity,
    width: double.infinity,
    loadingBuilder: (context, child, loadingProgress) => loadingProgress == null
        ? child
        : const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryRed,
            ),
          ),
    errorBuilder: (_, _, _) =>
        const Icon(Icons.broken_image, color: Colors.grey),
  );

  // gradiente para facilitar leitura
  Widget _buildGradientOverlay() => Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          stops: const [0.0, 0.5],
        ),
      ),
    ),
  );
}

// widget para a nota do filme
class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) => Positioned(
    top: 10,
    right: 10,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppTheme.primaryRed, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
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
