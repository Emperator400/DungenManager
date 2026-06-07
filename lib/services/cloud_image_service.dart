import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'auth_service.dart';

/// Lädt Bilder in Firebase Storage hoch/herunter mit anonymisierten Pfaden.
///
/// Pfad-Schema im Storage: users/{uid}/media/{entityId}_{role}.{ext}
/// Pfad-Schema in Firestore-Daten: cloud://users/{uid}/media/{entityId}_{role}.{ext}
///
/// Windows: Firebase Storage REST API (kein nativer SDK).
/// Android / iOS: natives firebase_storage Plugin.
class CloudImageService {
  static const _bucket = 'dungoenmanager.firebasestorage.app';
  static const _uploadBase =
      'https://firebasestorage.googleapis.com/v0/b/$_bucket/o';
  static const _scheme = 'cloud://';

  final AuthService _authService;

  CloudImageService(this._authService);

  // ── Öffentliche API ───────────────────────────────────────────────────────

  /// Gibt true zurück wenn [path] ein Cloud-Verweis ist (nicht lokal).
  static bool isCloudPath(String? path) =>
      path != null && path.startsWith(_scheme);

  /// Lädt ein lokales Bild hoch und gibt den anonymen Cloud-Pfad zurück.
  ///
  /// - Ist [localPath] null/leer/nicht vorhanden → null zurück
  /// - Ist [localPath] bereits ein Cloud-Pfad → unveränderter Cloud-Pfad
  /// - Ansonsten → Upload und Rückgabe von `cloud://...`
  ///
  /// [entityId] ist die ID der Kampagne oder des Ortes (UUID).
  /// [role] beschreibt den Zweck (z.B. 'cover', 'karte', 'map', 'token').
  Future<String?> uploadIfLocal(
    String? localPath,
    String uid,
    String entityId,
    String role,
  ) async {
    if (localPath == null || localPath.isEmpty) return null;
    if (isCloudPath(localPath)) return localPath;

    final file = File(localPath);
    if (!file.existsSync()) return null;

    final ext = p.extension(localPath).toLowerCase();
    final sp = _storagePath(uid, entityId, role, ext);

    try {
      if (Platform.isWindows) {
        await _restUpload(file, sp);
      } else {
        await _nativeUpload(file, sp);
      }
      debugPrint('[CloudImageService] Hochgeladen: $sp');
      return '$_scheme$sp';
    } catch (e) {
      debugPrint('[CloudImageService] Upload fehlgeschlagen ($role): $e');
      return null;
    }
  }

  /// Lädt ein Cloud-Bild herunter und gibt den lokalen Pfad zurück.
  ///
  /// - Ist [cloudPath] null/leer → null zurück
  /// - Ist [cloudPath] kein Cloud-Pfad → unveränderter lokaler Pfad
  /// - Datei lokal schon vorhanden → lokaler Pfad ohne erneuten Download
  /// - Ansonsten → Download und Rückgabe des lokalen Pfads
  Future<String?> downloadIfCloud(String? cloudPath) async {
    if (cloudPath == null || cloudPath.isEmpty) return null;
    if (!isCloudPath(cloudPath)) return cloudPath;

    final sp = cloudPath.replaceFirst(_scheme, '');
    final dest = await _localDestPath(sp);
    final destFile = File(dest);

    if (destFile.existsSync()) return dest;

    try {
      await Directory(p.dirname(dest)).create(recursive: true);
      if (Platform.isWindows) {
        await _restDownload(sp, dest);
      } else {
        await _nativeDownload(sp, dest);
      }
      debugPrint('[CloudImageService] Heruntergeladen: $dest');
      return dest;
    } catch (e) {
      debugPrint('[CloudImageService] Download fehlgeschlagen: $e');
      return null;
    }
  }

  // ── Pfad-Helfer ───────────────────────────────────────────────────────────

  /// Anonymisierter Storage-Pfad: keine Original-Dateinamen, nur Entity-ID + Rolle.
  static String _storagePath(
    String uid,
    String entityId,
    String role,
    String ext,
  ) =>
      'users/$uid/media/${entityId}_$role$ext';

  /// Lokaler Ziel-Pfad für heruntergeladene Bilder.
  static Future<String> _localDestPath(String storagePath) async {
    final dir = await getApplicationDocumentsDirectory();
    // Aus dem Storage-Pfad nur den Dateinamen verwenden (letztes Segment).
    final filename = storagePath.split('/').last;
    return p.join(dir.path, 'DungenManager', 'images', filename);
  }

  // ── Windows REST API ──────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeader() async {
    final token = await _authService.getIdToken();
    if (token == null) throw Exception('Nicht angemeldet');
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _restUpload(File file, String storagePath) async {
    final bytes = await file.readAsBytes();
    final mime = _mimeType(storagePath);

    // Firebase Storage einfacher Media-Upload
    final encodedName = Uri.encodeQueryComponent(storagePath);
    final url = Uri.parse('$_uploadBase?uploadType=media&name=$encodedName');

    final headers = await _authHeader();
    headers['Content-Type'] = mime;

    final response = await http.post(url, headers: headers, body: bytes);
    if (response.statusCode != 200) {
      throw Exception(
        'Storage-Upload fehlgeschlagen (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<void> _restDownload(String storagePath, String destPath) async {
    // Slashes im Objektnamen müssen als %2F kodiert werden
    final encodedPath =
        storagePath.split('/').map(Uri.encodeComponent).join('%2F');
    final url = Uri.parse('$_uploadBase/$encodedPath?alt=media');

    final headers = await _authHeader();
    final response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
        'Storage-Download fehlgeschlagen (${response.statusCode})',
      );
    }
    await File(destPath).writeAsBytes(response.bodyBytes);
  }

  // ── Native Firebase Storage (Android / iOS) ───────────────────────────────

  Future<void> _nativeUpload(File file, String storagePath) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putFile(file, SettableMetadata(contentType: _mimeType(storagePath)));
  }

  Future<void> _nativeDownload(String storagePath, String destPath) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.writeToFile(File(destPath));
  }

  // ── Helfer ────────────────────────────────────────────────────────────────

  static String _mimeType(String filePath) {
    switch (p.extension(filePath).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}
