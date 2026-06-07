import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServiceException implements Exception {
  final String message;

  AuthServiceException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_messageForAuthError(e));
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return;

      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_messageForAuthError(e));
    }
  }

  Future<void> updateProfile({
    required String name,
    String? photoBase64,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthServiceException('Tens de iniciar sessão primeiro.');
    }

    try {
      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      final profileData = <String, Object?>{
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (photoBase64 != null) {
        profileData['photoBase64'] = photoBase64;
      }

      unawaited(
        _firestore
            .collection('users')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true))
            .catchError((Object _) {}),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_messageForAuthError(e));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      throw AuthServiceException('Tens de iniciar sessão primeiro.');
    }

    if (newPassword.length < 6) {
      throw AuthServiceException(
        'A nova palavra-passe deve ter pelo menos 6 caracteres.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(_messageForAuthError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'O email introduzido não é válido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou palavra-passe incorretos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este email.';
      case 'weak-password':
        return 'A palavra-passe deve ter pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Foram feitas demasiadas tentativas. Tenta novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem ligação à internet. Verifica a tua rede.';
      case 'requires-recent-login':
        return 'Por segurança, volta a iniciar sessão antes de alterar a password.';
      default:
        return 'Não foi possível concluir a autenticação.';
    }
  }
}
