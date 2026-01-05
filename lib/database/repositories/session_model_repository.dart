import '../core/database_connection.dart';
import '../../models/session.dart';
import 'model_repository.dart';

/// Repository für Session Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem Session Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.
class SessionModelRepository extends ModelRepository<Session> {
  SessionModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'sessions';

  @override
  Map<String, dynamic> toDatabaseMap(Session session) {
    return session.toDatabaseMap();
  }

  @override
  Session fromDatabaseMap(Map<String, dynamic> map) {
    return Session.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Sessions nach Kampagne
  Future<List<Session>> findByCampaign(String campaignId) async {
    return await findWhere(
      where: 'campaignId = ?',
      whereArgs: [campaignId],
      orderBy: 'date DESC',
    );
  }

  /// Findet Sessions nach Status
  Future<List<Session>> findByStatus(String status) async {
    return await findWhere(
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'date DESC',
    );
  }

  /// Findet Sessions nach Datum-Bereich
  Future<List<Session>> findByDateRange(DateTime startDate, DateTime endDate) async {
    return await findWhere(
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
  }

  /// Sucht Sessions mit komplexen Filtern
  Future<List<Session>> searchSessions({
    String? searchTerm,
    String? campaignId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR summary LIKE ? OR notes LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%', '%$searchTerm%']);
    }

    if (campaignId != null) {
      whereConditions.add('campaignId = ?');
      whereArgs.add(campaignId);
    }

    if (status != null) {
      whereConditions.add('status = ?');
      whereArgs.add(status);
    }

    if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (location != null) {
      whereConditions.add('location LIKE ?');
      whereArgs.add('%$location%');
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== SESSION-STATISTIKEN =====

  /// Holt umfassende Statistiken über Sessions
  Future<Map<String, dynamic>> getSessionStatistics() async {
    // Gesamtzahl der Sessions
    final totalCount = await count();
    
    // Status-Verteilung
    final statusDistributionResult = await rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM $tableName
      GROUP BY status
      ORDER BY status
    ''');
    
    // Durchschnittliche Session-Länge (in Minuten)
    final avgDurationResult = await rawQuery('''
      SELECT 
        AVG(durationInMinutes) as avg_duration
      FROM $tableName
      WHERE durationInMinutes IS NOT NULL
    ''');

    return {
      'totalSessions': totalCount,
      'statusDistribution': statusDistributionResult,
      'averageDuration': (avgDurationResult.first['avg_duration'] as double?)?.toInt() ?? 0,
    };
  }

  /// ===== ADVANCED SUCHEN =====

  /// Sessions nach Namen suchen
  Future<List<Session>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'date DESC',
    );
  }

  /// Letzte Sessions finden
  Future<List<Session>> findRecentSessions(int limit) async {
    return await findWhere(
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  /// Sessions nach Location finden
  Future<List<Session>> findByLocation(String location) async {
    return await findWhere(
      where: 'location LIKE ?',
      whereArgs: ['%$location%'],
      orderBy: 'date DESC',
    );
  }
}
