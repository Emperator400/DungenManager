// lib/models/player_character.dart
import 'dart:convert';
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
  
  // Rettungswürfe (Saving Throws)
  final List<String> savingThrowProficiencies;
  
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
  
  // Equipment als Map für Datenbank-Speicherung
  final Map<String, String>? equipment;
  
  // D&D 5e spezifische Felder
  final int proficiencyBonus;
  final int speed;
  final int passivePerception;
  final String? spellSlots; // JSON-String für Spell-Slot-Verwaltung
  final int spellSaveDc;
  final int spellAttackBonus;

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
    this.equipment,
    this.proficiencyBonus = 2,
    this.speed = 30,
    this.passivePerception = 10,
    this.spellSlots,
    this.spellSaveDc = 8,
    this.spellAttackBonus = 0,
    this.savingThrowProficiencies = const [],
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
    List<String>? savingThrowProficiencies,
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
    Map<String, String>? equipment,
    int proficiencyBonus = 2,
    int speed = 30,
    int passivePerception = 10,
    String? spellSlots,
    int spellSaveDc = 8,
    int spellAttackBonus = 0,
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
      savingThrowProficiencies: savingThrowProficiencies ?? [],
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
      equipment: equipment,
      proficiencyBonus: proficiencyBonus,
      speed: speed,
      passivePerception: passivePerception,
      spellSlots: spellSlots,
      spellSaveDc: spellSaveDc,
      spellAttackBonus: spellAttackBonus,
    );
  }

  Map<String, dynamic> toMap() => toDatabaseMap();

  /// NEUE METHODE: Serialisiert für Datenbank mit konsistenten Feldnamen
  /// Diese Methode ersetzt zukünftig die Entity-Konvertierung
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'name': name,
      'player_name': playerName,
      'class_name': className,
      'race_name': raceName,
      'level': level,
      'max_hp': maxHp,
      'current_hp': maxHp, // Für zukünftige Verwendung
      'armor_class': armorClass,
      'initiative_bonus': initiativeBonus,
      'image_path': imagePath,
      
      // 6 Hauptattribute
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      
      // Komplexe Daten als JSON
      'proficient_skills': _serializeList(proficientSkills),
      'saving_throw_proficiencies': _serializeList(savingThrowProficiencies),
      'special_abilities': specialAbilities,
      'attacks': attacks,
      'attack_list': _serializeAttackList(attackList),
      'inventory': _serializeInventory(inventory),
      'equipment': _serializeEquipment(equipment),
      
      // D&D-Klassifikation
      'size': size,
      'type': type,
      'subtype': subtype,
      'alignment': alignment,
      'description': description,
      
      // Währung
      'gold': gold,
      'silver': silver,
      'copper': copper,
      
      // Metadaten
      'source_type': sourceType,
      'source_id': sourceId,
      'is_favorite': isFavorite ? 1 : 0,
      'version': version,
      
      // D&D 5e Felder
      'proficiency_bonus': proficiencyBonus,
      'speed': speed,
      'passive_perception': passivePerception,
      'spell_slots': spellSlots,
      'spell_save_dc': spellSaveDc,
      'spell_attack_bonus': spellAttackBonus,
      
      // Timestamps
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// NEUE METHODE: Deserialisiert von Datenbank mit konsistenten Feldnamen
  /// Diese Methode ersetzt zukünftig die Entity-Konvertierung
  factory PlayerCharacter.fromDatabaseMap(Map<String, dynamic> map) {
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
      
      // 6 Hauptattribute
      strength: ModelParsingHelper.safeInt(map, 'strength', 10),
      dexterity: ModelParsingHelper.safeInt(map, 'dexterity', 10),
      constitution: ModelParsingHelper.safeInt(map, 'constitution', 10),
      intelligence: ModelParsingHelper.safeInt(map, 'intelligence', 10),
      wisdom: ModelParsingHelper.safeInt(map, 'wisdom', 10),
      charisma: ModelParsingHelper.safeInt(map, 'charisma', 10),
      
      // Komplexe Daten
      proficientSkills: _deserializeList(map['proficient_skills'] as String?),
      savingThrowProficiencies: _deserializeList(map['saving_throw_proficiencies'] as String?),
      specialAbilities: ModelParsingHelper.safeStringOrNull(map, 'special_abilities', null),
      attacks: map['attacks']?.toString(),
      attackList: _deserializeAttackList(map['attack_list'] as String?),
      inventory: _deserializeInventory(map['inventory'] as String?),
      equipment: _deserializeEquipment(map['equipment'] as String?),
      
      // D&D-Klassifikation
      size: ModelParsingHelper.safeStringOrNull(map, 'size', null),
      type: ModelParsingHelper.safeStringOrNull(map, 'type', null),
      subtype: ModelParsingHelper.safeStringOrNull(map, 'subtype', null),
      alignment: ModelParsingHelper.safeStringOrNull(map, 'alignment', null),
      description: ModelParsingHelper.safeStringOrNull(map, 'description', null),
      
      // Währung
      gold: ModelParsingHelper.safeDouble(map, 'gold', 0.0),
      silver: ModelParsingHelper.safeDouble(map, 'silver', 0.0),
      copper: ModelParsingHelper.safeDouble(map, 'copper', 0.0),
      
      // Metadaten
      sourceType: ModelParsingHelper.safeString(map, 'source_type', 'custom'),
      sourceId: ModelParsingHelper.safeStringOrNull(map, 'source_id', null),
      isFavorite: ModelParsingHelper.safeBool(map, 'is_favorite', false),
      version: ModelParsingHelper.safeString(map, 'version', '1.0'),
      
      // D&D 5e Felder
      proficiencyBonus: ModelParsingHelper.safeInt(map, 'proficiency_bonus', 2),
      speed: ModelParsingHelper.safeInt(map, 'speed', 30),
      passivePerception: ModelParsingHelper.safeInt(map, 'passive_perception', 10),
      spellSlots: ModelParsingHelper.safeStringOrNull(map, 'spell_slots', null),
      spellSaveDc: ModelParsingHelper.safeInt(map, 'spell_save_dc', 8),
      spellAttackBonus: ModelParsingHelper.safeInt(map, 'spell_attack_bonus', 0),
    );
  }

  // Hilfsmethoden für komplexe Daten

  /// Serialisiert eine Liste von Strings als JSON
  static String _serializeList(List<String> list) {
    try {
      return jsonEncode(list);
    } catch (e) {
      return '[]';
    }
  }

  /// Deserialisiert eine Liste von Strings aus JSON
  static List<String> _deserializeList(String? json) {
    if (json == null || json.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List;
      return decoded.map((item) => item.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Serialisiert eine Liste von Angriffen als JSON
  static String _serializeAttackList(List<Attack> attacks) {
    try {
      final list = attacks.map((a) => a.toMap()).toList();
      return jsonEncode(list);
    } catch (e) {
      return '[]';
    }
  }

  /// Deserialisiert eine Liste von Angriffen aus JSON
  static List<Attack> _deserializeAttackList(String? json) {
    if (json == null || json.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List;
      return decoded.map((item) => Attack.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Serialisiert ein Inventar als JSON
  static String _serializeInventory(List<InventoryItem> inventory) {
    try {
      final list = inventory.map((i) => i.toMap()).toList();
      return jsonEncode(list);
    } catch (e) {
      return '[]';
    }
  }

  /// Deserialisiert ein Inventar aus JSON
  static List<InventoryItem> _deserializeInventory(String? json) {
    if (json == null || json.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List;
      return decoded.map((item) => InventoryItem.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Serialisiert Equipment als JSON
  static String _serializeEquipment(Map<String, String>? equipment) {
    if (equipment == null || equipment.isEmpty) return '{}';
    try {
      return jsonEncode(equipment);
    } catch (e) {
      return '{}';
    }
  }

  /// Deserialisiert Equipment aus JSON
  static Map<String, String>? _deserializeEquipment(String? json) {
    if (json == null || json.trim().isEmpty || json == '{}') return null;
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return null;
    }
  }

  /// Gibt den Tabellennamen für die Datenbank zurück
  static String get tableName => 'player_characters';

  factory PlayerCharacter.fromMap(Map<String, dynamic> map) {
    return PlayerCharacter(
      id: ModelParsingHelper.safeId(map, 'id'),
      campaignId: map['campaignId']?.toString() ?? ModelParsingHelper.safeString(map, 'campaign_id', ''),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbenannt'),
      playerName: map['playerName']?.toString() ?? ModelParsingHelper.safeString(map, 'player_name', 'Unbekannt'),
      className: map['className']?.toString() ?? ModelParsingHelper.safeString(map, 'class_name', 'Unbekannt'),
      raceName: map['raceName']?.toString() ?? ModelParsingHelper.safeString(map, 'race_name', 'Mensch'),
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
      proficiencyBonus: ModelParsingHelper.safeInt(map, 'proficiencyBonus', 2),
      speed: ModelParsingHelper.safeInt(map, 'speed', 30),
      passivePerception: ModelParsingHelper.safeInt(map, 'passivePerception', 10),
      spellSlots: ModelParsingHelper.safeStringOrNull(map, 'spellSlots', null),
      spellSaveDc: ModelParsingHelper.safeInt(map, 'spellSaveDc', 8),
      spellAttackBonus: ModelParsingHelper.safeInt(map, 'spellAttackBonus', 0),
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
    List<String>? savingThrowProficiencies,
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
    Map<String, String>? equipment,
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
      savingThrowProficiencies: savingThrowProficiencies ?? this.savingThrowProficiencies,
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
      equipment: equipment ?? this.equipment,
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
