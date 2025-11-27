// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/attack.dart';
import '../models/creature.dart';
import '../models/inventory_item.dart';
import '../models/player_character.dart';
import '../database/database_helper.dart';
import 'attack_parser_service.dart';
import 'exceptions/service_exceptions.dart';
import 'uuid_service.dart';

/// Zentraler Service für alle Character Editor Business-Logik
/// ersetzt direkte Datenbankzugriffe und verstreute Logik
/// Verwendet spezifische Exceptions und ServiceResult Pattern.
class CharacterEditorService {
  // Constructor-Abschnitt - Muss zuerst stehen (sort_constructors_first)
  final DatabaseHelper _dbHelper;
  final UuidService _uuidService;

  CharacterEditorService({
    DatabaseHelper? dbHelper,
    UuidService? uuidService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _uuidService = uuidService ?? UuidService();

  // ============================================================================

  // HELPER METHOD FOR SERVICE OPERATIONS
  // ============================================================================

  /// Führt eine Service-Operation mit Fehlerbehandlung aus
  Future<T> performServiceOperation<T>(
    String operation,
    Future<T> Function() operationFunc,
  ) async {
    try {
      return await operationFunc();
    } catch (e) {
      if (e is ServiceException) {
        rethrow;
      }
      throw BusinessException(
        'Fehler in $operation: $e',
        operation: operation,
        originalError: e,
      );
    }
  }

  // ============================================================================
  // CHARACTER CREATION & UPDATES
  // ============================================================================

  /// Erstellt einen neuen Player Character mit voller Validierung
  Future<ServiceResult<String>> createPlayerCharacter({
    required String campaignId,
    required String name,
    required String playerName,
    required String className,
    required String raceName,
    required int level,
    required Map<String, int> attributes,
    required Set<String> proficientSkills,
    String? imagePath,
    String? description,
    List<Attack>? attackList,
    List<InventoryItem>? inventory,
    double gold = 0.0,
  }) async {
    try {
      final characterId = await performServiceOperation('createPlayerCharacter', () async {
        // Validierung
        validateCharacterData(
          name: name,
          playerName: playerName,
          className: className,
          raceName: raceName,
          level: level,
          attributes: attributes,
        );

        // Character erstellen
        final id = _uuidService.generateId();
        
        final pc = PlayerCharacter(
          id: id,
          campaignId: campaignId,
          name: name.trim(),
          playerName: playerName.trim(),
          className: className,
          raceName: raceName,
          level: level,
          maxHp: calculateMaxHp(attributes['constitution'] ?? 10, level),
          armorClass: calculateBaseAC(attributes['dexterity'] ?? 10),
          initiativeBonus: calculateModifier(attributes['dexterity'] ?? 10),
          imagePath: imagePath?.isNotEmpty == true ? imagePath : null,
          strength: attributes['strength'] ?? 10,
          dexterity: attributes['dexterity'] ?? 10,
          constitution: attributes['constitution'] ?? 10,
          intelligence: attributes['intelligence'] ?? 10,
          wisdom: attributes['wisdom'] ?? 10,
          charisma: attributes['charisma'] ?? 10,
          proficientSkills: proficientSkills.toList(),
          description: description?.trim(),
          attackList: attackList ?? [],
          inventory: inventory ?? [],
          gold: gold,
          silver: 0.0,
          copper: 0.0,
          sourceType: 'custom',
          isFavorite: false,
          version: '1.0',
        );

        await _dbHelper.insertPlayerCharacter(pc);
        return id;
      });
      return ServiceResult<String>.success(characterId, operation: 'createPlayerCharacter');
    } catch (e) {
      return ServiceResult<String>.unexpectedError(e, operation: 'createPlayerCharacter');
    }
  }

  /// Aktualisiert einen existierenden Player Character
  Future<ServiceResult<void>> updatePlayerCharacter(PlayerCharacter character) async {
    try {
      await performServiceOperation('updatePlayerCharacter', () async {
        // Prüfe ob Character existiert
        final existing = await _dbHelper.getPlayerCharacterById(character.id);
        if (existing == null) {
          throw ResourceNotFoundException.forId(
            'PlayerCharacter',
            character.id,
            operation: 'updatePlayerCharacter',
          );
        }

        // Validierung
        validateCharacterData(
          name: character.name,
          playerName: character.playerName,
          className: character.className,
          raceName: character.raceName,
          level: character.level,
          attributes: {
            'strength': character.strength,
            'dexterity': character.dexterity,
            'constitution': character.constitution,
            'intelligence': character.intelligence,
            'wisdom': character.wisdom,
            'charisma': character.charisma,
          },
        );

        await _dbHelper.updatePlayerCharacter(character);
      });
      return ServiceResult<void>.success(null, operation: 'updatePlayerCharacter');
    } catch (e) {
      return ServiceResult<void>.unexpectedError(e, operation: 'updatePlayerCharacter');
    }
  }

  /// Erstellt eine neue Kreatur/NPC mit voller Validierung
  Future<ServiceResult<String>> createCreature({
    required String name,
    required Map<String, int> attributes,
    required String size,
    required String type,
    String? subtype,
    required String alignment,
    required int challengeRating,
    String? description,
    String? attacks,
    String? specialAbilities,
    String? legendaryActions,
    List<Attack>? attackList,
    List<InventoryItem>? inventory,
    double gold = 0.0,
    String? speed,
    int? maxHp,
    int? armorClass,
  }) async {
    try {
      final creatureId = await performServiceOperation('createCreature', () async {
        // Validierung
        validateCreatureData(
          name: name,
          attributes: attributes,
          challengeRating: challengeRating,
        );

        final id = _uuidService.generateId();
        final conScore = attributes['constitution'] ?? 10;
        final calculatedMaxHp = maxHp ?? calculateMonsterHp(conScore, challengeRating);

        final creature = Creature(
          id: id,
          name: name.trim(),
          maxHp: calculatedMaxHp,
          currentHp: calculatedMaxHp,
          armorClass: armorClass ?? calculateBaseAC(attributes['dexterity'] ?? 10),
          speed: speed ?? '30ft',
          attacks: attacks?.trim() ?? '',
          initiativeBonus: calculateModifier(attributes['dexterity'] ?? 10),
          strength: attributes['strength'] ?? 10,
          dexterity: attributes['dexterity'] ?? 10,
          constitution: attributes['constitution'] ?? 10,
          intelligence: attributes['intelligence'] ?? 10,
          wisdom: attributes['wisdom'] ?? 10,
          charisma: attributes['charisma'] ?? 10,
          gold: gold,
          silver: 0.0,
          copper: 0.0,
          size: size,
          type: type,
          subtype: subtype?.isNotEmpty == true ? subtype : null,
          alignment: alignment.isNotEmpty ? alignment : 'True Neutral',
          challengeRating: challengeRating,
          specialAbilities: specialAbilities?.trim(),
          legendaryActions: legendaryActions?.trim(),
          description: description?.trim(),
          isCustom: true,
          sourceType: 'custom',
          attackList: attackList ?? [],
          inventory: const [],
        );

        await _dbHelper.insertCreature(creature);
        return id;
      });
      return ServiceResult<String>.success(creatureId, operation: 'createCreature');
    } catch (e) {
      return ServiceResult<String>.unexpectedError(e, operation: 'createCreature');
    }
  }

  /// Aktualisiert eine existierende Kreatur
  Future<ServiceResult<void>> updateCreature(Creature creature) async {
    try {
      await performServiceOperation('updateCreature', () async {
        // Prüfe ob Kreatur existiert
        final existing = await _dbHelper.getCreatureById(creature.id);
        if (existing == null) {
          throw ResourceNotFoundException.forId(
            'Creature',
            creature.id,
            operation: 'updateCreature',
          );
        }

        validateCreatureData(
          name: creature.name,
          attributes: {
            'strength': creature.strength,
            'dexterity': creature.dexterity,
            'constitution': creature.constitution,
            'intelligence': creature.intelligence,
            'wisdom': creature.wisdom,
            'charisma': creature.charisma,
          },
          challengeRating: creature.challengeRating ?? 0,
        );

        await _dbHelper.updateCreature(creature);
      });
      return ServiceResult<void>.success(null, operation: 'updateCreature');
    } catch (e) {
      return ServiceResult<void>.unexpectedError(e, operation: 'updateCreature');
    }
  }

  // ============================================================================
  // ATTACK MANAGEMENT
  // ============================================================================

  /// Validiert und formatiert Angriffsliste
  Future<ServiceResult<List<Attack>>> processAttacks(
    List<Attack> attacks, 
    Map<String, int> attributes
  ) async {
    try {
      final result = await performServiceOperation('processAttacks', () async {
        return attacks.map((attack) {
          // Automatische Bonus-Berechnung wenn nicht gesetzt
          final abilityScore = attributes[attack.abilityUsed ?? 'strength'] ?? 10;
          final abilityModifier = calculateModifier(abilityScore);
          
          return attack.copyWith(
            attackBonus: attack.attackBonus ?? abilityModifier,
          );
        }).toList();
      });
      return ServiceResult<List<Attack>>.success(result, operation: 'processAttacks');
    } catch (e) {
      return ServiceResult<List<Attack>>.unexpectedError(e, operation: 'processAttacks');
    }
  }

  /// Konvertiert alte String-basierte Angriffe zu neuen Attack-Objekten
  Future<ServiceResult<List<Attack>>> parseLegacyAttacks(
    String attacksString, 
    Map<String, int> attributes
  ) async {
    try {
      final result = await performServiceOperation('parseLegacyAttacks', () async {
        // Nutze attack_parser_service für Legacy-Parser
        try {
          final attacks = AttackParserService.parseAttacksFromString(attacksString);
          // Füge IDs hinzu und berechne Boni basierend auf Attributen
          return attacks.map((attack) {
            final abilityScore = attributes[attack.abilityUsed ?? 'strength'] ?? 10;
            final abilityModifier = calculateModifier(abilityScore);
            
            return attack.copyWith(
              id: _uuidService.generateId(),
              attackBonus: attack.attackBonus ?? abilityModifier,
            );
          }).toList();
        } catch (e) {
          throw DataProcessingException(
            'Fehler beim Parsen der Angriffe: $e',
            operation: 'parseLegacyAttacks',
          );
        }
      });
      return ServiceResult<List<Attack>>.success(result, operation: 'parseLegacyAttacks');
    } catch (e) {
      return ServiceResult<List<Attack>>.unexpectedError(e, operation: 'parseLegacyAttacks');
    }
  }

  // ============================================================================
  // INVENTORY CONVERSION HELPERS
  // ============================================================================

  /// Konvertiert InventoryItem Liste zu DisplayInventoryItem Liste
  List<InventoryItem> convertInventoryItems(List<InventoryItem> inventoryItems) {
    // Für jetzt einfach die InventoryItems zurückgeben
    // TODO: Implementiere DisplayInventoryItem Konvertierung wenn benötigt
    return inventoryItems;
  }

  // ============================================================================
  // IMPORT HELPERS
  // ============================================================================

  /// Importiert Daten von Official Monster
  Future<ServiceResult<String>> importFromOfficialMonster(
    String officialMonsterId, 
    String campaignId
  ) async {
    // TODO: Implementiere Official Monster Import
    // Muss mit bestehenden Services integriert werden
    return ServiceResult<String>.businessError(
      BusinessException(
        'Official Monster import not implemented yet',
        operation: 'importFromOfficialMonster',
      ),
      operation: 'importFromOfficialMonster',
    );
  }

  /// Dupliziert einen existierenden Character
  Future<ServiceResult<String>> duplicateCharacter(
    String characterId, 
    String newName
  ) async {
    try {
      final newCharacterId = await performServiceOperation('duplicateCharacter', () async {
        // Hole den Original-Character aus der Datenbank
        final originalCharacter = await _dbHelper.getPlayerCharacterById(characterId);
        if (originalCharacter == null) {
          throw ResourceNotFoundException.forId(
            'PlayerCharacter',
            characterId,
            operation: 'duplicateCharacter',
          );
        }

        // Erstelle neue ID und passe Namen an
        final id = _uuidService.generateId();
        final duplicatedCharacter = PlayerCharacter(
          id: id,
          campaignId: originalCharacter.campaignId,
          name: newName.trim(),
          playerName: originalCharacter.playerName,
          className: originalCharacter.className,
          raceName: originalCharacter.raceName,
          level: originalCharacter.level,
          maxHp: originalCharacter.maxHp,
          armorClass: originalCharacter.armorClass,
          initiativeBonus: originalCharacter.initiativeBonus,
          imagePath: originalCharacter.imagePath,
          strength: originalCharacter.strength,
          dexterity: originalCharacter.dexterity,
          constitution: originalCharacter.constitution,
          intelligence: originalCharacter.intelligence,
          wisdom: originalCharacter.wisdom,
          charisma: originalCharacter.charisma,
          proficientSkills: List<String>.from(originalCharacter.proficientSkills),
          description: originalCharacter.description,
          attackList: List<Attack>.from(originalCharacter.attackList),
          inventory: List<InventoryItem>.from(originalCharacter.inventory),
          gold: originalCharacter.gold,
          silver: originalCharacter.silver,
          copper: originalCharacter.copper,
          sourceType: 'custom',
          isFavorite: false,
          version: '1.0',
        );

        await _dbHelper.insertPlayerCharacter(duplicatedCharacter);
        return id;
      });
      return ServiceResult<String>.success(newCharacterId, operation: 'duplicateCharacter');
    } catch (e) {
      return ServiceResult<String>.unexpectedError(e, operation: 'duplicateCharacter');
    }
  }

  // ============================================================================
  // STATIC VALIDATION HELPERS
  // ============================================================================

  /// Validiert Character-Daten
  static void validateCharacterData({
    required String name,
    required String playerName,
    required String className,
    required String raceName,
    required int level,
    required Map<String, int> attributes,
  }) {
    if (name.trim().isEmpty) {
      throw ValidationException(
        'Character-Name ist erforderlich',
        operation: 'validateCharacterData',
      );
    }
    
    if (playerName.trim().isEmpty) {
      throw ValidationException(
        'Spieler-Name ist erforderlich',
        operation: 'validateCharacterData',
      );
    }
    
    if (className.trim().isEmpty) {
      throw ValidationException(
        'Klasse ist erforderlich',
        operation: 'validateCharacterData',
      );
    }
    
    if (raceName.trim().isEmpty) {
      throw ValidationException(
        'Volk ist erforderlich',
        operation: 'validateCharacterData',
      );
    }
    
    if (level < 1 || level > 20) {
      throw ValidationException(
        'Level muss zwischen 1 und 20 liegen',
        operation: 'validateCharacterData',
      );
    }
    
    validateAttributes(attributes);
  }

  /// Validiert Kreatur-Daten
  static void validateCreatureData({
    required String name,
    required Map<String, int> attributes,
    required int challengeRating,
  }) {
    if (name.trim().isEmpty) {
      throw ValidationException(
        'Kreatur-Name ist erforderlich',
        operation: 'validateCreatureData',
      );
    }
    
    if (challengeRating < 0 || challengeRating > 30) {
      throw ValidationException(
        'Herausforderungs-Rating muss zwischen 0 und 30 liegen',
        operation: 'validateCreatureData',
      );
    }
    
    validateAttributes(attributes);
  }

  /// Validiert Attribute-Werte
  static void validateAttributes(Map<String, int> attributes) {
    final requiredAttributes = [
      'strength', 'dexterity', 'constitution', 
      'intelligence', 'wisdom', 'charisma'
    ];
    
    for (final attr in requiredAttributes) {
      final value = attributes[attr] ?? 0;
      if (value < 1 || value > 30) {
        throw ValidationException(
          '$attr muss zwischen 1 und 30 liegen (aktuell: $value)',
          operation: 'validateAttributes',
        );
      }
    }
  }

  // ============================================================================
  // STATIC CALCULATION HELPERS
  // ============================================================================

  /// Berechnet D&D Modifier: (score - 10) ~/ 2
  static int calculateModifier(int score) => (score - 10) ~/ 2;

  /// Berechnet Basis-AC basierend auf Dexterity
  static int calculateBaseAC(int dexterity) => 10 + calculateModifier(dexterity);

  /// Berechnet maximale HP für Player Character
  static int calculateMaxHp(int constitution, int level) {
    final conMod = calculateModifier(constitution);
    return 8 + conMod + (level * conMod); // Simplified D&D 5e HP calculation
  }

  /// Berechnet HP für Monster basierend auf CR
  static int calculateMonsterHp(int constitution, int challengeRating) {
    final conMod = calculateModifier(constitution);
    
    // CR-based HP ranges (simplified D&D 5e)
    int baseHp;
    if (challengeRating <= 1) {
      baseHp = 15;
    } else if (challengeRating <= 4) {
      baseHp = 35;
    } else if (challengeRating <= 8) {
      baseHp = 75;
    } else if (challengeRating <= 12) {
      baseHp = 115;
    } else if (challengeRating <= 16) {
      baseHp = 180;
    } else {
      baseHp = 250;
    }
    
    return baseHp + (conMod * challengeRating);
  }

  /// Prüft ob ein Character gültige Attribute hat
  static bool hasValidAttributes(Map<String, int> attributes) {
    try {
      validateAttributes(attributes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Prüft ob ein Character gültige Daten hat
  static bool hasValidCharacterData({
    required String name,
    required String playerName,
    required String className,
    required String raceName,
    required int level,
    required Map<String, int> attributes,
  }) {
    try {
      validateCharacterData(
        name: name,
        playerName: playerName,
        className: className,
        raceName: raceName,
        level: level,
        attributes: attributes,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Formatiert Character für Anzeige
  static String formatCharacter(PlayerCharacter character) {
    final buffer = StringBuffer();
    buffer.writeln('Character: ${character.name}');
    buffer.writeln('  Player: ${character.playerName}');
    buffer.writeln('  Class: ${character.className} ${character.raceName}');
    buffer.writeln('  Level: ${character.level}');
    buffer.writeln('  HP: ${character.maxHp}');
    buffer.writeln('  AC: ${character.armorClass}');
    buffer.writeln('  Initiative: ${character.initiativeBonus}');
    buffer.writeln('  Gold: ${character.gold}');
    
    if (character.description?.isNotEmpty == true) {
      buffer.writeln('  Description: ${character.description}');
    }
    
    return buffer.toString();
  }

  /// Formatiert Creature für Anzeige
  static String formatCreature(Creature creature) {
    final buffer = StringBuffer();
    buffer.writeln('Creature: ${creature.name}');
    buffer.writeln('  Type: ${creature.type} ${creature.subtype ?? ''}');
    buffer.writeln('  Size: ${creature.size}');
    buffer.writeln('  Alignment: ${creature.alignment}');
    buffer.writeln('  CR: ${creature.challengeRating}');
    buffer.writeln('  HP: ${creature.currentHp}/${creature.maxHp}');
    buffer.writeln('  AC: ${creature.armorClass}');
    buffer.writeln('  Initiative: ${creature.initiativeBonus}');
    buffer.writeln('  Speed: ${creature.speed}');
    buffer.writeln('  Gold: ${creature.gold}');
    
    if (creature.description?.isNotEmpty == true) {
      buffer.writeln('  Description: ${creature.description}');
    }
    
    return buffer.toString();
  }
}
