import 'package:sqflite/sqflite.dart';
import '../core/database_connection.dart';
import '../entities/player_character_entity.dart';
import 'base_repository.dart';

/// Repository für PlayerCharacter-Entitäten
/// Erweitert BaseRepository mit spezialisierten Methoden für Character-Operationen
/// 
/// @deprecated Dieses Repository wird durch PlayerCharacterModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class PlayerCharacterRepository extends BaseRepository<PlayerCharacterEntity> {
  PlayerCharacterRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'player_characters';

  @override
  PlayerCharacterEntity get entityFactory => createEntity();

  PlayerCharacterEntity createEntity() {
    return PlayerCharacterEntity(
      id: '',
      name: '',
      characterClass: '',
      level: 1,
      race: '',
      hitPoints: 0,
      maxHitPoints: 0,
      armorClass: 10,
      speed: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  PlayerCharacterEntity fromMap(Map<String, dynamic> map) {
    return createEntity().fromDatabaseMap(map);
  }

  /// Spezialisierte Suchmethoden für PlayerCharacter

  /// Findet Charaktere nach Kampagne
  Future<List<PlayerCharacterEntity>> findByCampaign(String campaignId) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Findet aktive Charaktere
  Future<List<PlayerCharacterEntity>> findActiveCharacters() async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Findet Charaktere nach Level-Bereich
  Future<List<PlayerCharacterEntity>> findByLevelRange(int minLevel, int maxLevel) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'level BETWEEN ? AND ?',
      whereArgs: [minLevel, maxLevel],
      orderBy: 'level ASC, name ASC',
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Findet Charaktere nach Klasse
  Future<List<PlayerCharacterEntity>> findByClass(String characterClass) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'character_class LIKE ?',
      whereArgs: ['%$characterClass%'],
      orderBy: 'level DESC, name ASC',
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Findet Charaktere nach Rasse
  Future<List<PlayerCharacterEntity>> findByRace(String race) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'race LIKE ?',
      whereArgs: ['%$race%'],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Sucht Charaktere mit komplexen Filtern
  Future<List<PlayerCharacterEntity>> searchCharacters({
    String? searchTerm,
    String? campaignId,
    String? characterClass,
    String? race,
    int? minLevel,
    int? maxLevel,
    bool? isActive,
    List<String>? tags,
    int? limit,
    int? offset,
  }) async {
    final db = await connection.database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR background LIKE ? OR alignment LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%', '%$searchTerm%']);
    }

    if (campaignId != null) {
      whereConditions.add('campaign_id = ?');
      whereArgs.add(campaignId);
    }

    if (characterClass != null) {
      whereConditions.add('character_class LIKE ?');
      whereArgs.add('%$characterClass%');
    }

    if (race != null) {
      whereConditions.add('race LIKE ?');
      whereArgs.add('%$race%');
    }

    if (minLevel != null) {
      whereConditions.add('level >= ?');
      whereArgs.add(minLevel);
    }

    if (maxLevel != null) {
      whereConditions.add('level <= ?');
      whereArgs.add(maxLevel);
    }

    if (isActive != null) {
      whereConditions.add('is_active = ?');
      whereArgs.add(isActive ? 1 : 0);
    }

    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        whereConditions.add('tags LIKE ?');
        whereArgs.add('%$tag%');
      }
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;
    final orderBy = 'level DESC, name ASC';

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

  /// Charakter-Statistiken
  Future<Map<String, dynamic>> getCharacterStatistics() async {
    final db = await connection.database;
    
    // Gesamtzahl der Charaktere
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    final totalCount = totalResult.first['count'] as int;
    
    // Aktive vs inaktive Charaktere
    final activeResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE is_active = 1',
    );
    final activeCount = activeResult.first['count'] as int;
    
    // Durchschnittliches Level
    final avgLevelResult = await db.rawQuery(
      'SELECT AVG(level) as avg_level FROM $tableName',
    );
    final avgLevel = (avgLevelResult.first['avg_level'] as double?)?.toDouble() ?? 0.0;
    
    // Level-Verteilung
    final levelDistributionResult = await db.rawQuery('''
      SELECT 
        CASE 
          WHEN level BETWEEN 1 AND 5 THEN 'Level 1-5'
          WHEN level BETWEEN 6 AND 10 THEN 'Level 6-10'
          WHEN level BETWEEN 11 AND 15 THEN 'Level 11-15'
          WHEN level BETWEEN 16 AND 20 THEN 'Level 16-20'
        END as level_range,
        COUNT(*) as count
      FROM $tableName
      GROUP BY level_range
      ORDER BY level_range
    ''');
    
    // Klassen-Verteilung
    final classDistributionResult = await db.rawQuery('''
      SELECT character_class, COUNT(*) as count
      FROM $tableName
      GROUP BY character_class
      ORDER BY count DESC
    ''');
    
    // Rassen-Verteilung
    final raceDistributionResult = await db.rawQuery('''
      SELECT race, COUNT(*) as count
      FROM $tableName
      GROUP BY race
      ORDER BY count DESC
    ''');

    return {
      'totalCharacters': totalCount,
      'activeCharacters': activeCount,
      'inactiveCharacters': totalCount - activeCount,
      'activationRate': totalCount > 0 ? (activeCount / totalCount * 100) : 0.0,
      'averageLevel': avgLevel,
      'levelDistribution': levelDistributionResult,
      'classDistribution': classDistributionResult,
      'raceDistribution': raceDistributionResult,
    };
  }

  /// Charakter-Level-up
  Future<PlayerCharacterEntity> levelUpCharacter(String characterId, int levelsToGain) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.levelUp(levelsToGain);
    return await update(updatedCharacter);
  }

  /// Charakter-Schaden zufügen
  Future<PlayerCharacterEntity> applyDamage(String characterId, int damage) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.takeDamage(damage);
    return await update(updatedCharacter);
  }

  /// Charakter heilen
  Future<PlayerCharacterEntity> healCharacter(String characterId, int healing) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.heal(healing);
    return await update(updatedCharacter);
  }

  /// Fähigkeit ändern
  Future<PlayerCharacterEntity> updateAbility(
    String characterId, 
    String ability, 
    int value
  ) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.setAbility(ability, value);
    return await update(updatedCharacter);
  }

  /// Charakter zu Kampagne hinzufügen
  Future<PlayerCharacterEntity> addToCampaign(String characterId, String campaignId) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.addToCampaign(campaignId);
    return await update(updatedCharacter);
  }

  /// Charakter aus Kampagne entfernen
  Future<PlayerCharacterEntity> removeFromCampaign(String characterId) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.removeFromCampaign();
    return await update(updatedCharacter);
  }

  /// Mehrere Charaktere zu Kampagne hinzufügen
  Future<List<PlayerCharacterEntity>> addMultipleToCampaign(
    List<String> characterIds, 
    String campaignId
  ) async {
    final results = <PlayerCharacterEntity>[];
    
    for (final characterId in characterIds) {
      try {
        final updated = await addToCampaign(characterId, campaignId);
        results.add(updated);
      } catch (e) {
        // Log error but continue with other characters
        print('Error adding character $characterId to campaign: $e');
      }
    }
    
    return results;
  }

  /// Charaktere nach Kampagne aktivieren/deaktivieren
  Future<List<PlayerCharacterEntity>> toggleCampaignCharacters(
    String campaignId, 
    bool activate
  ) async {
    final characters = await findByCampaign(campaignId);
    final results = <PlayerCharacterEntity>[];
    
    for (final character in characters) {
      final updated = character.copyWith(
        isActive: activate,
        updatedAt: DateTime.now(),
      );
      final result = await update(updated);
      results.add(result);
    }
    
    return results;
  }

  /// Duplizierte Charaktere finden (gleicher Name in gleicher Kampagne)
  Future<List<PlayerCharacterEntity>> findDuplicateCharacters() async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c1.*
      FROM $tableName c1
      INNER JOIN $tableName c2 ON 
        c1.name = c2.name AND 
        c1.campaign_id = c2.campaign_id AND 
        c1.id < c2.id
      ORDER BY c1.campaign_id, c1.name
    ''');
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Charaktere mit niedrigen HP finden
  Future<List<PlayerCharacterEntity>> findInjuredCharacters({double threshold = 0.5}) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName
      WHERE hit_points < max_hit_points * ?
      AND is_active = 1
      ORDER BY (hit_points * 1.0 / max_hit_points) ASC
    ''', [threshold]);
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Level-up-Kandidaten finden (hohe XP, ready für nächsten Level)
  Future<List<PlayerCharacterEntity>> findLevelUpCandidates() async {
    // Dies ist eine vereinfachte Version - in einer echten Implementierung
    // würdest du XP-Tracks haben
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'level < 20 AND is_active = 1',
      orderBy: 'level DESC, created_at ASC',
      limit: 10,
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Batch-Operationen für Charaktere
  Future<List<PlayerCharacterEntity>> createAll(List<PlayerCharacterEntity> characters) async {
    final results = <PlayerCharacterEntity>[];
    final db = await connection.database;
    
    final batch = db.batch();
    
    for (final character in characters) {
      batch.insert(
        tableName, 
        character.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    final resultsList = await batch.commit();
    
    for (int i = 0; i < characters.length; i++) {
      if (resultsList[i] != null) {
        final id = resultsList[i] as int;
        final character = characters[i].copyWith(id: id.toString());
        results.add(character);
      }
    }
    
    return results;
  }

  /// Health Check für Charakterdaten
  Future<Map<String, dynamic>> performHealthCheck() async {
    final db = await connection.database;
    final issues = <String>[];
    
    // Prüfe auf ungültige Level
    final invalidLevels = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE level < 1 OR level > 20',
    );
    final invalidLevelCount = invalidLevels.first['count'] as int;
    if (invalidLevelCount > 0) {
      issues.add('$invalidLevelCount characters have invalid levels');
    }
    
    // Prüfe auf negative HP
    final negativeHp = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE hit_points < 0',
    );
    final negativeHpCount = negativeHp.first['count'] as int;
    if (negativeHpCount > 0) {
      issues.add('$negativeHpCount characters have negative hit points');
    }
    
    // Prüfe auf HP > MaxHP
    final invalidHp = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE hit_points > max_hit_points',
    );
    final invalidHpCount = invalidHp.first['count'] as int;
    if (invalidHpCount > 0) {
      issues.add('$invalidHpCount characters have more HP than their maximum');
    }
    
    // Prüfe auf ungültige Fähigkeitswerte
    final invalidAbilities = await db.rawQuery('''
      SELECT COUNT(*) as count FROM $tableName 
      WHERE abilities IS NULL OR abilities = ''
    ''');
    final invalidAbilitiesCount = invalidAbilities.first['count'] as int;
    if (invalidAbilitiesCount > 0) {
      issues.add('$invalidAbilitiesCount characters have invalid ability data');
    }
    
    return {
      'healthy': issues.isEmpty,
      'issues': issues,
      'totalIssues': issues.length,
      'checkedAt': DateTime.now().toIso8601String(),
    };
  }
}
