// lib/models/player_character.dart
import '../services/uuid_service.dart';
import '../services/player_character_service.dart';
import 'inventory_item.dart';
import 'attack.dart';
import '../utils/model_parsing_helper.dart';

/// Reines Datenmodell für Player Characters
class PlayerCharacter {
  final String id;
  final String campaignId;
  final String name;
  final String playerName;
  final String className;
  final String raceName;
  final int level;
  final int maxHp;
  final int armorClass;
  final int initiativeBonus;
  final String? imagePath;
  
  // Die 6 Hauptattribute
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  
  // Fertigkeiten
  final List<String> proficientSkills;
  
  // D&D-Klassifikation
  final String? size;
  final String? type;
  final String? subtype;
  final String? alignment;
  
  // Beschreibung und Fähigkeiten
  final String? description;
  final String? specialAbilities;
  final String? attacks;  // Legacy String
  
  // Strukturierte Angriffsliste
  final List<Attack> attackList;
  
  // Inventar und Währung
  final List<InventoryItem> inventory;
  final double gold;
  final double silver;
  final double copper;
  
  // Erweiterte Felder für Unified System
  final String sourceType;
  final String? sourceId;
  final bool isFavorite;
  final String version;

  const PlayerCharacter({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.playerName,
    required this.className,
    required this.raceName,
    required this.level,
    required this.maxHp,
    required this.armorClass,
    required this.initiativeBonus,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.proficientSkills,
    required this.attackList,
    required this.inventory,
    required this.gold,
    required this.silver,
    required this.copper,
    required this.sourceType,
    required this.version,
    this.imagePath,
    this.size,
    this.type,
    this.subtype,
    this.alignment,
    this.description,
    this.specialAbilities,
    this.attacks,
    this.sourceId,
    this.isFavorite = false,
  });

  /// Factory für neuen Player Character
  factory PlayerCharacter.create({
    required String campaignId,
    required String name,
    required String playerName,
    required String className,
    required String raceName,
    int level = 1,
    int maxHp = 10,
    int armorClass = 10,
    int initiativeBonus = 0,
    int strength = 10,
    int dexterity = 10,
    int constitution = 10,
    int intelligence = 10,
    int wisdom = 10,
    int charisma = 10,
    List<String>? proficientSkills,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    String? description,
    String? specialAbilities,
    String attacks = '',
    List<Attack>? attackList,
    List<InventoryItem>? inventory,
    double gold = 0.0,
    double silver = 0.0,
    double copper = 0.0,
    String sourceType = 'custom',
    String? sourceId,
    String version = '1.0',
    String? imagePath,
    bool isFavorite = false,
  }) {
    return PlayerCharacter(
      id: UuidService().generateId(),
      campaignId: campaignId,
      name: name,
      playerName: playerName,
      className: className,
      raceName: raceName,
      level: level,
      maxHp: maxHp,
      armorClass: armorClass,
      initiativeBonus: initiativeBonus,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      charisma: charisma,
      proficientSkills: proficientSkills ?? [],
      size: size,
      type: type,
      subtype: subtype,
      alignment: alignment,
      description: description,
      specialAbilities: specialAbilities,
      attacks: attacks,
      attackList: attackList ?? [],
      inventory: inventory ?? [],
      gold: gold,
      silver: silver,
      copper: copper,
      sourceType: sourceType,
      sourceId: sourceId,
      version: version,
      imagePath: imagePath,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'name': name,
      'player_name': playerName,
      'class_name': className,
      'race_name': raceName,
      'level': level,
      'max_hp': maxHp,
      'armor_class': armorClass,
      'initiative_bonus': initiativeBonus,
      'image_path': imagePath,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'proficient_skills': PlayerCharacterService.serializeSkills(proficientSkills),
      'size': size,
      'type': type,
      'subtype': subtype,
      'alignment': alignment,
      'description': description,
      'special_abilities': specialAbilities,
      'attacks': attacks,
      'attack_list': PlayerCharacterService.serializeAttackList(attackList),
      'inventory': PlayerCharacterService.serializeInventory(inventory),
      'gold': gold,
      'silver': silver,
      'copper': copper,
      'source_type': sourceType,
      'source_id': sourceId,
      'is_favorite': isFavorite,
      'version': version,
    };
  }

  factory PlayerCharacter.fromMap(Map<String, dynamic> map) {
    return PlayerCharacter(
      id: ModelParsingHelper.safeId(map, 'id'),
      campaignId: ModelParsingHelper.safeString(map, 'campaign_id', ''),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbenannt'),
      playerName: ModelParsingHelper.safeString(map, 'player_name', 'Unbekannt'),
      className: ModelParsingHelper.safeString(map, 'class_name', 'Unbekannt'),
      raceName: ModelParsingHelper.safeString(map, 'race_name', 'Mensch'),
      level: ModelParsingHelper.safeInt(map, 'level', 1),
      maxHp: ModelParsingHelper.safeInt(map, 'max_hp', 10),
      armorClass: ModelParsingHelper.safeInt(map, 'armor_class', 10),
      initiativeBonus: ModelParsingHelper.safeInt(map, 'initiative_bonus', 0),
      imagePath: ModelParsingHelper.safeStringOrNull(map, 'image_path', null),
      strength: ModelParsingHelper.safeInt(map, 'strength', 10),
      dexterity: ModelParsingHelper.safeInt(map, 'dexterity', 10),
      constitution: ModelParsingHelper.safeInt(map, 'constitution', 10),
      intelligence: ModelParsingHelper.safeInt(map, 'intelligence', 10),
      wisdom: ModelParsingHelper.safeInt(map, 'wisdom', 10),
      charisma: ModelParsingHelper.safeInt(map, 'charisma', 10),
      proficientSkills: PlayerCharacterService.deserializeSkills((map as Map<String, dynamic>)['proficient_skills']?.toString()) ?? [],
      size: ModelParsingHelper.safeStringOrNull(map, 'size', null),
      type: ModelParsingHelper.safeStringOrNull(map, 'type', null),
      subtype: ModelParsingHelper.safeStringOrNull(map, 'subtype', null),
      alignment: ModelParsingHelper.safeStringOrNull(map, 'alignment', null),
      description: ModelParsingHelper.safeStringOrNull(map, 'description', null),
      specialAbilities: ModelParsingHelper.safeStringOrNull(map, 'special_abilities', null),
      attacks: (map as Map<String, dynamic>)['attacks']?.toString(),
      attackList: PlayerCharacterService.deserializeAttackList((map as Map<String, dynamic>)['attack_list']) ?? [],
      inventory: PlayerCharacterService.deserializeInventory((map as Map<String, dynamic>)['inventory']) ?? [],
      gold: ModelParsingHelper.safeDouble(map, 'gold', 0.0),
      silver: ModelParsingHelper.safeDouble(map, 'silver', 0.0),
      copper: ModelParsingHelper.safeDouble(map, 'copper', 0.0),
      sourceType: ModelParsingHelper.safeString(map, 'source_type', 'custom'),
      sourceId: ModelParsingHelper.safeStringOrNull(map, 'source_id', null),
      isFavorite: ModelParsingHelper.safeBool(map, 'is_favorite', false),
      version: ModelParsingHelper.safeString(map, 'version', '1.0'),
    );
  }

  /// Erstellt eine Kopie mit aktualisierten Werten
  PlayerCharacter copyWith({
    String? id,
    String? campaignId,
    String? name,
    String? playerName,
    String? className,
    String? raceName,
    int? level,
    int? maxHp,
    int? armorClass,
    int? initiativeBonus,
    String? imagePath,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
    List<String>? proficientSkills,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    String? description,
    String? specialAbilities,
    String? attacks,
    List<Attack>? attackList,
    List<InventoryItem>? inventory,
    double? gold,
    double? silver,
    double? copper,
    String? sourceType,
    String? sourceId,
    bool? isFavorite,
    String? version,
  }) {
    return PlayerCharacter(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      name: name ?? this.name,
      playerName: playerName ?? this.playerName,
      className: className ?? this.className,
      raceName: raceName ?? this.raceName,
      level: level ?? this.level,
      maxHp: maxHp ?? this.maxHp,
      armorClass: armorClass ?? this.armorClass,
      initiativeBonus: initiativeBonus ?? this.initiativeBonus,
      imagePath: imagePath ?? this.imagePath,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      constitution: constitution ?? this.constitution,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      charisma: charisma ?? this.charisma,
      proficientSkills: proficientSkills ?? this.proficientSkills,
      size: size ?? this.size,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      alignment: alignment ?? this.alignment,
      description: description ?? this.description,
      specialAbilities: specialAbilities ?? this.specialAbilities,
      attacks: attacks ?? this.attacks,
      attackList: attackList ?? this.attackList,
      inventory: inventory ?? this.inventory,
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      copper: copper ?? this.copper,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isFavorite: isFavorite ?? this.isFavorite,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerCharacter &&
        other.id == id &&
        other.campaignId == campaignId &&
        other.name == name &&
        other.playerName == playerName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        campaignId.hashCode ^
        name.hashCode ^
        playerName.hashCode ^
        className.hashCode ^
        raceName.hashCode;
  }

  @override
  String toString() {
    return 'PlayerCharacter(id: $id, name: $name, player: $playerName, class: $className, race: $raceName, level: $level)';
  }
}
