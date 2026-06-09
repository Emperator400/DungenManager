import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Verfolgt welche Dateien bereits in die Cloud hochgeladen wurden.
///
/// Gespeichert als `.manifest.json` im Ressourcen-Ordner (lokal, nicht synced).
/// Vergleicht mtime + Dateigröße — kein SHA-256-Hash nötig (schneller).
class ResourceManifestService {
  static const _manifestFilename = '.manifest.json';

  final String _resourcesDir;
  final Map<String, _Entry> _entries = {};
  bool _loaded = false;

  ResourceManifestService(this._resourcesDir);

  String get _manifestPath => p.join(_resourcesDir, _manifestFilename);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final file = File(_manifestPath);
    if (!file.existsSync()) return;
    try {
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final files = raw['files'] as Map<String, dynamic>? ?? {};
      for (final kv in files.entries) {
        _entries[kv.key] = _Entry.fromJson(kv.value as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[Manifest] Corrupt manifest, starte neu: $e');
    }
  }

  Future<void> _save() async {
    final data = {
      'version': 1,
      'files': {
        for (final kv in _entries.entries) kv.key: kv.value.toJson(),
      },
    };
    await File(_manifestPath).writeAsString(jsonEncode(data));
  }

  /// Gibt true zurück wenn die Datei hochgeladen werden muss (neu oder geändert).
  Future<bool> needsUpload(String filename, File file) async {
    await _ensureLoaded();
    final entry = _entries[filename];
    if (entry == null) return true;
    final stat = await file.stat();
    return entry.sizeBytes != stat.size ||
        entry.mtimeMs != stat.modified.millisecondsSinceEpoch;
  }

  /// Markiert eine Datei als erfolgreich hochgeladen.
  Future<void> markUploaded(String filename, File file) async {
    await _ensureLoaded();
    final stat = await file.stat();
    _entries[filename] = _Entry(
      sizeBytes: stat.size,
      mtimeMs: stat.modified.millisecondsSinceEpoch,
      uploadedAt: DateTime.now().toIso8601String(),
    );
    await _save();
  }

  /// Entfernt den Eintrag (z.B. wenn Datei gelöscht wird).
  Future<void> removeEntry(String filename) async {
    await _ensureLoaded();
    if (_entries.remove(filename) != null) await _save();
  }
}

class _Entry {
  final int sizeBytes;
  final int mtimeMs;
  final String uploadedAt;

  const _Entry({
    required this.sizeBytes,
    required this.mtimeMs,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
        'sizeBytes': sizeBytes,
        'mtimeMs': mtimeMs,
        'uploadedAt': uploadedAt,
      };

  factory _Entry.fromJson(Map<String, dynamic> j) => _Entry(
        sizeBytes: j['sizeBytes'] as int,
        mtimeMs: j['mtimeMs'] as int,
        uploadedAt: j['uploadedAt'] as String,
      );
}
