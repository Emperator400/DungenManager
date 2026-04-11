import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
//import '../database/repositories/quest_model_repository.dart';
import '../database/core/database_connection.dart';

/// Service zum sicheren Speichern und Migrieren von importierten Bildern
class ImageStorageService {
  /// Sichert ein Bild im permanenten Dokumente-Ordner und gibt den neuen Pfad zurück
  static Future<String?> saveImageToSecureFolder(String originalPath) async {
    if (originalPath.isEmpty) return null;
    
    try {
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      final String securePath = path.join(documentsDir.path, 'DungenManager', 'images');
      final Directory secureDir = Directory(securePath);

      if (!await secureDir.exists()) {
        await secureDir.create(recursive: true);
      }

      // Bereits im sicheren Ordner?
      if (originalPath.contains(securePath)) return originalPath;

      final File sourceFile = File(originalPath);
      if (await sourceFile.exists()) {
        final String fileName = path.basename(originalPath);
        final String newFilePath = path.join(securePath, '${DateTime.now().millisecondsSinceEpoch}_$fileName');

        await sourceFile.copy(newFilePath);
        return newFilePath;
      }
    } catch (e) {
      print('⚠️ Fehler beim Sichern des Bildes: $e');
    }
    return originalPath; // Fallback: Alten Pfad behalten, falls Kopieren fehlschlägt
  }

  /// Migriert alle bestehenden Bilder von Charakteren, Wikis und Quests in den sicheren Ordner
  static Future<void> migrateExistingImages() async {
    print('🔄 Starte Bild-Migration in sicheren Ordner...');
    final dbConnection = DatabaseConnection.instance;
    
    try {
      // 1. Spieler-Charaktere migrieren (Feld: imagePath)
      final pcRepo = PlayerCharacterModelRepository(dbConnection);
      final characters = await pcRepo.findAll();
      for (var char in characters) {
        if (char.imagePath != null && char.imagePath!.isNotEmpty) {
          final newPath = await saveImageToSecureFolder(char.imagePath!);
          if (newPath != null && newPath != char.imagePath) {
            await pcRepo.update(char.copyWith(imagePath: newPath));
            print('✅ Bild für Charakter gesichert.');
          }
        }
      }

      // 2. Wiki-Einträge migrieren (Feld: imageUrl)
      final wikiRepo = WikiEntryModelRepository(dbConnection);
      final wikis = await wikiRepo.findAll();
      for (var wiki in wikis) {
        if (wiki.imageUrl != null && wiki.imageUrl!.isNotEmpty) {
          final newPath = await saveImageToSecureFolder(wiki.imageUrl!);
          if (newPath != null && newPath != wiki.imageUrl) {
            await wikiRepo.update(wiki.copyWith(imageUrl: newPath));
            print('✅ Bild für Wiki-Eintrag gesichert.');
          }
        }
      }

      /* 
      // 3. Quests migrieren (Feld: imageUrl)
      final questRepo = QuestModelRepository(dbConnection);
      final quests = await questRepo.findAll();
      for (var quest in quests) {
        if (quest.imageUrl != null && quest.imageUrl!.isNotEmpty) {
          final newPath = await saveImageToSecureFolder(quest.imageUrl!);
          if (newPath != null && newPath != quest.imageUrl) {
            await questRepo.update(quest.copyWith(imageUrl: newPath));
            print('✅ Bild für Quest gesichert.');
          }
        }
      }
      */
      
    } catch (e) {
      print('⚠️ Fehler bei der generellen Bild-Migration: $e');
    }
    print('✅ Bild-Migration abgeschlossen.');
  }
}