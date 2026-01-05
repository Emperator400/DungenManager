import 'condition.dart';
import 'attack.dart';
import '../services/creature_data_service.dart';
import '../services/creature_factory_service.dart';
import '../services/creature_helper_service.dart';
import '../utils/model_parsing_helper.dart';

/// Repräsentiert ein Wesen (Monster, NPC, Spieler)
class Creature {
  final String id;
  final String name;
  final int maxHp;
  final int armorClass;
  final String speed;
  final String attacks; // Legacy String für Abwärtskompatibilität
  final int initiativeBonus;
  
  // Temporäre Kampf-Werte
  int currentHp;
  int? initiative;
  List<Condition> conditions;
  final bool isPlayer;

  // Felder für die 6 Hauptattribute
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  // Inventar für Spieler-Charaktere
  final List<Map<String, dynamic>> inventory;
  
  // Gold und Währung für NPCs/Monster
  final double gold;
  final double silver;
  final double copper;

  // Integration mit offiziellen D&D-Daten
  final String? officialMonsterId; // Verknüpfung zu offiziellem Monster
  final String? officialSpellIds;   // IDs der bekannten Zauber (kommagetrennt)
  final String? officialItemIds;    // IDs der bekannten Gegenstände (kommagetrennt)
  final String? size;              // Größe (Tiny, Small, Medium, Large, Huge, Gargantuan)
  final String? type;              // Typ (Humanoid, Beast, Dragon, etc.)
  final String? subtype;           // Subtyp
  final String? alignment;         // Gesinnung
  final int? challengeRating;      // Schwierigkeitsgrad
  final String? specialAbilities;  // Spezielle Fähigkeiten
  final String? legendaryActions;  // Legendäre Aktionen
  final bool isCustom;            // Ob es ein benutzerdefiniertes Monster ist
  final String? description;       // Beschreibung des Monsters/NPCs

  // Strukturierte Angriffsliste
  final List<Attack> attackList;   // Neue strukturierte Angriffe

  // Felder für Unified Bestiarum
  final String sourceType;        // 'custom', 'official', 'hybrid'
  final String? sourceId;         // Verweis auf Original-Quelle
  final bool isFavorite;          // Ob das Monster favorisiert ist
  final String version;           // Version des Monsters

  Creature({
    required this.id,
    required this.name,
    required this.maxHp,
    int? currentHp, // Optional parameter
    this.armorClass = 10,
    this.speed = "30ft",
    this.attacks = "",
    this.initiativeBonus = 0,
    this.isPlayer = false,
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
    this.inventory = const [],
    this.gold = 0.0,
    this.silver = 0.0,
    this.copper = 0.0,
    this.officialMonsterId,
    this.officialSpellIds,
    this.officialItemIds,
    this.size,
    this.type,
    this.subtype,
    this.alignment,
    this.challengeRating,
    this.specialAbilities,
    this.legendaryActions,
    this.isCustom = true,
    this.description,
    this.attackList = const [],
    this.sourceType = 'custom',
    this.sourceId,
    this.isFavorite = false,
    this.version = '1.0',
    this.conditions = const [],
    this.initiative,
  }) : currentHp = currentHp ?? maxHp; // Auto-set auf maxHp wenn nicht gesetzt

  /// Konvertiert das Creature zu einer Datenbank-Map (Legacy)
  Map<String, dynamic> toMap() {
    return toDatabaseMap();
  }

  /// Konvertiert das Creature zu einer Datenbank-Map (Neu)
  Map<String, dynamic> toDatabaseMap() {
    final attackListResult = CreatureDataService.serializeAttackList(attackList);
    final inventoryResult = CreatureDataService.serializeInventory(inventory);
    
    return {
      'id': id,
      'name': name,
      'max_hp': maxHp,
      'armor_class': armorClass,
      'speed': speed,
      'attacks': attacks,
      'initiative_bonus': initiativeBonus,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'is_player': isPlayer,
      'gold': gold,
      'silver': silver,
      'copper': copper,
      'official_monster_id': officialMonsterId,
      'official_spell_ids': officialSpellIds,
      'official_item_ids': officialItemIds,
      'size': size,
      'type': type,
      'subtype': subtype,
      'alignment': alignment,
      'challenge_rating': challengeRating,
      'special_abilities': specialAbilities,
      'legendary_actions': legendaryActions,
      'is_custom': isCustom,
      'description': description,
      'attack_list': attackListResult.isSuccess ? attackListResult.data : '[]',
      'inventory': inventoryResult.isSuccess ? inventoryResult.data : '[]',
      'source_type': sourceType,
      'source_id': sourceId,
      'is_favorite': isFavorite,
      'version': version,
      'current_hp': currentHp,
      'initiative': initiative,
      'conditions': conditions.map((c) => c.toString()).join(','),
    };
  }

  /// Factory für Datenbank-Map mit sicherem Parsing (Legacy)
  factory Creature.fromMap(Map<String, dynamic> map) {
    return Creature.fromDatabaseMap(map);
  }

  /// Factory für Datenbank-Map mit sicherem Parsing (Neu)
  factory Creature.fromDatabaseMap(Map<String, dynamic> map) {
    final attackListResult = CreatureDataService.parseAttackList(map['attack_list']);
    final inventoryResult = CreatureDataService.parseInventory(map['inventory']);
    
    return Creature(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', ''),
      maxHp: ModelParsingHelper.safeInt(map, 'max_hp', 0),
      currentHp: ModelParsingHelper.safeInt(map, 'current_hp', 0),
      armorClass: ModelParsingHelper.safeInt(map, 'armor_class', 10),
      speed: ModelParsingHelper.safeString(map, 'speed', "30ft"),
      attacks: ModelParsingHelper.safeString(map, 'attacks', ""),
      initiativeBonus: ModelParsingHelper.safeInt(map, 'initiative_bonus', 0),
      strength: ModelParsingHelper.safeInt(map, 'strength', 10),
      dexterity: ModelParsingHelper.safeInt(map, 'dexterity', 10),
      constitution: ModelParsingHelper.safeInt(map, 'constitution', 10),
      intelligence: ModelParsingHelper.safeInt(map, 'intelligence', 10),
      wisdom: ModelParsingHelper.safeInt(map, 'wisdom', 10),
      charisma: ModelParsingHelper.safeInt(map, 'charisma', 10),
      isPlayer: ModelParsingHelper.safeBool(map, 'is_player', false),
      inventory: inventoryResult.isSuccess ? inventoryResult.data! : (map['inventory'] as List<Object>?)?.cast<Map<String, dynamic>>() ?? const [],
      gold: ModelParsingHelper.safeDouble(map, 'gold', 0.0),
      silver: ModelParsingHelper.safeDouble(map, 'silver', 0.0),
      copper: ModelParsingHelper.safeDouble(map, 'copper', 0.0),
      officialMonsterId: ModelParsingHelper.safeStringOrNull(map, 'official_monster_id', null),
      officialSpellIds: ModelParsingHelper.safeStringOrNull(map, 'official_spell_ids', null),
      officialItemIds: ModelParsingHelper.safeStringOrNull(map, 'official_item_ids', null),
      size: ModelParsingHelper.safeStringOrNull(map, 'size', null),
      type: ModelParsingHelper.safeStringOrNull(map, 'type', null),
      subtype: ModelParsingHelper.safeStringOrNull(map, 'subtype', null),
      alignment: ModelParsingHelper.safeStringOrNull(map, 'alignment', null),
      challengeRating: ModelParsingHelper.safeIntOrNull(map, 'challenge_rating', null),
      specialAbilities: ModelParsingHelper.safeStringOrNull(map, 'special_abilities', null),
      legendaryActions: ModelParsingHelper.safeStringOrNull(map, 'legendary_actions', null),
      isCustom: ModelParsingHelper.safeBool(map, 'is_custom', true),
      description: ModelParsingHelper.safeStringOrNull(map, 'description', null),
      attackList: attackListResult.isSuccess ? attackListResult.data! : const [],
      sourceType: ModelParsingHelper.safeString(map, 'source_type', 'custom'),
      sourceId: ModelParsingHelper.safeStringOrNull(map, 'source_id', null),
      isFavorite: ModelParsingHelper.safeBool(map, 'is_favorite', false),
      version: ModelParsingHelper.safeString(map, 'version', '1.0'),
      initiative: ModelParsingHelper.safeIntOrNull(map, 'initiative', null),
      conditions: _parseConditions(map['conditions']),
    );
  }

  /// Hilfsmethode zum Parsen von Conditions aus String
  static List<Condition> _parseConditions(dynamic conditionsData) {
    if (conditionsData == null || conditionsData.toString().isEmpty) {
      return [];
    }
    
    final conditionsString = conditionsData.toString();
    if (conditionsString.isEmpty) return [];
    
    return conditionsString
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => _parseCondition(s.trim()))
        .where((condition) => condition != null)
        .cast<Condition>()
        .toList();
  }

  /// Hilfsmethode zum Parsen einzelner Condition
  static Condition? _parseCondition(String conditionString) {
    try {
      return Condition.values.firstWhere(
        (condition) => condition.toString() == 'Condition.$conditionString',
        orElse: () => Condition.Blinded, // Fallback
      );
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'Creature(name: $name, HP: $currentHp/$maxHp, AC: $armorClass)';
  }
}

// Legacy Extensions für Abwärtskompatibilität
extension CreatureExtension on Creature {
  /// Legacy-Factory-Methode für offizielle Monster
  /// @deprecated Verwende stattdessen CreatureFactoryService.fromOfficialMonster()
  static Creature fromOfficialMonster({
    required String officialMonsterId,
    required String name,
    required int maxHp,
    required int armorClass,
    required String speed,
    required int strength,
    required int dexterity,
    required int constitution,
    required int intelligence,
    required int wisdom,
    required int charisma,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    int? challengeRating,
    String? specialAbilities,
    String? legendaryActions,
    String? description,
    String? attacks,
    List<Attack>? attackList,
  }) {
    // Importiere: '../services/creature_factory_service.dart'
    // Verwende: CreatureFactoryService.fromOfficialMonster()
    return CreatureFactoryService.fromOfficialMonster(
      officialMonsterId: officialMonsterId,
      name: name,
      maxHp: maxHp,
      armorClass: armorClass,
      speed: speed,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      charisma: charisma,
      size: size,
      type: type,
      subtype: subtype,
      alignment: alignment,
      challengeRating: challengeRating,
      specialAbilities: specialAbilities,
      legendaryActions: legendaryActions,
      description: description,
      attacks: attacks,
      attackList: attackList,
    );
  }

  /// Legacy-CopyWith-Methode
  /// @deprecated Verwende stattdessen CreatureHelperService.copyWith()
  Creature copyWith({
    String? name,
    int? maxHp,
    int? currentHp,
    int? armorClass,
    String? speed,
    String? attacks,
    int? initiativeBonus,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
    String? officialMonsterId,
    String? officialSpellIds,
    String? officialItemIds,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    int? challengeRating,
    String? specialAbilities,
    String? legendaryActions,
    bool? isCustom,
    String? description,
    List<Attack>? attackList,
    String? sourceType,
    String? sourceId,
    bool? isFavorite,
    String? version,
  }) {
    // Importiere: '../services/creature_helper_service.dart'
    // Verwende: CreatureHelperService.copyWith()
    return CreatureHelperService.copyWith(
      this,
      name: name,
      maxHp: maxHp,
      currentHp: currentHp,
      armorClass: armorClass,
      speed: speed,
      attacks: attacks,
      initiativeBonus: initiativeBonus,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      charisma: charisma,
      officialMonsterId: officialMonsterId,
      officialSpellIds: officialSpellIds,
      officialItemIds: officialItemIds,
      size: size,
      type: type,
      subtype: subtype,
      alignment: alignment,
      challengeRating: challengeRating,
      specialAbilities: specialAbilities,
      legendaryActions: legendaryActions,
      isCustom: isCustom,
      description: description,
      attackList: attackList,
      sourceType: sourceType,
      sourceId: sourceId,
      isFavorite: isFavorite,
      version: version,
    );
  }

  /// Legacy-Helper für formatierte Angriffe
  /// @deprecated Verwende stattdessen CreatureHelperService.getFormattedAttacks()
  String get formattedAttacks {
    // Importiere: '../services/creature_helper_service.dart'
    // Verwende: CreatureHelperService.getFormattedAttacks()
    return CreatureHelperService.getFormattedAttacks(this);
  }
  
  /// Legacy-Helper für effektive Angriffe
  /// @deprecated Verwende stattdessen CreatureHelperService.getEffectiveAttacks()
  List<Attack> get effectiveAttacks {
    // Importiere: '../services/creature_helper_service.dart'
    // Verwende: CreatureHelperService.getEffectiveAttacks()
    return CreatureHelperService.getEffectiveAttacks(this);
  }
}
