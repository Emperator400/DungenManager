import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../database/core/database_connection.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import 'resource_service.dart';

/// Migriert alte absolute Bildpfade in den `resources/`-Ordner mit `resource://`-Referenzen.
class ImageStorageService {
  /// Kopiert eine Datei in den `resources/`-Ordner und gibt `resource://filename` zurück.
  /// Gibt den Original-Pfad zurück wenn die Datei nicht existiert oder bereits resource:// ist.
  static Future<String?> saveImageToSecureFolder(String originalPath) async {
    if (originalPath.isEmpty) return null;
    if (ResourceService.isResourceRef(originalPath)) return originalPath;

    try {
      final file = File(originalPath);
      if (!await file.exists()) return originalPath;

      final filename = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(originalPath)}';
      return await ResourceService.importFile(originalPath, filename);
    } catch (e) {
      debugPrint('⚠️ Fehler beim Importieren des Bildes: $e');
    }
    return originalPath;
  }

  /// Migriert alle bestehenden Bildpfade (PC, Wiki) in den `resources/`-Ordner.
  static Future<void> migrateExistingImages() async {
    debugPrint('🔄 Starte Bild-Migration in resources/-Ordner...');
    final db = DatabaseConnection.instance;

    try {
      final pcRepo = PlayerCharacterModelRepository(db);
      for (final char in await pcRepo.findAll()) {
        final p = char.imagePath;
        if (p == null || p.isEmpty || ResourceService.isResourceRef(p)) continue;
        final newRef = await saveImageToSecureFolder(p);
        if (newRef != null && newRef != p) {
          await pcRepo.update(char.copyWith(imagePath: newRef));
          debugPrint('✅ PC-Bild migriert: $p → $newRef');
        }
      }

      final wikiRepo = WikiEntryModelRepository(db);
      for (final wiki in await wikiRepo.findAll()) {
        final u = wiki.imageUrl;
        if (u == null || u.isEmpty || ResourceService.isResourceRef(u)) continue;
        final newRef = await saveImageToSecureFolder(u);
        if (newRef != null && newRef != u) {
          await wikiRepo.update(wiki.copyWith(imageUrl: newRef));
          debugPrint('✅ Wiki-Bild migriert: $u → $newRef');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fehler bei der Bild-Migration: $e');
    }
    debugPrint('✅ Bild-Migration abgeschlossen.');
  }
}
