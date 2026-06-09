import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<AppUser?>? _authSub;

  AuthViewModel({required AuthService authService})
      : _authService = authService {
    // Lese sofort den aktuellen User (z.B. nach restoreSession() in main()).
    _user = _authService.currentUser;
    _authSub = _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
    } on UnsupportedError catch (e) {
      _error = e.message ?? 'Nicht verfügbar auf dieser Plattform.';
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: name,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e);
      notifyListeners();
      return false;
    } on UnsupportedError catch (e) {
      _error = e.message ?? 'Nicht verfügbar auf dieser Plattform.';
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Kein Account mit dieser E-Mail gefunden.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-Mail oder Passwort falsch.';
      case 'email-already-in-use':
        return 'Diese E-Mail wird bereits verwendet.';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse.';
      case 'weak-password':
        return 'Passwort zu schwach — mindestens 6 Zeichen.';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte kurz warten.';
      default:
        return e.message ?? 'Unbekannter Fehler.';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
