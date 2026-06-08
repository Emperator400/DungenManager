import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'auth_service.dart';
import 'resource_manifest_service.dart';
import 'resource_service.dart';

/// Synchronisiert den lokalen `resources/`-Ordner mit Firebase Storage.
///
/// Storage-Pfad: `users/{uid}/resources/{filename}`
///
/// Upload: nur geänderte Dateien (Manifest-Check → kein Re-Upload bei Neustart).
/// Download: nur lokal fehlende Dateien.
class CloudResourceService {
  static const _bucket = 'dungoenmanager.firebasestorage.app';
  static const _uploadBase =
      'https://firebasestorage.googleapis.com/v0/b/$_bucket/o';

  final AuthService _authService;

  CloudResourceService(this._authService);

  /// Synchronisiert Upload + Download für einen User.
  Future<void> syncResources(String uid) async {
    final dir = Directory(ResourceService.resourcesDir);
    if (!dir.existsSync()) return;

    final manifest = ResourceManifestService(ResourceService.resourcesDir);

    debugPrint('[CloudResourceService] Starte Sync für uid=$uid');
    await _uploadNew(dir, uid, manifest);
    await _downloadMissing(uid);
    debugPrint('[CloudResourceService] Sync abgeschlossen');
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<void> _uploadNew(
    Directory dir,
    String uid,
    ResourceManifestService manifest,
  ) async {
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final filename = p.basename(entity.path);
      if (filename.startsWith('.')) continue;

      if (!await manifest.needsUpload(filename, entity)) {
        debugPrint('[CloudResourceService] Übersprungen: $filename');
        continue;
      }

      final storagePath = 'users/$uid/resources/$filename';
      try {
        if (Platform.isWindows) {
          await _restUpload(entity, storagePath);
        } else {
          await _nativeUpload(entity, storagePath);
        }
        await manifest.markUploaded(filename, entity);
        debugPrint('[CloudResourceService] Hochgeladen: $filename');
      } catch (e) {
        debugPrint(
            '[CloudResourceService] Upload fehlgeschlagen ($filename): $e');
      }
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────

  Future<void> _downloadMissing(String uid) async {
    List<String> cloudFiles;
    try {
      cloudFiles = Platform.isWindows
          ? await _restListFiles(uid)
          : await _nativeListFiles(uid);
    } catch (e) {
      debugPrint('[CloudResourceService] Listing fehlgeschlagen: $e');
      return;
    }

    for (final filename in cloudFiles) {
      final localPath = p.join(ResourceService.resourcesDir, filename);
      if (File(localPath).existsSync()) continue;

      final storagePath = 'users/$uid/resources/$filename';
      try {
        await Directory(p.dirname(localPath)).create(recursive: true);
        if (Platform.isWindows) {
          await _restDownload(storagePath, localPath);
        } else {
          await _nativeDownload(storagePath, localPath);
        }
        debugPrint('[CloudResourceService] Heruntergeladen: $filename');
      } catch (e) {
        debugPrint(
            '[CloudResourceService] Download fehlgeschlagen ($filename): $e');
      }
    }
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
    final encoded = Uri.encodeQueryComponent(storagePath);
    final url = Uri.parse('$_uploadBase?uploadType=media&name=$encoded');
    final headers = await _authHeader();
    headers['Content-Type'] = mime;
    final response = await http.post(url, headers: headers, body: bytes);
    if (response.statusCode != 200) {
      throw Exception('Upload fehlgeschlagen (${response.statusCode})');
    }
  }

  Future<List<String>> _restListFiles(String uid) async {
    final prefix = Uri.encodeQueryComponent('users/$uid/resources/');
    final url = Uri.parse('$_uploadBase?prefix=$prefix');
    final response = await http.get(url, headers: await _authHeader());
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception('Listing fehlgeschlagen (${response.statusCode})');
    }
    final parsed = jsonDecode(response.body) as Map<String, dynamic>;
    final items = parsed['items'] as List<dynamic>? ?? [];
    return items
        .map((e) =>
            p.basename((e as Map<String, dynamic>)['name'] as String))
        .toList();
  }

  Future<void> _restDownload(String storagePath, String destPath) async {
    final encoded =
        storagePath.split('/').map(Uri.encodeComponent).join('%2F');
    final url = Uri.parse('$_uploadBase/$encoded?alt=media');
    final response = await http.get(url, headers: await _authHeader());
    if (response.statusCode != 200) {
      throw Exception('Download fehlgeschlagen (${response.statusCode})');
    }
    await File(destPath).writeAsBytes(response.bodyBytes);
  }

  // ── Native Firebase Storage (Android / iOS) ───────────────────────────────

  Future<void> _nativeUpload(File file, String storagePath) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putFile(
        file, SettableMetadata(contentType: _mimeType(storagePath)));
  }

  Future<List<String>> _nativeListFiles(String uid) async {
    final ref = FirebaseStorage.instance.ref('users/$uid/resources');
    final result = await ref.listAll();
    return result.items.map((r) => r.name).toList();
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
