import '../../models/sound.dart';
import 'model_repository.dart';

/// Repository für Sound Modelle
class SoundModelRepository extends ModelRepository<Sound> {
  SoundModelRepository(super.connection);

  @override
  String get tableName => 'sounds';

  @override
  Map<String, dynamic> toDatabaseMap(Sound sound) => sound.toDatabaseMap();

  @override
  Sound fromDatabaseMap(Map<String, dynamic> map) => Sound.fromDatabaseMap(map);

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Sounds nach Typ
  Future<List<Sound>> findByType(SoundType type) =>
      findWhere(
        where: 'sound_type = ?',
        whereArgs: [type.toString().split('.').last],
        orderBy: 'name ASC',
      );

  /// Findet Sounds nach IDs (Sounds sind global, nicht kampagnen-gebunden)
  Future<List<Sound>> findByIds(List<String> ids) {
    if (ids.isEmpty) {
      return Future.value([]);
    }
    final placeholders = List.filled(ids.length, '?').join(', ');
    return findWhere(
      where: 'id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'name ASC',
    );
  }

  /// Sucht Sounds mit komplexen Filtern
  Future<List<Sound>> searchSounds({
    String? searchTerm,
    SoundType? type,
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

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== SOUND-STATISTIKEN =====

  Future<Map<String, dynamic>> getSoundStatistics() async {
    final totalCount = await count();

    final typeDistributionResult = await rawQuery('''
      SELECT
        sound_type,
        COUNT(*) as count
      FROM $tableName
      GROUP BY sound_type
      ORDER BY sound_type
    ''');

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

  Future<List<Sound>> findByName(String name) =>
      findWhere(
        where: 'name LIKE ?',
        whereArgs: ['%$name%'],
        orderBy: 'name ASC',
      );

  Future<List<Sound>> findRecentSounds(int limit) =>
      findWhere(orderBy: 'created_at DESC', limit: limit);
}
