import 'base_repository.dart';
import '../entities/quest_entity.dart';
import '../core/database_entity.dart';
import '../core/database_connection.dart';
import '../../models/quest.dart';
import 'package:sqflite/sqflite.dart';

/// Repository für Quest-Entities
/// Bietet typ-sichere CRUD-Operationen für Quests
/// 
/// @deprecated Dieses Repository wird durch QuestModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class QuestRepository extends BaseRepository<QuestEntity> {
  QuestRepository(DatabaseConnection connection) 
      : super(connection);

  @override
  String get tableName => QuestEntity.tableName;

  @override
  DatabaseEntity<QuestEntity> get entityFactory => _QuestEntityFactory();

  /// Quest mit spezifischem Status finden
  Future<List<QuestEntity>> findByStatus(QuestStatus status) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status.toString()],
      orderBy: 'priority DESC, updated_at DESC',
    );
    return maps.map((map) => QuestEntity.fromMap(map)).toList();
  }

  /// Quests für eine Kampagne finden
  Future<List<QuestEntity>> findByCampaign(String campaignId) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'priority DESC, updated_at DESC',
    );
    return maps.map((map) => QuestEntity.fromMap(map)).toList();
  }

  /// Favorisierte Quests finden
  Future<List<QuestEntity>> findFavorites() async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => QuestEntity.fromMap(map)).toList();
  }

  /// Quests nach Typ finden
  Future<List<QuestEntity>> findByType(QuestType questType) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'quest_type = ?',
      whereArgs: [questType.toString()],
      orderBy: 'priority DESC, updated_at DESC',
    );
    return maps.map((map) => QuestEntity.fromMap(map)).toList();
  }

  /// Quests nach Schwierigkeit finden
  Future<List<QuestEntity>> findByDifficulty(QuestDifficulty difficulty) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'difficulty = ?',
      whereArgs: [difficulty.toString()],
      orderBy: 'priority DESC, updated_at DESC',
    );
    return maps.map((map) => QuestEntity.fromMap(map)).toList();
  }

  /// Quests nach Level-Empfehlung finden
  Future<List<QuestEntity>> findByRecommendedLevel(int level, {int tolerance = 2}) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'recommended_level BETWEEN ? AND ?',
      whereArgs: [level - tolerance, level + tolerance],
      orderBy: 'recommended_level ASC, priority DESC',
    );
    return maps.map((map) => QuestEntity.fromMap(map)).toList();
  }

  /// Quest-Statistiken abrufen
  Future<Map<String, int>> getQuestStatistics() async {
    final db = await connection.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM $tableName
      GROUP BY status
    ''');

    final Map<String, int> stats = {};
    for (final row in result) {
      stats[row['status'] as String] = row['count'] as int;
    }
    return stats;
  }

  /// Quest-Priorität aktualisieren
  Future<void> updatePriority(String id, int priority) async {
    final db = await connection.database;
    await db.update(
      tableName,
      {
        'priority': priority,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Quest-Status aktualisieren
  Future<void> updateStatus(String id, QuestStatus status, {DateTime? completedAt}) async {
    final db = await connection.database;
    await db.update(
      tableName,
      {
        'status': status.toString(),
        'completed_at': completedAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Favoriten-Status umschalten
  Future<void> toggleFavorite(String id) async {
    final quest = await findById(id);
    if (quest != null) {
      await update(
        quest.copyWith(
          isFavorite: !quest.isFavorite,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Alle Quests für eine Kampagne abrufen (inkl. Filter)
  Future<List<QuestEntity>> findForCampaignWithFilters(
    String campaignId, {
    QuestStatus? status,
    QuestType? type,
    QuestDifficulty? difficulty,
    bool? isFavorite,
    String? searchText,
  }) async {
    String whereClause = 'campaign_id = ?';
    List<dynamic> whereArgs = [campaignId];

    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status.toString());
    }

    if (type != null) {
      whereClause += ' AND quest_type = ?';
      whereArgs.add(type.toString());
    }

    if (difficulty != null) {
      whereClause += ' AND difficulty = ?';
      whereArgs.add(difficulty.toString());
    }

    if (isFavorite != null) {
      whereClause += ' AND is_favorite = ?';
      whereArgs.add(isFavorite ? 1 : 0);
    }

    if (searchText != null && searchText.isNotEmpty) {
      whereClause += ' AND (title LIKE ? OR description LIKE ?)';
      whereArgs.addAll(['%$searchText%', '%$searchText%']);
    }

    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'priority DESC, updated_at DESC',
    );
    return maps.map((map) => QuestEntity.fromMap(map)).toList();
  }

  /// Quests aus externer Quelle finden
  Future<List<QuestEntity>> findBySourceType(String sourceType) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'source_type = ?',
      whereArgs: [sourceType],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => QuestEntity.fromMap(map)).toList();
  }

  /// Quest-Import durchführen
  Future<void> importQuests(List<Quest> quests, {
    String sourceType = 'import',
    String? sourceId,
    bool overwrite = false,
  }) async {
    final db = await connection.database;
    final batch = db.batch();

    for (final quest in quests) {
      final entity = QuestEntity.fromModel(
        quest,
        sourceType: sourceType,
        sourceId: sourceId,
      );

      if (overwrite) {
        batch.insert(
          tableName,
          entity.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        batch.insert(
          tableName,
          entity.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<QuestEntity> create(QuestEntity entity) async {
    final db = await connection.database;
    final factory = entityFactory as _QuestEntityFactory;
    factory.setCurrentEntity(entity);
    
    final entityMap = factory.toDatabaseMap();
    final id = await db.insert(tableName, entityMap);
    
    // Erstelle eine Kopie mit der neuen ID
    final copy = entity.copyWith();
    copy.id = id as String;
    
    return copy;
  }

  @override
  Future<QuestEntity> update(QuestEntity entity) async {
    final db = await connection.database;
    final factory = entityFactory as _QuestEntityFactory;
    factory.setCurrentEntity(entity);
    
    final entityMap = factory.toDatabaseMap();
    await db.update(
      tableName,
      entityMap,
      where: 'id = ?',
      whereArgs: [entity.id],
    );
    
    return entity;
  }
}

/// Factory-Klasse für QuestEntity
class _QuestEntityFactory extends DatabaseEntity<QuestEntity> {
  QuestEntity? _currentEntity;

  @override
  QuestEntity fromDatabaseMap(Map<String, dynamic> map) {
    return QuestEntity.fromMap(map);
  }

  @override
  Map<String, dynamic> toDatabaseMap() {
    if (_currentEntity != null) {
      return _currentEntity!.toMap();
    }
    throw UnimplementedError('Use setCurrentEntity() before calling toDatabaseMap()');
  }

  @override
  String get tableName => QuestEntity.tableName;

  @override
  List<String> get createTableSql => [QuestEntity.createTableSql()];

  @override
  List<String> get databaseFields => [
    'id', 'title', 'description', 'status', 'quest_type', 'difficulty',
    'created_at', 'updated_at', 'completed_at', 'campaign_id', 'location',
    'recommended_level', 'estimated_duration_hours', 'is_favorite', 'tags',
    'rewards', 'involved_npcs', 'linked_wiki_entry_ids', 'source_type',
    'source_id', 'is_custom', 'version', 'priority', 'quest_giver_id', 'image_url'
  ];

  @override
  bool get isValid => _currentEntity?.isValid ?? false;

  @override
  List<String> get validationErrors => _currentEntity?.validationErrors ?? [];

  /// Hilfsmethode zum Setzen der aktuellen Entity
  void setCurrentEntity(QuestEntity entity) {
    _currentEntity = entity;
  }
}
