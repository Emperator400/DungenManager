import 'base_entity.dart';
import '../core/database_entity.dart';
import '../../models/creature.dart';

/// Creature Entity für die neue Datenbankarchitektur
/// Implementiert DatabaseEntity für die neue Repository-Architektur
class CreatureEntity extends BaseEntity implements DatabaseEntity<CreatureEntity> {
  // Core Felder
  String _id;
  final String name;
  final int maxHp;
  final int armorClass;
  final String speed;
  final String attacks;
  final int initiativeBonus;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final bool isPlayer;
  
  // Währungsfelder
  final double gold;
  final double silver;
  final double copper;
  
  // D&D Klassifikation
  final String? size;
  final String? type;
  final String? subtype;
  final String? alignment;
  final String? description;
  final String? specialAbilities;
  final String? legendaryActions;
  
  // Metadaten
  final String? officialMonsterId;
  final String? officialSpellIds;
  final String? officialItemIds;
  final double? challengeRating;
  final bool isCustom;
  final String sourceType;
  final String? sourceId;
  final bool isFavorite;
  final String version;
  
  // Strukturierte Listen (als JSON-Strings in der Datenbank)
  final String? attackList;   // JSON-String für List<Attack>
  final String? inventory;     // JSON-String für List<Map<String, dynamic>>

  // Konstruktor
  CreatureEntity({
    required String id,
    required this.name,
    required this.maxHp,
    required this.armorClass,
    required this.speed,
    required this.attacks,
    required this.initiativeBonus,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.isPlayer,
    this.gold = 0.0,
    this.silver = 0.0,
    this.copper = 0.0,
    this.size,
    this.type,
    this.subtype,
    this.alignment,
    this.description,
    this.specialAbilities,
    this.legendaryActions,
    this.officialMonsterId,
    this.officialSpellIds,
    this.officialItemIds,
    this.challengeRating,
    this.isCustom = true,
    this.sourceType = 'custom',
    this.sourceId,
    this.isFavorite = false,
    this.version = '1.0',
    this.attackList,
    this.inventory,
  }) : _id = id;

  /// Factory für Datenbank-Erstellung
  factory CreatureEntity.fromMap(Map<String, dynamic> map) {
    return CreatureEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      maxHp: map['max_hp'] as int,
      armorClass: map['armor_class'] as int,
      speed: map['speed'] as String,
      attacks: map['attacks'] as String,
      initiativeBonus: map['initiativeBonus'] as int,
      strength: map['strength'] as int,
      dexterity: map['dexterity'] as int,
      constitution: map['constitution'] as int,
      intelligence: map['intelligence'] as int,
      wisdom: map['wisdom'] as int,
      charisma: map['charisma'] as int,
      isPlayer: (map['isPlayer'] as int) == 1,
      gold: (map['gold'] as num?)?.toDouble() ?? 0.0,
      silver: (map['silver'] as num?)?.toDouble() ?? 0.0,
      copper: (map['copper'] as num?)?.toDouble() ?? 0.0,
      size: map['size'] as String?,
      type: map['type'] as String?,
      subtype: map['subtype'] as String?,
      alignment: map['alignment'] as String?,
      description: map['description'] as String?,
      specialAbilities: map['special_abilities'] as String?,
      legendaryActions: map['legendary_actions'] as String?,
      officialMonsterId: map['official_monster_id'] as String?,
      officialSpellIds: map['official_spell_ids'] as String?,
      officialItemIds: map['official_item_ids'] as String?,
      challengeRating: (map['challenge_rating'] as num?)?.toDouble(),
      isCustom: (map['is_custom'] as int?) == 1,
      sourceType: map['source_type'] as String? ?? 'custom',
      sourceId: map['source_id'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      version: map['version'] as String? ?? '1.0',
      attackList: map['attack_list'] as String?,
      inventory: map['inventory'] as String?,
    );
  }

  /// Factory von Creature Model
  factory CreatureEntity.fromModel(Creature creature) {
    return CreatureEntity(
      id: creature.id,
      name: creature.name,
      maxHp: creature.maxHp,
      armorClass: creature.armorClass,
      speed: creature.speed,
      attacks: creature.attacks,
      initiativeBonus: creature.initiativeBonus,
      strength: creature.strength,
      dexterity: creature.dexterity,
      constitution: creature.constitution,
      intelligence: creature.intelligence,
      wisdom: creature.wisdom,
      charisma: creature.charisma,
      isPlayer: creature.isPlayer,
      gold: creature.gold,
      silver: creature.silver,
      copper: creature.copper,
      size: creature.size,
      type: creature.type,
      subtype: creature.subtype,
      alignment: creature.alignment,
      description: creature.description,
      specialAbilities: creature.specialAbilities,
      legendaryActions: creature.legendaryActions,
      officialMonsterId: creature.officialMonsterId,
      officialSpellIds: creature.officialSpellIds,
      officialItemIds: creature.officialItemIds,
      challengeRating: creature.challengeRating?.toDouble(),
      isCustom: creature.isCustom,
      sourceType: creature.sourceType,
      sourceId: creature.sourceId,
      isFavorite: creature.isFavorite,
      version: creature.version,
      attackList: creature.attackList?.toString(),
      inventory: creature.inventory?.toString(),
    );
  }

  /// ID Getter aus BaseEntity
  @override
  String get id => _id;
  
  /// ID Setter aus BaseEntity
  @override
  set id(String value) => _id = value;
  
  /// Metadata Getter aus BaseEntity
  @override
  Map<String, dynamic> get metadata => {
    'entityType': 'Creature',
    'tableName': tableName,
    'isPlayer': isPlayer,
    'sourceType': sourceType,
    'isCustom': isCustom,
  };
  
  /// Validierung Getter aus BaseEntity
  @override
  bool get isValid {
    return name.isNotEmpty && 
           maxHp > 0 && 
           armorClass >= 0 &&
           speed.isNotEmpty;
  }
  
  /// Validation Errors Getter aus BaseEntity
  @override
  List<String> get validationErrors {
    final errors = <String>[];
    if (name.isEmpty) errors.add('Name darf nicht leer sein');
    if (maxHp <= 0) errors.add('Max HP muss positiv sein');
    if (armorClass < 0) errors.add('Rüstungsklasse darf nicht negativ sein');
    if (speed.isEmpty) errors.add('Geschwindigkeit darf nicht leer sein');
    return errors;
  }

  /// Konvertierung zu Map für Datenbank (Legacy Methode)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'max_hp': maxHp,
      'armor_class': armorClass,
      'speed': speed,
      'attacks': attacks,
      'initiativeBonus': initiativeBonus,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'isPlayer': isPlayer ? 1 : 0,
      'gold': gold,
      'silver': silver,
      'copper': copper,
      'size': size,
      'type': type,
      'subtype': subtype,
      'alignment': alignment,
      'description': description,
      'special_abilities': specialAbilities,
      'legendary_actions': legendaryActions,
      'official_monster_id': officialMonsterId,
      'official_spell_ids': officialSpellIds,
      'official_item_ids': officialItemIds,
      'challenge_rating': challengeRating,
      'is_custom': isCustom ? 1 : 0,
      'source_type': sourceType,
      'source_id': sourceId,
      'is_favorite': isFavorite ? 1 : 0,
      'version': version,
      'attack_list': attackList,
      'inventory': inventory,
    };
  }

  /// Konvertierung zurück zum Creature Model
  Creature toModel() {
    return Creature(
      id: id,
      name: name,
      maxHp: maxHp,
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
      isPlayer: isPlayer,
      gold: gold,
      silver: silver,
      copper: copper,
      officialMonsterId: officialMonsterId,
      officialSpellIds: officialSpellIds,
      officialItemIds: officialItemIds,
      size: size,
      type: type,
      subtype: subtype,
      alignment: alignment,
      challengeRating: challengeRating?.toInt(), // Konvertiere double zu int?
      specialAbilities: specialAbilities,
      legendaryActions: legendaryActions,
      isCustom: isCustom,
      description: description,
      sourceType: sourceType,
      sourceId: sourceId,
      isFavorite: isFavorite,
      version: version,
      attackList: const [], // Leere Liste, da attackList JSON-String ist
      inventory: const [], // Leere Liste, da inventory JSON-String ist
    );
  }

  /// Kopie mit geänderten Werten erstellen
  CreatureEntity copyWith({
    String? id,
    String? name,
    int? maxHp,
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
    bool? isPlayer,
    double? gold,
    double? silver,
    double? copper,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    String? description,
    String? specialAbilities,
    String? legendaryActions,
    String? officialMonsterId,
    String? officialSpellIds,
    String? officialItemIds,
    double? challengeRating,
    bool? isCustom,
    String? sourceType,
    String? sourceId,
    bool? isFavorite,
    String? version,
    String? attackList,
    String? inventory,
  }) {
    return CreatureEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      maxHp: maxHp ?? this.maxHp,
      armorClass: armorClass ?? this.armorClass,
      speed: speed ?? this.speed,
      attacks: attacks ?? this.attacks,
      initiativeBonus: initiativeBonus ?? this.initiativeBonus,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      constitution: constitution ?? this.constitution,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      charisma: charisma ?? this.charisma,
      isPlayer: isPlayer ?? this.isPlayer,
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      copper: copper ?? this.copper,
      size: size ?? this.size,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      alignment: alignment ?? this.alignment,
      description: description ?? this.description,
      specialAbilities: specialAbilities ?? this.specialAbilities,
      legendaryActions: legendaryActions ?? this.legendaryActions,
      officialMonsterId: officialMonsterId ?? this.officialMonsterId,
      officialSpellIds: officialSpellIds ?? this.officialSpellIds,
      officialItemIds: officialItemIds ?? this.officialItemIds,
      challengeRating: challengeRating ?? this.challengeRating,
      isCustom: isCustom ?? this.isCustom,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isFavorite: isFavorite ?? this.isFavorite,
      version: version ?? this.version,
      attackList: attackList ?? this.attackList,
      inventory: inventory ?? this.inventory,
    );
  }

  // DatabaseEntity Interface Implementierung

  @override
  String get tableName => 'creatures';

  @override
  String get primaryKeyField => 'id';

  @override
  List<String> get databaseFields => [
    'id',
    'name',
    'max_hp',
    'armor_class',
    'speed',
    'attacks',
    'initiativeBonus',
    'strength',
    'dexterity',
    'constitution',
    'intelligence',
    'wisdom',
    'charisma',
    'isPlayer',
    'gold',
    'silver',
    'copper',
    'size',
    'type',
    'subtype',
    'alignment',
    'special_abilities',
    'legendary_actions',
    'official_monster_id',
    'official_spell_ids',
    'official_item_ids',
    'challenge_rating',
    'is_custom',
    'source_type',
    'source_id',
    'is_favorite',
    'version',
    'attack_list',
    'inventory',
  ];

  @override
  List<String> get createTableSql => [
    '''
      CREATE TABLE creatures (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        maxHp INTEGER NOT NULL,
        armorClass INTEGER NOT NULL,
        speed TEXT NOT NULL,
        attacks TEXT NOT NULL,
        initiativeBonus INTEGER NOT NULL,
        strength INTEGER NOT NULL,
        dexterity INTEGER NOT NULL,
        constitution INTEGER NOT NULL,
        intelligence INTEGER NOT NULL,
        wisdom INTEGER NOT NULL,
        charisma INTEGER NOT NULL,
        isPlayer INTEGER DEFAULT 0,
        gold REAL DEFAULT 0.0,
        silver REAL DEFAULT 0.0,
        copper REAL DEFAULT 0.0,
        official_monster_id TEXT,
        official_spell_ids TEXT,
        official_item_ids TEXT,
        size TEXT,
        type TEXT,
        subtype TEXT,
        alignment TEXT,
        challenge_rating REAL,
        special_abilities TEXT,
        legendary_actions TEXT,
        is_custom INTEGER DEFAULT 1,
        description TEXT,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_favorite INTEGER DEFAULT 0,
        version TEXT DEFAULT '1.0',
        attack_list TEXT,
        inventory TEXT
      )
    '''
  ];

  @override
  String toString() {
    return 'CreatureEntity(id: $id, name: $name, maxHp: $maxHp, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreatureEntity &&
           other.id == id &&
           other.name == name &&
           other.maxHp == maxHp &&
           other.armorClass == armorClass;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           name.hashCode ^
           maxHp.hashCode ^
           armorClass.hashCode;
  }

  @override
  List<String> get createIndexes => [
    'CREATE INDEX idx_creatures_name ON creatures(name)',
    'CREATE INDEX idx_creatures_type ON creatures(type)',
    'CREATE INDEX idx_creatures_source_type ON creatures(source_type)',
    'CREATE INDEX idx_creatures_is_favorite ON creatures(is_favorite)',
  ];

  @override
  Map<String, dynamic> toDatabaseMap() {
    return toMap();
  }

  @override
  CreatureEntity fromDatabaseMap(Map<String, dynamic> map) {
    return CreatureEntity.fromMap(map);
  }

  // Implementierung der abstrakten Methoden von DatabaseEntity

  @override
  String toSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .toLowerCase();
  }
  
  @override
  String toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.length == 1) return parts.first;
    
    return parts.first + parts
        .skip(1)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join('');
  }
  
  @override
  Map<String, dynamic> convertToSnakeCase(Map<String, dynamic> camelCaseMap) {
    final snakeCaseMap = <String, dynamic>{};
    
    for (final entry in camelCaseMap.entries) {
      final snakeKey = toSnakeCase(entry.key);
      snakeCaseMap[snakeKey] = entry.value;
    }
    
    return snakeCaseMap;
  }
  
  @override
  Map<String, dynamic> convertToCamelCase(Map<String, dynamic> snakeCaseMap) {
    final camelCaseMap = <String, dynamic>{};
    
    for (final entry in snakeCaseMap.entries) {
      final camelKey = toCamelCase(entry.key);
      camelCaseMap[camelKey] = entry.value;
    }
    
    return camelCaseMap;
  }

  /// Factory zum Erstellen einer leeren Creature-Instanz
  factory CreatureEntity.create({
    String? id,
    String? name,
    int? maxHp,
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
    bool? isPlayer,
  }) {
    return CreatureEntity(
      id: id ?? '',
      name: name ?? '',
      maxHp: maxHp ?? 10,
      armorClass: armorClass ?? 10,
      speed: speed ?? '30 ft',
      attacks: attacks ?? '',
      initiativeBonus: initiativeBonus ?? 0,
      strength: strength ?? 10,
      dexterity: dexterity ?? 10,
      constitution: constitution ?? 10,
      intelligence: intelligence ?? 10,
      wisdom: wisdom ?? 10,
      charisma: charisma ?? 10,
      isPlayer: isPlayer ?? false,
    );
  }
}
