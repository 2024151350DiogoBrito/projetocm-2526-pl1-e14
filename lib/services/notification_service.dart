import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification.dart';
import '../models/movie.dart';
import 'tmdb_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TmdbService _tmdb = TmdbService();

  // vai buscar o id do utilizador atual
  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Tens de iniciar sessão para ver notificações.');
    }
    return uid;
  }

  // referência das notificações do utilizador
  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  // referência dos favoritos do utilizador
  CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('favorites');

  // vai buscar as notificações guardadas
  Future<List<AppNotification>> getNotifications() async {
    final snapshot = await _notificationsRef(
      _currentUid,
    ).orderBy('createdAt', descending: true).limit(50).get();

    return snapshot.docs.map(AppNotification.fromDoc).toList();
  }

  // conta notificações por ler
  Future<int> getUnreadCount() async {
    final snapshot = await _notificationsRef(
      _currentUid,
    ).where('read', isEqualTo: false).get();
    return snapshot.docs.length;
  }

  // marca todas as notificações como lidas
  Future<void> markAllAsRead() async {
    final snapshot = await _notificationsRef(
      _currentUid,
    ).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  // cria uma notificação de demonstração
  AppNotification createDemoNotification() {
    final uid = _currentUid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final isRelease = timestamp.isEven;
    final notification = AppNotification(
      id: 'demo_$timestamp',
      type: isRelease ? 'release' : 'season',
      title: isRelease
          ? 'Demonstração: filme estreou'
          : 'Demonstração: nova temporada',
      message: isRelease
          ? 'Exemplo de aviso quando um filme guardado nos Saved estreia.'
          : 'Exemplo de aviso quando uma série guardada ganha nova temporada.',
      read: false,
      createdAt: DateTime.now(),
    );

    unawaited(
      _createNotification(
        uid: uid,
        key: notification.id,
        type: notification.type,
        title: notification.title,
        message: notification.message,
      ).catchError((_) {}),
    );

    return notification;
  }

  // limpa todas as notificações
  Future<void> clearNotifications() async {
    final snapshot = await _notificationsRef(_currentUid).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // prepara um favorito para receber avisos
  Future<void> prepareFavorite(Movie movie) async {
    final today = DateTime.now();
    final releaseDate = _parseDate(movie.releaseDate);
    final data = <String, Object?>{
      'releaseNotified': releaseDate == null || !releaseDate.isAfter(today),
    };

    if (movie.mediaType == 'tv') {
      try {
        final detail = await _tmdb.getMovieDetails(movie.id, mediaType: 'tv');
        data['knownSeasonCount'] = detail.numberOfSeasons;
      } catch (_) {
        data['knownSeasonCount'] = 0;
      }
    }

    await _favoritesRef(
      _currentUid,
    ).doc(movie.favoriteKey).set(data, SetOptions(merge: true));
  }

  // verifica novidades nos favoritos guardados
  Future<void> checkSavedItems() async {
    final uid = _currentUid;
    final favorites = await _favoritesRef(uid).get();

    for (final doc in favorites.docs) {
      final data = doc.data();
      final movie = Movie.fromMap(data);

      if (movie.mediaType == 'tv') {
        await _checkSeriesSeason(uid, doc.reference, movie, data);
      } else {
        await _checkMovieRelease(uid, doc.reference, movie, data);
      }
    }
  }

  // verifica se um filme guardado já estreou
  Future<void> _checkMovieRelease(
    String uid,
    DocumentReference<Map<String, dynamic>> favoriteRef,
    Movie movie,
    Map<String, dynamic> data,
  ) async {
    if (data['releaseNotified'] == true) return;

    final releaseDate = _parseDate(movie.releaseDate);
    if (releaseDate == null || releaseDate.isAfter(DateTime.now())) return;

    await _createNotification(
      uid: uid,
      key: 'release_${movie.favoriteKey}',
      type: 'release',
      title: '${movie.title} já estreou',
      message: 'Um título que tinhas guardado nos Saved já está disponível.',
    );
    await favoriteRef.set({'releaseNotified': true}, SetOptions(merge: true));
  }

  // verifica se uma série ganhou nova temporada
  Future<void> _checkSeriesSeason(
    String uid,
    DocumentReference<Map<String, dynamic>> favoriteRef,
    Movie series,
    Map<String, dynamic> data,
  ) async {
    final detail = await _tmdb.getMovieDetails(series.id, mediaType: 'tv');
    final currentSeasonCount = detail.numberOfSeasons;
    final knownSeasonCount = data['knownSeasonCount'] as int?;

    if (currentSeasonCount <= 0) return;

    if (knownSeasonCount == null) {
      await favoriteRef.set({
        'knownSeasonCount': currentSeasonCount,
      }, SetOptions(merge: true));
      return;
    }

    if (currentSeasonCount <= knownSeasonCount) return;

    await _createNotification(
      uid: uid,
      key: 'season_${series.favoriteKey}_$currentSeasonCount',
      type: 'season',
      title: 'Nova temporada de ${series.title}',
      message:
          'Foi detetada a temporada $currentSeasonCount numa série guardada.',
    );
    await favoriteRef.set({
      'knownSeasonCount': currentSeasonCount,
    }, SetOptions(merge: true));
  }

  // guarda uma notificação no firestore
  Future<void> _createNotification({
    required String uid,
    required String key,
    required String type,
    required String title,
    required String message,
  }) async {
    await _notificationsRef(uid).doc(key).set({
      'type': type,
      'title': title,
      'message': message,
      'read': false,
      'createdAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // converte texto em data
  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
