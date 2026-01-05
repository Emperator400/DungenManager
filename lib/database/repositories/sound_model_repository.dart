import '../core/database_connection.dart';
import '../../models/sound.dart';
import 'model_repository.dart';

/// Repository für Sound Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem Sound Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.
class SoundModelRepository extends ModelRepository<Sound> {
  SoundModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'sounds';

  @override
  Map<String, dynamic> toDatabaseMap(Sound sound) {
    return sound.toDatabaseMap();
  }

  @override
  Sound fromDatabaseMap(Map<String, dynamic> map) {
    return Sound.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Sounds nach Typ
  Future<List<Sound>> findByType(SoundType type) async {
    return await findWhere(
      where: 'sound_type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'name ASC',
    );
  }

  /// Findet Sounds nach Kampagne
  Future<List<Sound>> findByCampaign(String campaignId) async {
    return await findWhere(
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'name ASC',
    );
  }

  /// Sucht Sounds mit komplexen Filtern
  Future<List<Sound>> searchSounds({
    String? searchTerm,
    SoundType? type,
    String? campaignId,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR description LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%']);
    }

    if (type != null) {
      whereConditions.add('sound_type = ?');
      whereArgs.add(type.toString().split('.').last);
    }

    if (campaignId != null) {
      whereConditions.add('campaign_id = ?');
      whereArgs.add(campaignId);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== SOUND-STATISTIKEN =====

  /// Holt umfassende Statistiken über Sounds
  Future<Map<String, dynamic>> getSoundStatistics() async {
    // Gesamtzahl der Sounds
    final totalCount = await count();
    
    // Typ-Verteilung
    final typeDistributionResult = await rawQuery('''
      SELECT 
        sound_type,
        COUNT(*) as count
      FROM $tableName
      GROUP BY sound_type
      ORDER BY sound_type
    ''');
    
    // Durchschnittliche Dauer (in Millisekunden)
    final avgDurationResult = await rawQuery('''
      SELECT 
        AVG(duration_in_ms) as avg_duration
      FROM $tableName
      WHERE duration_in_ms IS NOT NULL
    ''');

    return {
      'totalSounds': totalCount,
      'typeDistribution': typeDistributionResult,
      'averageDuration': (avgDurationResult.first['avg_duration'] as double?)?.toInt() ?? 0,
    };
  }

  /// ===== ADVANCED SUCHEN =====

  /// Sounds nach Namen suchen
  Future<List<Sound>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
  }

  /// Letzte Sounds finden
  Future<List<Sound>> findRecentSounds(int limit) async {
    return await findWhere(
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }
}
