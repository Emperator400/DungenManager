/// SceneService für D&D Kampagnen
/// 
/// Zentraler Service für alle Scene-Operationen als Hauptsäule des Kampagnen-Managements.
/// Verwaltet Scenes, Encounters, Quest-Status und Character-Tracking pro Scene.
library;

import '../database/core/database_connection.dart';
import '../models/scene.dart';
import '../models/encounter.dart';
import '../models/scene_quest_status.dart';

/// Service für Scene-Management
class SceneService {
  final DatabaseConnection _connection;

  SceneService(this._connection);

  // ========== CRUD OPERATIONS ==========

  /// Erstellt eine neue Scene
  Future<Scene> createScene(Scene scene) async {
    final db = await _connection.database;
    await db.insert('scenes', scene.toDatabaseMap());
    return scene;
  }

  /// Aktualisiert eine Scene
  Future<Scene> updateScene(Scene scene) async {
    final db = await _connection.database;
    final updatedScene = scene.copyWith(updatedAt: DateTime.now());
    await db.update(
      'scenes',
      updatedScene.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [scene.id],
    );
    return updatedScene;
  }

  /// Löscht eine Scene
  Future<void> deleteScene(String sceneId) async {
    final db = await _connection.database;
    await db.delete(
      'scenes',
      where: 'id = ?',
      whereArgs: [sceneId],
    );
  }

  /// Holt eine Scene anhand ihrer ID
  Future<Scene?> getSceneById(String sceneId) async {
    final db = await _connection.database;
    final results = await db.query(
      'scenes',
      where: 'id = ?',
      whereArgs: [sceneId],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return Scene.fromDatabaseMap(results.first);
  }

  /// Holt alle Scenes einer Session
  Future<List<Scene>> getScenesBySessionId(String sessionId) async {
    final db = await _connection.database;
    final results = await db.query(
      'scenes',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC',
    );
    
    return results.map((map) => Scene.fromDatabaseMap(map)).toList();
  }

  /// Holt alle Scenes einer Kampagne (über Sessions)
  Future<List<Scene>> getScenesByCampaignId(String campaignId) async {
    final db = await _connection.database;
    final results = await db.rawQuery('''
      SELECT s.* 
      FROM scenes s
      INNER JOIN sessions sess ON s.session_id = sess.id
      WHERE sess.campaignId = ?
      ORDER BY sess.created_at DESC, s.order_index ASC
    ''', [campaignId]);
    
    return results.map((map) => Scene.fromDatabaseMap(map)).toList();
  }

  // ========== ENCOUNTER LINKING ==========

  /// Verknüpft einen Encounter mit einer Scene
  Future<void> linkEncounter(String sceneId, String encounterId) async {
    final scene = await getSceneById(sceneId);
    if (scene == null) {
      throw Exception('Scene not found: $sceneId');
    }
    
    final updatedScene = scene.copyWith(linkedEncounterId: encounterId);
    await updateScene(updatedScene);
  }

  /// Entfernt die Encounter-Verknüpfung einer Scene
  Future<void> unlinkEncounter(String sceneId) async {
    final scene = await getSceneById(sceneId);
    if (scene == null) {
      throw Exception('Scene not found: $sceneId');
    }
    
    final updatedScene = scene.copyWith(linkedEncounterId: null);
    await updateScene(updatedScene);
  }

  /// Holt den Encounter einer Scene
  Future<Encounter?> getEncounterForScene(String sceneId) async {
    final scene = await getSceneById(sceneId);
    if (scene?.linkedEncounterId == null) return null;
    
    final db = await _connection.database;
    final results = await db.query(
      'encounters',
      where: 'id = ?',
      whereArgs: [scene!.linkedEncounterId],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    return Encounter.fromDatabaseMap(results.first);
  }

  // ========== QUEST STATUS MANAGEMENT ==========

  /// Setzt den Status eines Quests in einer Scene
  Future<void> setQuestStatus(
    String sceneId,
    String questId,
    QuestStatus status,
  ) async {
    final db = await _connection.database;
    
    // Prüfe ob Eintrag bereits existiert
    final existing = await db.query(
      'scene_quest_status',
      where: 'scene_id = ? AND quest_id = ?',
      whereArgs: [sceneId, questId],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      // Aktualisiere bestehenden Eintrag
      final progress = status == QuestStatus.completed ? 100 : 0;
      await db.update(
        'scene_quest_status',
        {
          'status': status.name,
          'progress': progress,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Erstelle neuen Eintrag
      await db.insert('scene_quest_status', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'scene_id': sceneId,
        'quest_id': questId,
        'status': status.name,
        'progress': status == QuestStatus.completed ? 100 : 0,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Holt alle Quest-Status für eine Scene
  Future<List<SceneQuestStatus>> getQuestStatusForScene(String sceneId) async {
    final db = await _connection.database;
    final results = await db.query(
      'scene_quest_status',
      where: 'scene_id = ?',
      whereArgs: [sceneId],
      orderBy: 'last_updated DESC',
    );
    
    return results.map((map) => SceneQuestStatus.fromDatabaseMap(map)).toList();
  }

  /// Holt alle Scenes, in denen ein Quest einen bestimmten Status hat
  Future<List<Scene>> getScenesForQuest(
    String questId,
    QuestStatus status,
  ) async {
    final db = await _connection.database;
    final results = await db.rawQuery('''
      SELECT s.* 
      FROM scenes s
      INNER JOIN scene_quest_status sqs ON s.id = sqs.scene_id
      WHERE sqs.quest_id = ? AND sqs.status = ?
      ORDER BY s.order_index ASC
    ''', [questId, status.name]);
    
    return results.map((map) => Scene.fromDatabaseMap(map)).toList();
  }

  // ========== CHARACTER LINKING ==========

  /// Fügt einen Charakter zu einer Scene hinzu
  Future<void> addCharacterToScene(String sceneId, String characterId) async {
    final scene = await getSceneById(sceneId);
    if (scene == null) {
      throw Exception('Scene not found: $sceneId');
    }
    
    final characters = List<String>.from(scene.linkedCharacterIds);
    if (!characters.contains(characterId)) {
      characters.add(characterId);
      final updatedScene = scene.copyWith(linkedCharacterIds: characters);
      await updateScene(updatedScene);
    }
  }

  /// Entfernt einen Charakter aus einer Scene
  Future<void> removeCharacterFromScene(String sceneId, String characterId) async {
    final scene = await getSceneById(sceneId);
    if (scene == null) {
      throw Exception('Scene not found: $sceneId');
    }
    
    final characters = List<String>.from(scene.linkedCharacterIds);
    characters.remove(characterId);
    final updatedScene = scene.copyWith(linkedCharacterIds: characters);
    await updateScene(updatedScene);
  }

  /// Holt alle Charakter-IDs einer Scene
  Future<List<String>> getCharactersForScene(String sceneId) async {
    final scene = await getSceneById(sceneId);
    return scene?.linkedCharacterIds ?? [];
  }

  // ========== WORKFLOW METHODS ==========

  /// Aktiviert eine Scene (setzt sie als aktiv)
  Future<void> activateScene(String sceneId) async {
    final scene = await getSceneById(sceneId);
    if (scene == null) {
      throw Exception('Scene not found: $sceneId');
    }
    
    // Scene als aktiv markieren
    final updatedScene = scene.copyWith(isCompleted: false);
    await updateScene(updatedScene);
    
    // Alle Quests in dieser Scene auf "aktiv" setzen
    final questStatuses = await getQuestStatusForScene(sceneId);
    for (final questStatus in questStatuses) {
      if (questStatus.status == QuestStatus.paused) {
        await setQuestStatus(sceneId, questStatus.questId, QuestStatus.active);
      }
    }
  }

  /// Schließt eine Scene ab
  Future<void> completeScene(String sceneId) async {
    final scene = await getSceneById(sceneId);
    if (scene == null) {
      throw Exception('Scene not found: $sceneId');
    }
    
    // Scene als abgeschlossen markieren
    final updatedScene = scene.copyWith(isCompleted: true);
    await updateScene(updatedScene);
    
    // Alle aktiven Quests auf "abgeschlossen" setzen
    final questStatuses = await getQuestStatusForScene(sceneId);
    for (final questStatus in questStatuses) {
      if (questStatus.status == QuestStatus.active) {
        await setQuestStatus(sceneId, questStatus.questId, QuestStatus.completed);
      }
    }
    
    // Encounter beenden, falls vorhanden
    final encounter = await getEncounterForScene(sceneId);
    if (encounter != null && encounter.status != EncounterStatus.completed) {
      final db = await _connection.database;
      await db.update(
        'encounters',
        {
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [encounter.id],
      );
    }
  }

  // ========== SCENE ORDERING ==========

  /// Verschiebt eine Scene nach oben
  Future<void> moveSceneUp(String sceneId) async {
    final scene = await getSceneById(sceneId);
    if (scene == null || scene.orderIndex <= 0) return;
    
    final scenes = await getScenesBySessionId(scene.sessionId);
    final currentIndex = scenes.indexWhere((s) => s.id == sceneId);
    if (currentIndex <= 0) return;
    
    // Tausche mit vorheriger Scene
    final previousScene = scenes[currentIndex - 1];
    await updateScene(scene.copyWith(orderIndex: currentIndex - 1));
    await updateScene(previousScene.copyWith(orderIndex: currentIndex));
  }

  /// Verschiebt eine Scene nach unten
  Future<void> moveSceneDown(String sceneId) async {
    final scene = await getSceneById(sceneId);
    if (scene == null) return;
    
    final scenes = await getScenesBySessionId(scene.sessionId);
    final currentIndex = scenes.indexWhere((s) => s.id == sceneId);
    if (currentIndex >= scenes.length - 1) return;
    
    // Tausche mit nächster Scene
    final nextScene = scenes[currentIndex + 1];
    await updateScene(scene.copyWith(orderIndex: currentIndex + 1));
    await updateScene(nextScene.copyWith(orderIndex: currentIndex));
  }

  // ========== SCENE DATA MANAGEMENT ==========

  /// Aktualisiert die Scene-Daten
  Future<void> updateSceneData(String sceneId, Map<String, dynamic> sceneData) async {
    final scene = await getSceneById(sceneId);
    if (scene == null) {
      throw Exception('Scene not found: $sceneId');
    }
    
    final updatedScene = scene.copyWith(sceneData: sceneData);
    await updateScene(updatedScene);
  }

  /// Holt die Scene-Daten
  Future<Map<String, dynamic>> getSceneData(String sceneId) async {
    final scene = await getSceneById(sceneId);
    return scene?.sceneData ?? {};
  }
}