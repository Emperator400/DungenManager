// lib/services/sound_scene_service.dart
import 'package:sqflite/sqflite.dart';
import '../database/core/database_connection.dart';
import '../models/sound_scene.dart';
import '../models/sound_scene_item.dart';

/// Service für die Verwaltung von SoundScenes
class SoundSceneService {
  final DatabaseConnection _dbConnection;

  SoundSceneService({DatabaseConnection? dbConnection})
      : _dbConnection = dbConnection ?? DatabaseConnection.instance;

  /// Erstellt eine neue SoundScene
  Future<SoundScene?> createSoundScene(SoundScene scene) async {
    try {
      final db = await _dbConnection.database;
      
      await db.insert(
        'sound_scenes',
        scene.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Items separat einfügen
      for (final item in scene.items) {
        await _insertSoundSceneItem(db, item);
      }
      
      print('✅ SoundScene erstellt: ${scene.name}');
      return scene;
    } catch (e) {
      print('❌ Fehler beim Erstellen der SoundScene: $e');
      return null;
    }
  }

  /// Aktualisiert eine bestehende SoundScene
  Future<bool> updateSoundScene(SoundScene scene) async {
    try {
      final db = await _dbConnection.database;
      
      // Hauptdatensatz aktualisieren
      await db.update(
        'sound_scenes',
        scene.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [scene.id],
      );
      
      print('✅ SoundScene aktualisiert: ${scene.name}');
      return true;
    } catch (e) {
      print('❌ Fehler beim Aktualisieren der SoundScene: $e');
      return false;
    }
  }

  /// Löscht eine SoundScene
  Future<bool> deleteSoundScene(String id) async {
    try {
      final db = await _dbConnection.database;
      
      // Items werden durch CASCADE automatisch gelöscht
      await db.delete(
        'sound_scenes',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('✅ SoundScene gelöscht: $id');
      return true;
    } catch (e) {
      print('❌ Fehler beim Löschen der SoundScene: $e');
      return false;
    }
  }

  /// Lädt alle SoundScenes (ohne Items)
  Future<List<SoundScene>> getAllSoundScenes() async {
    try {
      final db = await _dbConnection.database;
      
      final maps = await db.query(
        'sound_scenes',
        orderBy: 'name ASC',
      );
      
      return maps.map((map) => SoundScene.fromDatabaseMap(map)).toList();
    } catch (e) {
      print('❌ Fehler beim Laden der SoundScenes: $e');
      return [];
    }
  }

  /// Lädt alle SoundScenes mit ihren Items
  Future<List<SoundScene>> getAllSoundScenesWithItems() async {
    try {
      final db = await _dbConnection.database;
      
      final maps = await db.query(
        'sound_scenes',
        orderBy: 'name ASC',
      );
      
      final List<SoundScene> scenes = [];
      
      for (final map in maps) {
        final items = await _getItemsForScene(db, map['id'] as String);
        scenes.add(SoundScene.fromDatabaseMapWithItems(map, items));
      }
      
      return scenes;
    } catch (e) {
      print('❌ Fehler beim Laden der SoundScenes mit Items: $e');
      return [];
    }
  }

  /// Lädt eine einzelne SoundScene mit ihren Items
  Future<SoundScene?> getSoundSceneById(String id) async {
    try {
      final db = await _dbConnection.database;
      
      final maps = await db.query(
        'sound_scenes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      
      final items = await _getItemsForScene(db, id);
      return SoundScene.fromDatabaseMapWithItems(maps.first, items);
    } catch (e) {
      print('❌ Fehler beim Laden der SoundScene: $e');
      return null;
    }
  }

  /// Fügt einen Sound zu einer Szene hinzu
  Future<SoundSceneItem?> addSoundToScene({
    required String sceneId,
    required String soundId,
    double volume = 1.0,
    bool isLooping = true,
    double fadeInDuration = 0.0,
    double fadeOutDuration = 0.0,
  }) async {
    try {
      final db = await _dbConnection.database;
      
      // Höchste sortOrder ermitteln
      final items = await _getItemsForScene(db, sceneId);
      final maxOrder = items.fold<int>(-1, (max, item) => 
          item.sortOrder > max ? item.sortOrder : max);
      
      final item = SoundSceneItem(
        soundSceneId: sceneId,
        soundId: soundId,
        volume: volume,
        isLooping: isLooping,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        sortOrder: maxOrder + 1,
      );
      
      await _insertSoundSceneItem(db, item);
      
      // UpdatedAt der Szene aktualisieren
      await _updateSceneTimestamp(db, sceneId);
      
      print('✅ Sound zu Szene hinzugefügt: $soundId -> $sceneId');
      return item;
    } catch (e) {
      print('❌ Fehler beim Hinzufügen des Sounds zur Szene: $e');
      return null;
    }
  }

  /// Entfernt einen Sound aus einer Szene
  Future<bool> removeSoundFromScene(String sceneId, String soundId) async {
    try {
      final db = await _dbConnection.database;
      
      await db.delete(
        'sound_scene_items',
        where: 'sound_scene_id = ? AND sound_id = ?',
        whereArgs: [sceneId, soundId],
      );
      
      // UpdatedAt der Szene aktualisieren
      await _updateSceneTimestamp(db, sceneId);
      
      print('✅ Sound aus Szene entfernt: $soundId -> $sceneId');
      return true;
    } catch (e) {
      print('❌ Fehler beim Entfernen des Sounds aus der Szene: $e');
      return false;
    }
  }

  /// Aktualisiert ein SoundSceneItem
  Future<bool> updateSoundSceneItem(SoundSceneItem item) async {
    try {
      final db = await _dbConnection.database;
      
      await db.update(
        'sound_scene_items',
        item.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      
      // UpdatedAt der Szene aktualisieren
      await _updateSceneTimestamp(db, item.soundSceneId);
      
      print('✅ SoundSceneItem aktualisiert: ${item.id}');
      return true;
    } catch (e) {
      print('❌ Fehler beim Aktualisieren des SoundSceneItems: $e');
      return false;
    }
  }

  /// Ändert den Favoriten-Status einer Szene
  Future<bool> toggleFavorite(String sceneId) async {
    try {
      final db = await _dbConnection.database;
      
      final scene = await getSoundSceneById(sceneId);
      if (scene == null) return false;
      
      await db.update(
        'sound_scenes',
        {
          'is_favorite': scene.isFavorite ? 0 : 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [sceneId],
      );
      
      return true;
    } catch (e) {
      print('❌ Fehler beim Ändern des Favoriten-Status: $e');
      return false;
    }
  }

  /// Sucht SoundScenes anhand eines Suchbegriffs
  Future<List<SoundScene>> searchSoundScenes(String query) async {
    try {
      final db = await _dbConnection.database;
      
      final maps = await db.query(
        'sound_scenes',
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      
      final List<SoundScene> scenes = [];
      
      for (final map in maps) {
        final items = await _getItemsForScene(db, map['id'] as String);
        scenes.add(SoundScene.fromDatabaseMapWithItems(map, items));
      }
      
      return scenes;
    } catch (e) {
      print('❌ Fehler bei der Suche nach SoundScenes: $e');
      return [];
    }
  }

  // ============ Private Helper Methoden ============

  Future<void> _insertSoundSceneItem(Database db, SoundSceneItem item) async {
    await db.insert(
      'sound_scene_items',
      item.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SoundSceneItem>> _getItemsForScene(Database db, String sceneId) async {
    final maps = await db.query(
      'sound_scene_items',
      where: 'sound_scene_id = ?',
      whereArgs: [sceneId],
      orderBy: 'sort_order ASC',
    );
    
    return maps.map((map) => SoundSceneItem.fromDatabaseMap(map)).toList();
  }

  Future<void> _updateSceneTimestamp(Database db, String sceneId) async {
    await db.update(
      'sound_scenes',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sceneId],
    );
  }
}