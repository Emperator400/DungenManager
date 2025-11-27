import '../utils/model_parsing_helper.dart';
import '../services/monster_parser_service.dart';
import '../services/official_monster_import_service.dart';

/// Repräsentiert ein offizielles D&D 5e Monster
class OfficialMonster {
  final String id;
  final String name;
  final String size;
  final String type;
  final String? subtype;
  final String alignment;
  final String armorClass;
  final int hitPoints;
  final String hitDice;
  final String speed;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final List<String> savingThrows;
  final Map<String, int> skills;
  final List<String> damageVulnerabilities;
  final List<String> damageResistances;
  final List<String> damageImmunities;
  final List<String> conditionImmunities;
  final Map<String, String> senses;
  final String languages;
  final double challengeRating;
  final int xp;
  final List<MonsterAbility> specialAbilities;
  final List<MonsterAction> actions;
  final List<LegendaryAction>? legendaryActions;
  final List<LairAction>? lairActions;
  final String? description;
  final String source;
  final int page;
  final bool isCustom;
  final String? version;
  final Map<String, dynamic>? customData;

  const OfficialMonster({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    this.subtype,
    required this.alignment,
    required this.armorClass,
    required this.hitPoints,
    required this.hitDice,
    required this.speed,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    this.savingThrows = const [],
    this.skills = const {},
    this.damageVulnerabilities = const [],
    this.damageResistances = const [],
    this.damageImmunities = const [],
    this.conditionImmunities = const [],
    this.senses = const {},
    this.languages = '',
    required this.challengeRating,
    required this.xp,
    this.specialAbilities = const [],
    this.actions = const [],
    this.legendaryActions,
    this.lairActions,
    this.description,
    required this.source,
    this.page = 1,
    this.isCustom = false,
    this.version,
    this.customData,
  });

  /// Konvertierung für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'type': type,
      'subtype': subtype,
      'alignment': alignment,
      'armor_class': armorClass,
      'hit_points': hitPoints,
      'hit_dice': hitDice,
      'speed': speed,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'saving_throws': savingThrows.isNotEmpty ? savingThrows.join(',') : null,
      'skills': skills.isNotEmpty ? skills.entries.map((e) => '${e.key}:${e.value}').join(',') : null,
      'damage_vulnerabilities': damageVulnerabilities.isNotEmpty ? damageVulnerabilities.join(',') : null,
      'damage_resistances': damageResistances.isNotEmpty ? damageResistances.join(',') : null,
      'damage_immunities': damageImmunities.isNotEmpty ? damageImmunities.join(',') : null,
      'condition_immunities': conditionImmunities.isNotEmpty ? conditionImmunities.join(',') : null,
      'senses': senses.isNotEmpty ? senses.entries.map((e) => '${e.key}:${e.value}').join(',') : null,
      'languages': languages,
      'challenge_rating': challengeRating,
      'xp': xp,
      'special_abilities': specialAbilities.isNotEmpty ? specialAbilities.map((a) => a.toMap()).toList() : null,
      'actions': actions.isNotEmpty ? actions.map((a) => a.toMap()).toList() : null,
      'legendary_actions': legendaryActions?.map((a) => a.toMap()).toList(),
      'lair_actions': lairActions?.map((a) => a.toMap()).toList(),
      'description': description,
      'source': source,
      'page': page,
      'is_custom': isCustom ? 1 : 0,
      'version': version,
      'custom_data': customData,
    };
  }

  /// Erstellung aus Datenbank
  factory OfficialMonster.fromMap(Map<String, dynamic> map, [Map<String, dynamic>? context]) {
    return OfficialMonster(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', ''),
      size: ModelParsingHelper.safeString(map, 'size', ''),
      type: ModelParsingHelper.safeString(map, 'type', ''),
      subtype: ModelParsingHelper.safeStringOrNull(map, 'subtype', null),
      alignment: ModelParsingHelper.safeString(map, 'alignment', ''),
      armorClass: ModelParsingHelper.safeString(map, 'armor_class', ''),
      hitPoints: ModelParsingHelper.safeInt(map, 'hit_points', 0),
      hitDice: ModelParsingHelper.safeString(map, 'hit_dice', ''),
      speed: ModelParsingHelper.safeString(map, 'speed', ''),
      strength: ModelParsingHelper.safeInt(map, 'strength', 10),
      dexterity: ModelParsingHelper.safeInt(map, 'dexterity', 10),
      constitution: ModelParsingHelper.safeInt(map, 'constitution', 10),
      intelligence: ModelParsingHelper.safeInt(map, 'intelligence', 10),
      wisdom: ModelParsingHelper.safeInt(map, 'wisdom', 10),
      charisma: ModelParsingHelper.safeInt(map, 'charisma', 10),
      savingThrows: ModelParsingHelper.safeString(map, 'saving_throws', '').split(','),
      skills: MonsterParserService.parseSkills(map['skills']),
      damageVulnerabilities: ModelParsingHelper.safeString(map, 'damage_vulnerabilities', '').split(','),
      damageResistances: ModelParsingHelper.safeString(map, 'damage_resistances', '').split(','),
      damageImmunities: ModelParsingHelper.safeString(map, 'damage_immunities', '').split(','),
      conditionImmunities: ModelParsingHelper.safeString(map, 'condition_immunities', '').split(','),
      senses: MonsterParserService.parseSenses(map['senses']),
      languages: ModelParsingHelper.safeString(map, 'languages', ''),
      challengeRating: ModelParsingHelper.safeDouble(map, 'challenge_rating', 0.0),
      xp: ModelParsingHelper.safeInt(map, 'xp', 0),
      specialAbilities: MonsterParserService.parseAbilities(map['special_abilities']),
      actions: MonsterParserService.parseActions(map['actions']),
      legendaryActions: MonsterParserService.parseLegendaryActions(map['legendary_actions']),
      lairActions: MonsterParserService.parseLairActions(map['lair_actions']),
      description: ModelParsingHelper.safeStringOrNull(map, 'description', null),
      source: ModelParsingHelper.safeString(map, 'source', ''),
      page: ModelParsingHelper.safeInt(map, 'page', 1),
      isCustom: ModelParsingHelper.safeBool(map, 'is_custom', false),
      version: ModelParsingHelper.safeStringOrNull(map, 'version', null),
      customData: ModelParsingHelper.safeGet(map, 'custom_data', null),
    );
  }

  @override
  String toString() {
    return 'OfficialMonster(name: $name, CR: $challengeRating, Type: $type $subtype)';
  }
}

/// Spezielle Fähigkeit eines Monsters
class MonsterAbility {
  final String name;
  final String description;
  final int? usage;

  const MonsterAbility({
    required this.name,
    required this.description,
    this.usage,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'usage': usage,
    };
  }

  factory MonsterAbility.fromMap(Map<String, dynamic> map) {
    return MonsterAbility(
      name: ModelParsingHelper.safeString(map, 'name', 'Unknown Ability'),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      usage: ModelParsingHelper.safeIntOrNull(map, 'usage', null),
    );
  }

  factory MonsterAbility.from5eToolsJson(Map<String, dynamic> json) {
    return MonsterAbility(
      name: ModelParsingHelper.safeString(json, 'name', ''),
      description: json['entries'] is List ? (json['entries'] as List).join('\n') : ModelParsingHelper.safeString(json, 'text', ''),
      usage: ModelParsingHelper.safeIntOrNull(json, 'usage', null),
    );
  }

  @override
  String toString() => 'MonsterAbility(name: $name)';
}

/// Aktion eines Monsters
class MonsterAction {
  final String name;
  final String description;
  final String? attackBonus;
  final String? damage;
  final String? damageType;

  const MonsterAction({
    required this.name,
    required this.description,
    this.attackBonus,
    this.damage,
    this.damageType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'attack_bonus': attackBonus,
      'damage': damage,
      'damage_type': damageType,
    };
  }

  factory MonsterAction.fromMap(Map<String, dynamic> map) {
    return MonsterAction(
      name: ModelParsingHelper.safeString(map, 'name', 'Unknown Action'),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      attackBonus: ModelParsingHelper.safeStringOrNull(map, 'attack_bonus', null),
      damage: ModelParsingHelper.safeStringOrNull(map, 'damage', null),
      damageType: ModelParsingHelper.safeStringOrNull(map, 'damage_type', null),
    );
  }

  factory MonsterAction.from5eToolsJson(Map<String, dynamic> json) {
    final entries = json['entries'] ?? [];
    final description = entries is List ? (entries as List).join('\n') : entries.toString();
    
    String? attackBonus;
    String? damage;
    String? damageType;

    if (json['entries'] is List) {
      for (final entry in json['entries'] as List) {
        if (entry is Map<String, dynamic> && entry['type'] == 'attack') {
          attackBonus = ModelParsingHelper.safeStringOrNull(entry, 'attackBonus', null);
          damage = ModelParsingHelper.safeStringOrNull(entry, 'damage', null);
          damageType = ModelParsingHelper.safeStringOrNull(entry, 'damage_type', null);
        }
      }
    }

    return MonsterAction(
      name: ModelParsingHelper.safeString(json, 'name', ''),
      description: description,
      attackBonus: attackBonus,
      damage: damage,
      damageType: damageType,
    );
  }

  @override
  String toString() => 'MonsterAction(name: $name)';
}

/// Legendäre Aktion eines Monsters
class LegendaryAction {
  final String name;
  final String description;
  final int? cost;

  const LegendaryAction({
    required this.name,
    required this.description,
    this.cost = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'cost': cost,
    };
  }

  factory LegendaryAction.fromMap(Map<String, dynamic> map) {
    return LegendaryAction(
      name: ModelParsingHelper.safeString(map, 'name', 'Unknown Legendary Action'),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      cost: ModelParsingHelper.safeIntOrNull(map, 'cost', 1),
    );
  }

  factory LegendaryAction.from5eToolsJson(Map<String, dynamic> json) {
    return LegendaryAction(
      name: ModelParsingHelper.safeString(json, 'name', ''),
      description: json['entries'] is List ? (json['entries'] as List).join('\n') : ModelParsingHelper.safeString(json, 'text', ''),
      cost: ModelParsingHelper.safeIntOrNull(json, 'cost', 1),
    );
  }

  @override
  String toString() => 'LegendaryAction(name: $name)';
}

/// Höhlen-Aktion eines Monsters
class LairAction {
  final String name;
  final String description;

  const LairAction({
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  factory LairAction.fromMap(Map<String, dynamic> map) {
    return LairAction(
      name: ModelParsingHelper.safeString(map, 'name', 'Unknown Lair Action'),
      description: ModelParsingHelper.safeString(map, 'description', ''),
    );
  }

  factory LairAction.from5eToolsJson(Map<String, dynamic> json) {
    return LairAction(
      name: ModelParsingHelper.safeString(json, 'name', ''),
      description: json['entries'] is List ? (json['entries'] as List).join('\n') : ModelParsingHelper.safeString(json, 'text', ''),
    );
  }

  @override
  String toString() => 'LairAction(name: $name)';
}

// Legacy Extensions für Abwärtskompatibilität
extension OfficialMonsterExtension on OfficialMonster {
  /// Legacy-Methode für 5e.tools Import
  /// @deprecated Verwende stattdessen OfficialMonsterImportService.from5eToolsJson()
  static OfficialMonster from5eToolsJson(Map<String, dynamic> json) {
    // Importiere: '../services/official_monster_import_service.dart'
    // Verwende: OfficialMonsterImportService.from5eToolsJson(json)
    return OfficialMonsterImportService.from5eToolsJson(json);
  }
}
