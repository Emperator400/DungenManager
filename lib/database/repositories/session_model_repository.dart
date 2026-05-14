import '../../models/session.dart';
import 'model_repository.dart';

/// Repository für Session Modelle
class SessionModelRepository extends ModelRepository<Session> {
  SessionModelRepository(super.connection);

  @override
  String get tableName => 'sessions';

  @override
  Map<String, dynamic> toDatabaseMap(Session session) => session.toDatabaseMap();

  @override
  Session fromDatabaseMap(Map<String, dynamic> map) => Session.fromDatabaseMap(map);

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  Future<List<Session>> findByCampaign(String campaignId) async =>
      findWhere(
        where: 'campaignId = ?',
        whereArgs: [campaignId],
        orderBy: 'createdAt DESC',
      );

  Future<List<Session>> findByOrtId(String ortId) async =>
      findWhere(
        where: 'ortId = ?',
        whereArgs: [ortId],
        orderBy: 'createdAt DESC',
      );

  /// Findet Sessions nach Status (pending/active/completed)
  Future<List<Session>> findByStatus(String status) async {
    final String where;
    switch (status) {
      case 'active':
        where = 'startedAt IS NOT NULL AND completedAt IS NULL';
      case 'completed':
        where = 'completedAt IS NOT NULL';
      default: // pending
        where = 'startedAt IS NULL';
    }
    return findWhere(where: where, orderBy: 'createdAt DESC');
  }

  Future<List<Session>> findByDateRange(DateTime startDate, DateTime endDate) async =>
      findWhere(
        where: 'createdAt BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'createdAt DESC',
      );

  /// Sucht Sessions mit komplexen Filtern
  Future<List<Session>> searchSessions({
    String? searchTerm,
    String? campaignId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? ortId,
    int? limit,
    int? offset,
  }) async {
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

    if (status != null) {
      switch (status) {
        case 'active':
          whereConditions.add('startedAt IS NOT NULL AND completedAt IS NULL');
        case 'completed':
          whereConditions.add('completedAt IS NOT NULL');
        default:
          whereConditions.add('startedAt IS NULL');
      }
    }

    if (startDate != null) {
      whereConditions.add('createdAt >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereConditions.add('createdAt <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (ortId != null) {
      whereConditions.add('ortId = ?');
      whereArgs.add(ortId);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== SESSION-STATISTIKEN =====

  Future<Map<String, dynamic>> getSessionStatistics() async {
    final totalCount = await count();

    final statusDistributionResult = await rawQuery('''
      SELECT
        CASE
          WHEN completedAt IS NOT NULL THEN 'completed'
          WHEN startedAt IS NOT NULL THEN 'active'
          ELSE 'pending'
        END as status,
        COUNT(*) as count
      FROM $tableName
      GROUP BY status
      ORDER BY status
    ''');

    final avgDurationResult = await rawQuery('''
      SELECT
        AVG(inGameTimeInMinutes) as avg_duration
      FROM $tableName
      WHERE inGameTimeInMinutes IS NOT NULL
    ''');

    return {
      'totalSessions': totalCount,
      'statusDistribution': statusDistributionResult,
      'averageDuration': (avgDurationResult.first['avg_duration'] as double?)?.toInt() ?? 0,
    };
  }

  /// ===== ADVANCED SUCHEN =====

  Future<List<Session>> findByName(String name) async =>
      findWhere(
        where: 'title LIKE ?',
        whereArgs: ['%$name%'],
        orderBy: 'createdAt DESC',
      );

  Future<List<Session>> findRecentSessions(int limit) async =>
      findWhere(orderBy: 'createdAt DESC', limit: limit);

  Future<List<Session>> findByLocation(String ortId) async =>
      findWhere(
        where: 'ortId = ?',
        whereArgs: [ortId],
        orderBy: 'createdAt DESC',
      );
}
