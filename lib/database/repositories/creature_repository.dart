import '../core/database_connection.dart';
import '../../models/creature.dart';
import '../../services/creature_helper_service.dart';
import 'model_repository.dart';

/// Repository für Creature Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem Creature Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
class CreatureRepository extends ModelRepository<Creature> {
  CreatureRepository(DatabaseConnection connection) : super(connection) {
    print('CreatureRepository initialisiert');
  }
  
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

  /// Findet Creatures nach Typ
  Future<List<Creature>> findByType(String type) async {
    return await findWhere(
      where: 'type LIKE ?',
      whereArgs: ['%$type%'],
      orderBy: 'name ASC',
    );
  }

  /// Findet Creatures nach Challenge Rating
  Future<List<Creature>> findByChallengeRating(int challengeRating) async {
    return await findWhere(
      where: 'challenge_rating = ?',
      whereArgs: [challengeRating],
      orderBy: 'name ASC',
    );
  }

  /// Findet Creatures nach CR-Bereich
  Future<List<Creature>> findByChallengeRatingRange(int minCR, int maxCR) async {
    return await findWhere(
      where: 'challenge_rating BETWEEN ? AND ?',
      whereArgs: [minCR, maxCR],
      orderBy: 'challenge_rating ASC, name ASC',
    );
  }

  /// Findet Creatures nach Ausrichtung
  Future<List<Creature>> findByAlignment(String alignment) async {
    return await findWhere(
      where: 'alignment LIKE ?',
      whereArgs: ['%$alignment%'],
      orderBy: 'name ASC',
    );
  }

  /// Sucht Creatures mit komplexen Filtern
  Future<List<Creature>> searchCreatures({
    String? searchTerm,
    String? type,
    String? subtype,
    String? alignment,
    int? minCR,
    int? maxCR,
    String? size,
    bool? isCustom,
    bool? isFavorite,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR description LIKE ? OR attacks LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%', '%$searchTerm%']);
    }

    if (type != null) {
      whereConditions.add('type LIKE ?');
      whereArgs.add('%$type%');
    }

    if (subtype != null) {
      whereConditions.add('subtype LIKE ?');
      whereArgs.add('%$subtype%');
    }

    if (alignment != null) {
      whereConditions.add('alignment LIKE ?');
      whereArgs.add('%$alignment%');
    }

    if (size != null) {
      whereConditions.add('size = ?');
      whereArgs.add(size);
    }

    if (minCR != null) {
      whereConditions.add('challenge_rating >= ?');
      whereArgs.add(minCR);
    }

    if (maxCR != null) {
      whereConditions.add('challenge_rating <= ?');
      whereArgs.add(maxCR);
    }

    if (isCustom != null) {
      whereConditions.add('is_custom = ?');
      whereArgs.add(isCustom ? 1 : 0);
    }

    if (isFavorite != null) {
      whereConditions.add('is_favorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'challenge_rating ASC, name ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== CREATURE-STATISTIKEN =====

  /// Holt umfassende Statistiken über Creatures
  Future<Map<String, dynamic>> getCreatureStatistics() async {
    // Gesamtzahl der Creatures
    final totalCount = await count();
    
    // Favorisierte Creatures
    final favoriteCount = await count(where: 'is_favorite = ?', whereArgs: [1]);
    
    // Custom Creatures
    final customCount = await count(where: 'is_custom = ?', whereArgs: [1]);
    
    // Durchschnittliches CR
    final avgCrResult = await rawQuery(
      'SELECT AVG(challenge_rating) as avg_cr FROM $tableName',
    );
    final avgCr = (avgCrResult.first['avg_cr'] as double?)?.toDouble() ?? 0.0;
    
    // CR-Verteilung
    final crDistributionResult = await rawQuery('''
      SELECT 
        CASE 
          WHEN challenge_rating BETWEEN 0 AND 1 THEN 'CR 0-1'
          WHEN challenge_rating BETWEEN 2 AND 5 THEN 'CR 2-5'
          WHEN challenge_rating BETWEEN 6 AND 10 THEN 'CR 6-10'
          WHEN challenge_rating BETWEEN 11 AND 15 THEN 'CR 11-15'
          WHEN challenge_rating >= 16 THEN 'CR 16+'
        END as cr_range,
        COUNT(*) as count
      FROM $tableName
      GROUP BY cr_range
      ORDER BY MIN(challenge_rating)
    ''');
    
    // Typ-Verteilung
    final typeDistributionResult = await rawQuery('''
      SELECT type, COUNT(*) as count
      FROM $tableName
      WHERE type IS NOT NULL
      GROUP BY type
      ORDER BY count DESC
    ''');
    
    // Größen-Verteilung
    final sizeDistributionResult = await rawQuery('''
      SELECT size, COUNT(*) as count
      FROM $tableName
      WHERE size IS NOT NULL
      GROUP BY size
      ORDER BY count DESC
    ''');

    return {
      'totalCreatures': totalCount,
      'favoriteCreatures': favoriteCount,
      'nonFavoriteCreatures': totalCount - favoriteCount,
      'customCreatures': customCount,
      'officialCreatures': totalCount - customCount,
      'averageChallengeRating': avgCr,
      'crDistribution': crDistributionResult,
      'typeDistribution': typeDistributionResult,
      'sizeDistribution': sizeDistributionResult,
    };
  }

  /// ===== CREATURE-OPERATIONEN =====

  /// Favorit-Status umschalten
  Future<Creature> toggleFavorite(String creatureId) async {
    final creature = await findById(creatureId);
    if (creature == null) {
      throw Exception('Creature not found: $creatureId');
    }

    final updatedCreature = CreatureHelperService.copyWith(
      creature,
      isFavorite: !creature.isFavorite,
    );
    return await update(updatedCreature);
  }

  /// ===== ADVANCED SUCHEN =====

  /// Duplizierte Creatures finden (gleicher Name)
  Future<List<Creature>> findDuplicateCreatures() async {
    final maps = await rawQuery('''
      SELECT c1.*
      FROM $tableName c1
      INNER JOIN $tableName c2 ON 
        c1.name = c2.name AND 
        c1.id < c2.id
      ORDER BY c1.name
    ''');
    
    return maps.map((map) => fromDatabaseMap(map)).toList();
  }

  /// Creatures nach Name suchen
  Future<List<Creature>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
  }

  /// Offizielle Creatures finden
  Future<List<Creature>> findOfficialCreatures() async {
    return await findWhere(
      where: 'is_custom = ?',
      whereArgs: [0],
      orderBy: 'name ASC',
    );
  }

  /// Custom Creatures finden
  Future<List<Creature>> findCustomCreatures() async {
    return await findWhere(
      where: 'is_custom = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  /// ===== BATCH OPERATIONEN =====

  /// Mehrere Creatures als Favorit markieren
  Future<List<Creature>> setMultipleAsFavorite(
    List<String> creatureIds,
    bool isFavorite,
  ) async {
    final results = <Creature>[];
    
    for (final creatureId in creatureIds) {
      try {
        final creature = await findById(creatureId);
        if (creature != null) {
          final updated = CreatureHelperService.copyWith(
            creature,
            isFavorite: isFavorite,
          );
          final result = await update(updated);
          results.add(result);
        }
      } catch (e) {
        print('Error setting favorite status for creature $creatureId: $e');
      }
    }
    
    return results;
  }
}
