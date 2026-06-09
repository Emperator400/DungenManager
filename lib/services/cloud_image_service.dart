import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'auth_service.dart';
import 'resource_service.dart';

/// Lädt Bilder in Firebase Storage hoch/herunter mit anonymisierten Pfaden.
///
/// Pfad-Schema im Storage: users/{uid}/media/{entityId}_{role}.{ext}
/// Pfad-Schema in Firestore-Daten: cloud://users/{uid}/media/{entityId}_{role}.{ext}
///
/// Deduplication: `.upload_manifest.json` verhindert Re-Upload unveränderter Dateien.
/// resource://-Pfade werden unverändert durchgeleitet (handled by CloudResourceService).
///
/// Windows: Firebase Storage REST API (kein nativer SDK).
/// Android / iOS: natives firebase_storage Plugin.
class CloudImageService {
  static const _bucket = 'dungoenmanager.firebasestorage.app';
  static const _uploadBase =
      'https://firebasestorage.googleapis.com/v0/b/$_bucket/o';
  static const _scheme = 'cloud://';
  static const _manifestFilename = '.upload_manifest.json';

  final AuthService _authService;

  // Lazy-loaded manifest: key = "$uid:$absolutePath"
  Map<String, _ManifestEntry>? _manifest;

  CloudImageService(this._authService);

  // ── Öffentliche API ───────────────────────────────────────────────────────

  /// Gibt true zurück wenn [path] ein Cloud-Verweis ist (nicht lokal).
  static bool isCloudPath(String? path) =>
      path != null && path.startsWith(_scheme);

  /// Lädt ein lokales Bild hoch und gibt den anonymen Cloud-Pfad zurück.
  ///
  /// - null/leer → null
  /// - `cloud://…` → unveränderter Cloud-Pfad (bereits hochgeladen)
  /// - `resource://…` → unveränderter resource-Pfad (handled by CloudResourceService)
  /// - absoluter Pfad, unverändert seit letztem Upload → gecachter Cloud-Pfad (kein Re-Upload)
  /// - absoluter Pfad, neu/geändert → Upload → Cloud-Pfad
  Future<String?> uploadIfLocal(
    String? localPath,
    String uid,
    String entityId,
    String role,
  ) async {
    if (localPath == null || localPath.isEmpty) return null;

    // Bereits ein Cloud-Verweis → sofort zurück
    if (isCloudPath(localPath)) return localPath;

    // resource://-Pfad → wird von CloudResourceService gehandelt, unverändert durchleiten
    if (ResourceService.isResourceRef(localPath)) return localPath;

    final file = File(localPath);
    if (!file.existsSync()) return null;

    // Manifest prüfen — gleiche Datei, gleiches uid, unverändert → kein Upload
    final manifest = await _loadManifest();
    final key = '$uid:$localPath';
    final entry = manifest[key];
    if (entry != null) {
      final stat = await file.stat();
      if (entry.sizeBytes == stat.size &&
          entry.mtimeMs == stat.modified.millisecondsSinceEpoch) {
        debugPrint('[CloudImageService] Übersprungen (unverändert): $localPath');
        return entry.cloudPath;
      }
    }

    final ext = p.extension(localPath).toLowerCase();
    final sp = _storagePath(uid, entityId, role, ext);

    try {
      if (Platform.isWindows) {
        await restUpload(file, sp);
      } else {
        await nativeUpload(file, sp);
      }
      final cloudPath = '$_scheme$sp';
      await _saveEntry(key, file, cloudPath);
      debugPrint('[CloudImageService] Hochgeladen: $sp');
      return cloudPath;
    } catch (e) {
      debugPrint('[CloudImageService] Upload fehlgeschlagen ($role): $e');
      return null;
    }
  }

  /// Lädt ein Cloud-Bild herunter und gibt den lokalen Pfad zurück.
  ///
  /// - null/leer → null
  /// - `resource://…` → unveränderter resource-Pfad (lokal auflösbar)
  /// - kein Cloud-Pfad → unveränderter lokaler Pfad (Rückwärtskompatibilität)
  /// - Datei lokal schon vorhanden → lokaler Pfad ohne erneuten Download
  /// - Ansonsten → Download und Rückgabe des lokalen Pfads
  Future<String?> downloadIfCloud(String? cloudPath) async {
    if (cloudPath == null || cloudPath.isEmpty) return null;

    // resource://-Pfad ist lokal auflösbar — kein Download nötig
    if (ResourceService.isResourceRef(cloudPath)) return cloudPath;

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

  // ── Manifest ──────────────────────────────────────────────────────────────

  @protected
  @visibleForTesting
  Future<String> get manifestPath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'DungenManager', _manifestFilename);
  }

  Future<Map<String, _ManifestEntry>> _loadManifest() async {
    if (_manifest != null) return _manifest!;
    _manifest = {};
    try {
      final file = File(await manifestPath);
      if (!file.existsSync()) return _manifest!;
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final entries = raw['uploads'] as Map<String, dynamic>? ?? {};
      for (final kv in entries.entries) {
        _manifest![kv.key] =
            _ManifestEntry.fromJson(kv.value as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[CloudImageService] Manifest-Ladefehler (starte neu): $e');
      _manifest = {};
    }
    return _manifest!;
  }

  Future<void> _saveEntry(String key, File file, String cloudPath) async {
    final manifest = await _loadManifest();
    final stat = await file.stat();
    manifest[key] = _ManifestEntry(
      sizeBytes: stat.size,
      mtimeMs: stat.modified.millisecondsSinceEpoch,
      cloudPath: cloudPath,
    );
    try {
      final mPath = await manifestPath;
      await Directory(p.dirname(mPath)).create(recursive: true);
      await File(mPath).writeAsString(jsonEncode({
        'version': 1,
        'uploads': {
          for (final kv in manifest.entries) kv.key: kv.value.toJson(),
        },
      }));
    } catch (e) {
      debugPrint('[CloudImageService] Manifest-Speicherfehler: $e');
    }
  }

  // ── Pfad-Helfer ───────────────────────────────────────────────────────────

  static String _storagePath(
    String uid,
    String entityId,
    String role,
    String ext,
  ) =>
      'users/$uid/media/${entityId}_$role$ext';

  static Future<String> _localDestPath(String storagePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = storagePath.split('/').last;
    return p.join(dir.path, 'DungenManager', 'images', filename);
  }

  // ── Windows REST API ──────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeader() async {
    final token = await _authService.getIdToken();
    if (token == null) throw Exception('Nicht angemeldet');
    return {'Authorization': 'Bearer $token'};
  }

  @protected
  @visibleForTesting
  Future<void> restUpload(File file, String storagePath) async {
    final bytes = await file.readAsBytes();
    final mime = _mimeType(storagePath);
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

  @protected
  @visibleForTesting
  Future<void> nativeUpload(File file, String storagePath) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putFile(
        file, SettableMetadata(contentType: _mimeType(storagePath)));
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

class _ManifestEntry {
  final int sizeBytes;
  final int mtimeMs;
  final String cloudPath;

  const _ManifestEntry({
    required this.sizeBytes,
    required this.mtimeMs,
    required this.cloudPath,
  });

  Map<String, dynamic> toJson() => {
        'sizeBytes': sizeBytes,
        'mtimeMs': mtimeMs,
        'cloudPath': cloudPath,
      };

  factory _ManifestEntry.fromJson(Map<String, dynamic> j) => _ManifestEntry(
        sizeBytes: j['sizeBytes'] as int,
        mtimeMs: j['mtimeMs'] as int,
        cloudPath: j['cloudPath'] as String,
      );
}
