import '../core/database_connection.dart';
import '../../models/player_character.dart';
import '../../models/inventory_item.dart';
import '../../models/attack.dart';
import 'model_repository.dart';

/// Repository für PlayerCharacter Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem PlayerCharacter Modell,
// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.
class PlayerCharacterModelRepository extends ModelRepository<PlayerCharacter> {
  PlayerCharacterModelRepository(DatabaseConnection connection) : super(connection) {
    print('PlayerCharacterModelRepository initialisiert');
  }
  
  @override
  String get tableName => PlayerCharacter.tableName;

  @override
  Map<String, dynamic> toDatabaseMap(PlayerCharacter character) {
    final map = character.toDatabaseMap();
    print('toDatabaseMap aufgerufen für Character: ${character.name}');
    print('  ID: ${character.id}');
    print('  Campaign ID: ${character.campaignId}');
    print('  Map Keys: ${map.keys.join(', ')}');
    return map;
  }

  @override
  PlayerCharacter fromDatabaseMap(Map<String, dynamic> map) {
    print('fromDatabaseMap aufgerufen');
    print('  ID: ${map['id']}');
    print('  Name: ${map['name']}');
    return PlayerCharacter.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Charaktere nach Kampagne
  Future<List<PlayerCharacter>> findByCampaign(String campaignId) async {
    return await findWhere(
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'name ASC',
    );
  }

  /// Findet Charaktere nach Level-Bereich
  Future<List<PlayerCharacter>> findByLevelRange(int minLevel, int maxLevel) async {
    return await findWhere(
      where: 'level BETWEEN ? AND ?',
      whereArgs: [minLevel, maxLevel],
      orderBy: 'level ASC, name ASC',
    );
  }

  /// Findet Charaktere nach Klasse
  Future<List<PlayerCharacter>> findByClass(String characterClass) async {
    return await findWhere(
      where: 'class_name LIKE ?',
      whereArgs: ['%$characterClass%'],
      orderBy: 'level DESC, name ASC',
    );
  }

  /// Findet Charaktere nach Rasse
  Future<List<PlayerCharacter>> findByRace(String race) async {
    return await findWhere(
      where: 'race_name LIKE ?',
      whereArgs: ['%$race%'],
      orderBy: 'name ASC',
    );
  }

  /// Sucht Charaktere mit komplexen Filtern
  Future<List<PlayerCharacter>> searchCharacters({
    String? searchTerm,
    String? campaignId,
    String? characterClass,
    String? race,
    int? minLevel,
    int? maxLevel,
    bool? isFavorite,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR description LIKE ? OR alignment LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%', '%$searchTerm%']);
    }

    if (campaignId != null) {
      whereConditions.add('campaign_id = ?');
      whereArgs.add(campaignId);
    }

    if (characterClass != null) {
      whereConditions.add('class_name LIKE ?');
      whereArgs.add('%$characterClass%');
    }

    if (race != null) {
      whereConditions.add('race_name LIKE ?');
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

    if (isFavorite != null) {
      whereConditions.add('is_favorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'level DESC, name ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== CHARAKTER-STATISTIKEN =====

  /// Holt umfassende Statistiken über Charaktere
  Future<Map<String, dynamic>> getCharacterStatistics() async {
    // Gesamtzahl der Charaktere
    final totalCount = await count();
    
    // Favorisierte Charaktere
    final favoriteCount = await count(where: 'is_favorite = ?', whereArgs: [1]);
    
    // Durchschnittliches Level
    final avgLevelResult = await rawQuery(
      'SELECT AVG(level) as avg_level FROM $tableName',
    );
    final avgLevel = (avgLevelResult.first['avg_level'] as double?)?.toDouble() ?? 0.0;
    
    // Level-Verteilung
    final levelDistributionResult = await rawQuery('''
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
    final classDistributionResult = await rawQuery('''
      SELECT class_name, COUNT(*) as count
      FROM $tableName
      GROUP BY class_name
      ORDER BY count DESC
    ''');
    
    // Rassen-Verteilung
    final raceDistributionResult = await rawQuery('''
      SELECT race_name, COUNT(*) as count
      FROM $tableName
      GROUP BY race_name
      ORDER BY count DESC
    ''');

    return {
      'totalCharacters': totalCount,
      'favoriteCharacters': favoriteCount,
      'nonFavoriteCharacters': totalCount - favoriteCount,
      'averageLevel': avgLevel,
      'levelDistribution': levelDistributionResult,
      'classDistribution': classDistributionResult,
      'raceDistribution': raceDistributionResult,
    };
  }

  /// ===== CHARAKTER-OPERATIONEN =====

  /// Level-up eines Charakters
  Future<PlayerCharacter> levelUpCharacter(String characterId, int levelsToGain) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.copyWith(
      level: character.level + levelsToGain,
    );
    return await update(updatedCharacter);
  }

  /// Währung aktualisieren
  Future<PlayerCharacter> updateCurrency(
    String characterId, {
    double? gold,
    double? silver,
    double? copper,
  }) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.copyWith(
      gold: gold ?? character.gold,
      silver: silver ?? character.silver,
      copper: copper ?? character.copper,
    );
    return await update(updatedCharacter);
  }

  /// Favorit-Status umschalten
  Future<PlayerCharacter> toggleFavorite(String characterId) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.copyWith(
      isFavorite: !character.isFavorite,
    );
    return await update(updatedCharacter);
  }

  /// Inventar aktualisieren
  Future<PlayerCharacter> updateInventory(
    String characterId,
    List<InventoryItem> newInventory,
  ) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.copyWith(
      inventory: newInventory,
    );
    return await update(updatedCharacter);
  }

  /// Angriffsliste aktualisieren
  Future<PlayerCharacter> updateAttackList(
    String characterId,
    List<Attack> newAttackList,
  ) async {
    final character = await findById(characterId);
    if (character == null) {
      throw Exception('Character not found: $characterId');
    }

    final updatedCharacter = character.copyWith(
      attackList: newAttackList,
    );
    return await update(updatedCharacter);
  }

  /// ===== ADVANCED SUCHEN =====

  /// Duplizierte Charaktere finden (gleicher Name in gleicher Kampagne)
  Future<List<PlayerCharacter>> findDuplicateCharacters() async {
    final maps = await rawQuery('''
      SELECT c1.*
      FROM $tableName c1
      INNER JOIN $tableName c2 ON 
        c1.name = c2.name AND 
        c1.campaign_id = c2.campaign_id AND 
        c1.id < c2.id
      ORDER BY c1.campaign_id, c1.name
    ''');
    
    return maps.map((map) => fromDatabaseMap(map)).toList();
  }

  /// Charaktere nach Name suchen
  Future<List<PlayerCharacter>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
  }

  /// Charaktere nach Spieler-Namen suchen
  Future<List<PlayerCharacter>> findByPlayerName(String playerName) async {
    return await findWhere(
      where: 'player_name LIKE ?',
      whereArgs: ['%$playerName%'],
      orderBy: 'name ASC',
    );
  }

  /// ===== BATCH OPERATIONEN =====

  /// Mehrere Charaktere zu Kampagne hinzufügen
  Future<List<PlayerCharacter>> addMultipleToCampaign(
    List<String> characterIds,
    String campaignId,
  ) async {
    final results = <PlayerCharacter>[];
    
    for (final characterId in characterIds) {
      try {
        final character = await findById(characterId);
        if (character != null) {
          final updated = character.copyWith(campaignId: campaignId);
          final result = await update(updated);
          results.add(result);
        }
      } catch (e) {
        // Log error but continue with other characters
        print('Error adding character $characterId to campaign: $e');
      }
    }
    
    return results;
  }

  /// Mehrere Charaktere als Favorit markieren
  Future<List<PlayerCharacter>> setMultipleAsFavorite(
    List<String> characterIds,
    bool isFavorite,
  ) async {
    final results = <PlayerCharacter>[];
    
    for (final characterId in characterIds) {
      try {
        final character = await findById(characterId);
        if (character != null) {
          final updated = character.copyWith(isFavorite: isFavorite);
          final result = await update(updated);
          results.add(result);
        }
      } catch (e) {
        print('Error setting favorite status for character $characterId: $e');
      }
    }
    
    return results;
  }
}
