import '../core/database_connection.dart';
import '../../models/creature.dart';
import 'model_repository.dart';

/// Repository für Creature Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem Creature Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.
class CreatureModelRepository extends ModelRepository<Creature> {
  CreatureModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'creatures';

  @override
  Map<String, dynamic> toDatabaseMap(Creature creature) {
    return creature.toDatabaseMap();
  }

  @override
  Creature fromDatabaseMap(Map<String, dynamic> map) {
    return Creature.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Kreaturen nach Typ
  Future<List<Creature>> findByType(String type) async {
    return await findWhere(
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
  }

  /// Findet Kreaturen nach Kampagne
  Future<List<Creature>> findByCampaign(String campaignId) async {
    return await findWhere(
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'name ASC',
    );
  }

  /// Findet Kreaturen nach Level-Bereich
  Future<List<Creature>> findByChallengeRatingRange(double minCR, double maxCR) async {
    return await findWhere(
      where: 'challenge_rating BETWEEN ? AND ?',
      whereArgs: [minCR, maxCR],
      orderBy: 'challenge_rating ASC, name ASC',
    );
  }

  /// Sucht Kreaturen mit komplexen Filtern
  Future<List<Creature>> searchCreatures({
    String? searchTerm,
    String? type,
    String? campaignId,
    double? minChallengeRating,
    double? maxChallengeRating,
    int? minHitPoints,
    int? maxHitPoints,
    String? environment,
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
      whereConditions.add('type = ?');
      whereArgs.add(type);
    }

    if (campaignId != null) {
      whereConditions.add('campaign_id = ?');
      whereArgs.add(campaignId);
    }

    if (minChallengeRating != null) {
      whereConditions.add('challenge_rating >= ?');
      whereArgs.add(minChallengeRating);
    }

    if (maxChallengeRating != null) {
      whereConditions.add('challenge_rating <= ?');
      whereArgs.add(maxChallengeRating);
    }

    if (minHitPoints != null) {
      whereConditions.add('hit_points >= ?');
      whereArgs.add(minHitPoints);
    }

    if (maxHitPoints != null) {
      whereConditions.add('hit_points <= ?');
      whereArgs.add(maxHitPoints);
    }

    if (environment != null) {
      whereConditions.add('environment LIKE ?');
      whereArgs.add('%$environment%');
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

  /// ===== CREATURE-STATISTIKEN =====

  /// Holt umfassende Statistiken über Kreaturen
  Future<Map<String, dynamic>> getCreatureStatistics() async {
    // Gesamtzahl der Kreaturen
    final totalCount = await count();
    
    // Typ-Verteilung
    final typeDistributionResult = await rawQuery('''
      SELECT 
        type,
        COUNT(*) as count
      FROM $tableName
      GROUP BY type
      ORDER BY count DESC
    ''');
    
    // Durchschnittliche Stats
    final avgStatsResult = await rawQuery('''
      SELECT 
        AVG(challenge_rating) as avg_challenge_rating,
        AVG(hit_points) as avg_hit_points,
        AVG(armor_class) as avg_armor_class,
        AVG(level) as avg_level
      FROM $tableName
      WHERE challenge_rating IS NOT NULL
    ''');

    return {
      'totalCreatures': totalCount,
      'typeDistribution': typeDistributionResult,
      'averageChallengeRating': (avgStatsResult.first['avg_challenge_rating'] as double?)?.toDouble() ?? 0.0,
      'averageHitPoints': (avgStatsResult.first['avg_hit_points'] as double?)?.toInt() ?? 0,
      'averageArmorClass': (avgStatsResult.first['avg_armor_class'] as double?)?.toInt() ?? 0,
      'averageLevel': (avgStatsResult.first['avg_level'] as double?)?.toInt() ?? 0,
    };
  }

  /// ===== ADVANCED SUCHEN =====

  /// Kreaturen nach Namen suchen
  Future<List<Creature>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
  }

  /// Kreaturen nach Challenge Rating finden
  Future<List<Creature>> findByChallengeRating(double challengeRating) async {
    return await findWhere(
      where: 'challenge_rating = ?',
      whereArgs: [challengeRating],
      orderBy: 'name ASC',
    );
  }

  /// Kreaturen ohne Kampagne finden
  Future<List<Creature>> findCreaturesWithoutCampaign() async {
    return await findWhere(
      where: 'campaign_id IS NULL OR campaign_id = ?',
      whereArgs: [''],
      orderBy: 'name ASC',
    );
  }
}
