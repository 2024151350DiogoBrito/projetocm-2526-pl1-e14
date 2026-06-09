import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // referência dos favoritos do utilizador
  CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('favorites');

  // vai buscar o id do utilizador atual
  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Tens de iniciar sessão para gerir favoritos.');
    }
    return uid;
  }

  // vai buscar os favoritos guardados
  Future<List<Movie>> getFavorites() async {
    final snapshot = await _favoritesRef(
      _currentUid,
    ).orderBy('addedAt', descending: false).get();

    return snapshot.docs.map((doc) => Movie.fromMap(doc.data())).toList();
  }

  // adiciona um filme aos favoritos
  Future<void> addFavorite(Movie movie) async {
    await _favoritesRef(_currentUid).doc(movie.favoriteKey).set({
      ...movie.toMap(),
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // remove um filme dos favoritos
  Future<void> removeFavorite(Movie movie) async {
    await _favoritesRef(_currentUid).doc(movie.favoriteKey).delete();
  }
}
