import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('favorites');

  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Tens de iniciar sessão para gerir favoritos.');
    }
    return uid;
  }

  Future<List<Movie>> getFavorites() async {
    final snapshot = await _favoritesRef(
      _currentUid,
    ).orderBy('addedAt', descending: false).get();

    return snapshot.docs.map((doc) => Movie.fromMap(doc.data())).toList();
  }

  Future<void> addFavorite(Movie movie) async {
    await _favoritesRef(_currentUid).doc(movie.favoriteKey).set({
      ...movie.toMap(),
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(Movie movie) async {
    await _favoritesRef(_currentUid).doc(movie.favoriteKey).delete();
  }
}
