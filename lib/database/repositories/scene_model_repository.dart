import '../core/database_connection.dart';
import 'model_repository.dart';
import '../../models/scene.dart';

/// Repository für Scene-Modelle mit nativer Serialisierung
/// 
/// HINWEIS: Verwendet das neue ModelRepository<T> Pattern
/// - Keine Entity-Klasse mehr nötig
/// - Direkte Arbeit mit Scene-Modellen
/// - Modelle implementieren ihre eigene Serialisierung
class SceneModelRepository extends ModelRepository<Scene> {
  SceneModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'scenes';

  @override
  Map<String, dynamic> toDatabaseMap(Scene scene) {
    return scene.toDatabaseMap();
  }

  @override
  Scene fromDatabaseMap(Map<String, dynamic> map) {
    return Scene.fromDatabaseMap(map);
  }

  // ========== SCENE-SPEZIFISCHE SUCHMETHODEN ==========

  /// Findet alle Szenen für eine Session
  Future<List<Scene>> findBySession(String sessionId) async {
    return await findWhere(
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC',
    );
  }

  /// Findet abgeschlossene Szenen
  Future<List<Scene>> findCompletedScenes() async {
    return await findWhere(
      where: 'is_completed = ?',
      whereArgs: [1],
      orderBy: 'order_index ASC',
    );
  }

  /// Findet offene Szenen
  Future<List<Scene>> findIncompleteScenes() async {
    return await findWhere(
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'order_index ASC',
    );
  }

  /// Findet Szenen nach Typ
  Future<List<Scene>> findByType(String sceneType) async {
    return await findWhere(
      where: 'scene_type = ?',
      whereArgs: [sceneType],
      orderBy: 'order_index ASC',
    );
  }

  /// Findet Szenen nach Name
  Future<List<Scene>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'order_index ASC',
    );
  }

  /// Sucht Szenen mit komplexen Filtern
  Future<List<Scene>> searchScenes({
    String? sessionId,
    String? sceneType,
    bool? isCompleted,
    String? nameQuery,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (sessionId != null) {
      whereConditions.add('session_id = ?');
      whereArgs.add(sessionId);
    }

    if (sceneType != null) {
      whereConditions.add('scene_type = ?');
      whereArgs.add(sceneType);
    }

    if (isCompleted != null) {
      whereConditions.add('is_completed = ?');
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (nameQuery != null && nameQuery.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR description LIKE ?)');
      whereArgs.addAll(['%$nameQuery%', '%$nameQuery%']);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'order_index ASC',
    );
  }

  // ========== SCENE-OPERATIONEN ==========

  /// Aktualisiert den Completion-Status einer Szene
  Future<Scene?> updateCompletionStatus(String sceneId, bool isCompleted) async {
    final scene = await findById(sceneId);
    if (scene == null) return null;

    final updatedScene = scene.copyWith(
      isCompleted: isCompleted,
      updatedAt: DateTime.now(),
    );

    return await update(updatedScene);
  }

  /// Aktualisiert den Typ einer Szene
  Future<Scene?> updateSceneType(String sceneId, SceneType sceneType) async {
    final scene = await findById(sceneId);
    if (scene == null) return null;

    final updatedScene = scene.copyWith(
      sceneType: sceneType,
      updatedAt: DateTime.now(),
    );

    return await update(updatedScene);
  }

  /// Aktualisiert die Reihenfolge einer Szene
  Future<Scene?> updateOrderIndex(String sceneId, int orderIndex) async {
    final scene = await findById(sceneId);
    if (scene == null) return null;

    final updatedScene = scene.copyWith(
      orderIndex: orderIndex,
      updatedAt: DateTime.now(),
    );

    return await update(updatedScene);
  }

  /// Aktualisiert verlinkte Wiki-Einträge
  Future<Scene?> updateLinkedWikiEntries(String sceneId, List<String> wikiEntryIds) async {
    final scene = await findById(sceneId);
    if (scene == null) return null;

    final updatedScene = scene.copyWith(
      linkedWikiEntryIds: wikiEntryIds,
      updatedAt: DateTime.now(),
    );

    return await update(updatedScene);
  }

  /// Aktualisiert verlinkte Quests
  Future<Scene?> updateLinkedQuests(String sceneId, List<String> questIds) async {
    final scene = await findById(sceneId);
    if (scene == null) return null;

    final updatedScene = scene.copyWith(
      linkedQuestIds: questIds,
      updatedAt: DateTime.now(),
    );

    return await update(updatedScene);
  }

  // ========== STATISTIK-FUNKTIONEN ==========

  /// Holt Statistiken über alle Szenen
  Future<Map<String, dynamic>> getSceneStatistics() async {
    final allScenes = await findAll();
    
    final completedCount = allScenes.where((s) => s.isCompleted).length;
    final incompleteCount = allScenes.length - completedCount;
    
    final byType = <String, int>{};
    for (final scene in allScenes) {
      final typeName = scene.sceneType.name;
      byType[typeName] = (byType[typeName] ?? 0) + 1;
    }
    
    return {
      'total': allScenes.length,
      'completed': completedCount,
      'incomplete': incompleteCount,
      'completion_rate': allScenes.isEmpty 
          ? 0.0 
          : (completedCount / allScenes.length * 100).roundToDouble(),
      'by_type': byType,
    };
  }

  /// Holt Statistiken für eine Session
  Future<Map<String, dynamic>> getSessionSceneStatistics(String sessionId) async {
    final sessionScenes = await findBySession(sessionId);
    
    if (sessionScenes.isEmpty) {
      return {
        'total': 0,
        'completed': 0,
        'incomplete': 0,
        'completion_rate': 0.0,
      };
    }
    
    final completedCount = sessionScenes.where((s) => s.isCompleted).length;
    final incompleteCount = sessionScenes.length - completedCount;
    
    return {
      'total': sessionScenes.length,
      'completed': completedCount,
      'incomplete': incompleteCount,
      'completion_rate': (completedCount / sessionScenes.length * 100).roundToDouble(),
    };
  }

  // ========== BATCH-OPERATIONEN ==========

  /// Dupliziert mehrere Szenen für eine neue Session
  Future<List<Scene>> duplicateScenesForSession(
    List<String> sceneIds, 
    String newSessionId,
  ) async {
    final scenesToDuplicate = <Scene>[];
    for (final sceneId in sceneIds) {
      final scene = await findById(sceneId);
      if (scene != null) {
        scenesToDuplicate.add(scene);
      }
    }
    
    final duplicatedScenes = <Scene>[];
    
    for (final scene in scenesToDuplicate) {
      final duplicated = Scene(
        sessionId: newSessionId,
        orderIndex: scene.orderIndex,
        name: '${scene.name} (Kopie)',
        description: scene.description,
        sceneType: scene.sceneType,
        estimatedDuration: scene.estimatedDuration,
        complexity: scene.complexity,
        linkedWikiEntryIds: List.from(scene.linkedWikiEntryIds),
        linkedQuestIds: List.from(scene.linkedQuestIds),
      );
      
      final created = await create(duplicated);
      if (created != null) {
        duplicatedScenes.add(created);
      }
    }
    
    return duplicatedScenes;
  }

  /// Setzt alle Szenen einer Session als nicht abgeschlossen
  Future<int> resetSessionScenes(String sessionId) async {
    final sessionScenes = await findBySession(sessionId);
    var updatedCount = 0;
    
    for (final scene in sessionScenes) {
      if (scene.isCompleted) {
        final updated = await updateCompletionStatus(scene.id, false);
        if (updated != null) {
          updatedCount++;
        }
      }
    }
    
    return updatedCount;
  }
}
