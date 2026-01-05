import 'package:sqflite/sqflite.dart';
import '../core/database_connection.dart';
import '../entities/session_entity.dart';
import 'base_repository.dart';

/// Repository für Session-Entitäten
/// Erweitert BaseRepository mit spezialisierten Methoden für Session-Operationen
/// 
/// @deprecated Dieses Repository wird durch SessionModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class SessionRepository extends BaseRepository<SessionEntity> {
  SessionRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'sessions';

  @override
  SessionEntity get entityFactory => createEntity();

  @override
  SessionEntity createEntity() {
    return SessionEntity(
      id: '',
      campaignId: '',
      title: '',
      inGameTimeInMinutes: 0,
      liveNotes: '',
    );
  }

  @override
  SessionEntity fromMap(Map<String, dynamic> map) {
    return SessionEntity.fromMap(map);
  }

  /// Findet Sessions nach Kampagne
  Future<List<SessionEntity>> findByCampaign(String campaignId) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'campaignId = ?',
      whereArgs: [campaignId],
      orderBy: 'title ASC',
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Sucht Sessions mit komplexen Filtern
  Future<List<SessionEntity>> searchSessions({
    String? searchTerm,
    String? campaignId,
    int? limit,
    int? offset,
  }) async {
    final db = await connection.database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(title LIKE ? OR liveNotes LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%']);
    }

    if (campaignId != null) {
      whereConditions.add('campaignId = ?');
      whereArgs.add(campaignId);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;
    final orderBy = 'title ASC';

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Batch-Operationen für Sessions
  Future<List<SessionEntity>> createAll(List<SessionEntity> sessions) async {
    final db = await connection.database;
    
    final batch = db.batch();
    
    for (final session in sessions) {
      batch.insert(
        tableName, 
        session.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
    
    // Sessions haben bereits IDs (TEXT PRIMARY KEY), also geben wir sie zurück
    return sessions;
  }
}
