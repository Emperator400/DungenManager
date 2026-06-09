import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

// Windows uses Firebase Auth REST API (no native SDK needed).
const _kWindowsApiKey = 'AIzaSyDJcbJjnRSSDKBX7fhw9Krj4q6M2jY1qN0';

// SharedPreferences keys for Windows session persistence.
const _kPrefRefreshToken = 'win_auth_refresh_token';
const _kPrefUid = 'win_auth_uid';
const _kPrefEmail = 'win_auth_email';
const _kPrefDisplayName = 'win_auth_display_name';

class AuthService {
  // Windows in-memory session state (populated at login or restored from prefs).
  static final _windowsAuthController = StreamController<AppUser?>.broadcast();
  static AppUser? _windowsUser;
  static String? _windowsIdToken;
  static String? _windowsRefreshToken;
  static DateTime? _windowsTokenExpiry;

  Stream<AppUser?> get authStateChanges {
    if (Platform.isWindows) return _windowsAuthController.stream;
    return FirebaseAuth.instance.authStateChanges().map(_mapFirebaseUser);
  }

  AppUser? get currentUser {
    if (Platform.isWindows) return _windowsUser;
    return _mapFirebaseUser(FirebaseAuth.instance.currentUser);
  }

  /// Returns the current Firebase ID token for API calls.
  /// On Windows: auto-refreshes when the token is expired or expires within 5 minutes.
  Future<String?> getIdToken() async {
    if (Platform.isWindows) {
      final expiry = _windowsTokenExpiry;
      if (_windowsIdToken != null &&
          expiry != null &&
          DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)))) {
        await _refreshWindowsToken();
      }
      return _windowsIdToken;
    }
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<void> _refreshWindowsToken() async {
    final refreshToken = _windowsRefreshToken;
    if (refreshToken == null) return;
    try {
      final uri = Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$_kWindowsApiKey',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'grant_type': 'refresh_token', 'refresh_token': refreshToken}),
      );
      if (response.statusCode != 200) {
        debugPrint('[AuthService] Token-Refresh fehlgeschlagen: ${response.statusCode}');
        return;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _windowsIdToken = body['id_token'] as String?;
      _windowsRefreshToken = body['refresh_token'] as String? ?? refreshToken;
      final expiresIn = int.tryParse(body['expires_in'] as String? ?? '3600') ?? 3600;
      _windowsTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefRefreshToken, _windowsRefreshToken!);
      debugPrint('[AuthService] Token automatisch erneuert.');
    } catch (e) {
      debugPrint('[AuthService] Token-Refresh Fehler: $e');
    }
  }

  // ── Session Persistence (Windows) ─────────────────────────────────────────

  /// Call once in main() before runApp() on Windows.
  /// Uses the stored refresh token to obtain a fresh idToken and restore the session.
  static Future<void> restoreSession() async {
    if (!Platform.isWindows) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_kPrefRefreshToken);
      if (refreshToken == null) return;

      // Exchange refresh token for a new id token.
      final uri = Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$_kWindowsApiKey',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode != 200) {
        // Token revoked or expired — clear stored session.
        await _clearPrefs(prefs);
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final newIdToken = body['id_token'] as String?;
      final newRefreshToken = body['refresh_token'] as String?;
      if (newIdToken == null) return;

      // Persist updated refresh token.
      if (newRefreshToken != null) {
        await prefs.setString(_kPrefRefreshToken, newRefreshToken);
        _windowsRefreshToken = newRefreshToken;
      }

      final expiresIn = int.tryParse(body['expires_in'] as String? ?? '3600') ?? 3600;
      _windowsTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      // Restore in-memory state (AuthViewModel reads currentUser in its constructor).
      _windowsIdToken = newIdToken;
      _windowsUser = AppUser(
        uid: prefs.getString(_kPrefUid) ?? (body['user_id'] as String? ?? ''),
        email: prefs.getString(_kPrefEmail),
        displayName: prefs.getString(_kPrefDisplayName),
      );
      debugPrint('[AuthService] Session wiederhergestellt: ${_windowsUser?.email}');
    } catch (e) {
      debugPrint('[AuthService] Session-Restore fehlgeschlagen: $e');
    }
  }

  static Future<void> _clearPrefs(SharedPreferences prefs) async {
    await prefs.remove(_kPrefRefreshToken);
    await prefs.remove(_kPrefUid);
    await prefs.remove(_kPrefEmail);
    await prefs.remove(_kPrefDisplayName);
  }

  Future<void> _persistSession(AppUser user, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefRefreshToken, refreshToken);
    await prefs.setString(_kPrefUid, user.uid);
    if (user.email != null) await prefs.setString(_kPrefEmail, user.email!);
    if (user.displayName != null) {
      await prefs.setString(_kPrefDisplayName, user.displayName!);
    }
  }

  // ── Public Auth API ───────────────────────────────────────────────────────

  Future<AppUser> signInWithEmail(String email, String password) async {
    if (Platform.isWindows) return _windowsSignIn(email, password);
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _mapFirebaseUser(result.user)!;
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (Platform.isWindows) {
      return _windowsRegister(email, password, displayName);
    }
    final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user?.updateDisplayName(displayName.trim());
    return _mapFirebaseUser(result.user)!;
  }

  Future<void> signOut() async {
    if (Platform.isWindows) {
      _windowsUser = null;
      _windowsIdToken = null;
      _windowsRefreshToken = null;
      _windowsTokenExpiry = null;
      _windowsAuthController.add(null);
      final prefs = await SharedPreferences.getInstance();
      await _clearPrefs(prefs);
      return;
    }
    await FirebaseAuth.instance.signOut();
  }

  // ── Windows REST API ──────────────────────────────────────────────────────

  Future<AppUser> _windowsSignIn(String email, String password) async {
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_kWindowsApiKey',
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) throw _parseFirebaseError(body);

    final user = AppUser(
      uid: body['localId'] as String,
      email: body['email'] as String?,
      displayName: body['displayName'] as String?,
    );
    _windowsUser = user;
    _windowsIdToken = body['idToken'] as String?;
    _windowsRefreshToken = body['refreshToken'] as String?;
    final expiresIn = int.tryParse(body['expiresIn'] as String? ?? '3600') ?? 3600;
    _windowsTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    _windowsAuthController.add(user);
    await _persistSession(user, body['refreshToken'] as String? ?? '');
    return user;
  }

  Future<AppUser> _windowsRegister(
    String email,
    String password,
    String displayName,
  ) async {
    // Step 1: create account
    final signUpUri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_kWindowsApiKey',
    );
    final signUpRes = await http.post(
      signUpUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final signUpBody = jsonDecode(signUpRes.body) as Map<String, dynamic>;
    if (signUpRes.statusCode != 200) throw _parseFirebaseError(signUpBody);
    final idToken = signUpBody['idToken'] as String;

    // Step 2: set display name
    final updateUri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$_kWindowsApiKey',
    );
    await http.post(
      updateUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'displayName': displayName.trim(),
        'returnSecureToken': false,
      }),
    );

    final user = AppUser(
      uid: signUpBody['localId'] as String,
      email: signUpBody['email'] as String?,
      displayName: displayName.trim(),
    );
    _windowsUser = user;
    _windowsIdToken = idToken;
    _windowsRefreshToken = signUpBody['refreshToken'] as String?;
    final expiresIn = int.tryParse(signUpBody['expiresIn'] as String? ?? '3600') ?? 3600;
    _windowsTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    _windowsAuthController.add(user);
    await _persistSession(user, signUpBody['refreshToken'] as String? ?? '');
    return user;
  }

  Exception _parseFirebaseError(Map<String, dynamic> body) {
    final error = body['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String? ?? 'Unbekannter Fehler';
    return switch (message) {
      'EMAIL_NOT_FOUND' || 'INVALID_EMAIL' => Exception('E-Mail-Adresse ungültig oder nicht gefunden.'),
      'INVALID_PASSWORD' || 'INVALID_LOGIN_CREDENTIALS' => Exception('Falsches Passwort.'),
      'USER_DISABLED' => Exception('Dieser Account wurde gesperrt.'),
      'EMAIL_EXISTS' => Exception('Diese E-Mail-Adresse ist bereits registriert.'),
      'WEAK_PASSWORD : Password should be at least 6 characters' => Exception('Passwort muss mindestens 6 Zeichen haben.'),
      _ => Exception('Anmeldefehler: $message'),
    };
  }

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      avatarUrl: user.photoURL,
    );
  }
}
