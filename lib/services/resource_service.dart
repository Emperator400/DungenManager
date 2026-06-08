import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ein einzelner Eintrag in der lokalen Ressourcen-Bibliothek.
class ResourceEntry {
  final String filename;
  final String absolutePath;
  final int sizeBytes;
  final DateTime modifiedAt;

  const ResourceEntry({
    required this.filename,
    required this.absolutePath,
    required this.sizeBytes,
    required this.modifiedAt,
  });
}

/// Verwaltet den zentralen Ressourcen-Ordner für Bilder.
///
/// Pfad: `{appDocumentsDir}/DungenManager/resources/`
/// Referenz-Schema: `resource://dateiname.jpg`
///
/// Auflösung ist synchron (nach [init]).
/// Rückwärtskompatibel: absolute Pfade und `cloud://`-Pfade bleiben unverändert.
class ResourceService {
  static const scheme = 'resource://';
  static String? _cachedDir;

  /// Nur für Tests — setzt das Verzeichnis direkt ohne Dateisystem-Zugriff.
  @visibleForTesting
  static void setDirForTesting(String dir) => _cachedDir = dir;

  /// Muss einmal beim App-Start aufgerufen werden (vor [resolveLocalPath]).
  static Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cachedDir = p.join(appDir.path, 'DungenManager', 'resources');
    await Directory(_cachedDir!).create(recursive: true);
  }

  static String get resourcesDir {
    assert(_cachedDir != null, 'ResourceService.init() wurde nicht aufgerufen');
    return _cachedDir!;
  }

  /// Löst eine Referenz zu einem absoluten Pfad auf.
  ///
  /// - `resource://x.jpg` → `{resourcesDir}/x.jpg`
  /// - absoluter Pfad → unverändert (Rückwärtskompatibilität)
  /// - `cloud://...` → null (wird von CloudImageService behandelt)
  /// - null/leer → null
  static String? resolveLocalPath(String? ref) {
    if (ref == null || ref.isEmpty) return null;
    if (ref.startsWith(scheme)) {
      if (_cachedDir == null) return null;
      return p.join(_cachedDir!, ref.replaceFirst(scheme, ''));
    }
    if (ref.startsWith('cloud://')) return null;
    return ref;
  }

  static bool isResourceRef(String? ref) =>
      ref != null && ref.startsWith(scheme);

  static String filenameFromRef(String ref) =>
      ref.replaceFirst(scheme, '');

  /// Kopiert eine Datei in den Ressourcen-Ordner.
  /// [name] ist der vom User gewählte Dateiname (mit Endung).
  /// Gibt `resource://name.ext` zurück.
  static Future<String> importFile(String srcPath, String name) async {
    final dir = Directory(resourcesDir);
    if (!dir.existsSync()) await dir.create(recursive: true);
    final destPath = p.join(resourcesDir, name);
    await File(srcPath).copy(destPath);
    debugPrint('[ResourceService] Importiert: $name');
    return '$scheme$name';
  }

  /// Listet alle Dateien im Ressourcen-Ordner auf.
  static Future<List<ResourceEntry>> listAll() async {
    final dir = Directory(resourcesDir);
    if (!dir.existsSync()) return [];
    final entries = <ResourceEntry>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final filename = p.basename(entity.path);
      if (filename.startsWith('.')) continue;
      final stat = await entity.stat();
      entries.add(ResourceEntry(
        filename: filename,
        absolutePath: entity.path,
        sizeBytes: stat.size,
        modifiedAt: stat.modified,
      ));
    }
    entries.sort((a, b) => a.filename.compareTo(b.filename));
    return entries;
  }

  static Future<void> deleteFile(String filename) async {
    final file = File(p.join(resourcesDir, filename));
    if (file.existsSync()) await file.delete();
    debugPrint('[ResourceService] Gelöscht: $filename');
  }

  static Future<void> renameFile(String oldName, String newName) async {
    final oldFile = File(p.join(resourcesDir, oldName));
    final newPath = p.join(resourcesDir, newName);
    await oldFile.rename(newPath);
    debugPrint('[ResourceService] Umbenannt: $oldName → $newName');
  }

  /// Prüft ob die referenzierte Datei lokal existiert.
  static bool fileExists(String? ref) {
    final path = resolveLocalPath(ref);
    if (path == null) return false;
    return File(path).existsSync();
  }

  static List<String> _imageExtensions = const [
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp',
  ];

  static bool isImageFile(String filename) {
    final ext = p.extension(filename).toLowerCase();
    return _imageExtensions.contains(ext);
  }
}
