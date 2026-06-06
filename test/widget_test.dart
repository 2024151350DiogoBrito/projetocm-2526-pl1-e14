import 'package:flutter_test/flutter_test.dart';
import 'package:movienest/models/movie.dart';

void main() {
  test('Movie converts to and from Firestore map', () {
    final movie = Movie(
      id: 1,
      title: 'MovieNest Test',
      posterPath: '/poster.jpg',
      backdropPath: '/backdrop.jpg',
      voteAverage: 8.5,
      releaseDate: '2026-06-06',
      overview: 'Teste de favoritos.',
      genreIds: [28, 12],
    );

    final restoredMovie = Movie.fromMap(movie.toMap());

    expect(restoredMovie.id, movie.id);
    expect(restoredMovie.title, movie.title);
    expect(restoredMovie.posterPath, movie.posterPath);
    expect(restoredMovie.backdropPath, movie.backdropPath);
    expect(restoredMovie.voteAverage, movie.voteAverage);
    expect(restoredMovie.releaseDate, movie.releaseDate);
    expect(restoredMovie.overview, movie.overview);
    expect(restoredMovie.genreIds, movie.genreIds);
  });
}
