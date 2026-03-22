import '../core/database_entity.dart';
import 'base_entity.dart';
import '../../models/player_character.dart';
import '../../models/attack.dart';
import '../../models/inventory_item.dart';

/// PlayerCharacter-Entität für die neue Datenbankarchitektur
/// Implementiert DatabaseEntity für PlayerCharacter-Tabellen
class PlayerCharacterEntity extends BaseEntity implements DatabaseEntity<PlayerCharacterEntity> {
  String id;
  String name;
  String characterClass;
  int level;
  String race;
  String? background;
  String? alignment;
  Map<String, int> abilities; // STR, DEX, CON, INT, WIS, CHA
  int hitPoints;
  int maxHitPoints;
  int armorClass;
  int speed;
  String? imageUrl;
  List<String> tags;
  String? campaignId;
  bool isActive;
  Map<String, dynamic> characterData; // Zusätzliche Charakterdaten
  DateTime createdAt;
  DateTime updatedAt;
  
  // Trefferwürfel
  String hitDice; // z.B. "d8", "d10", "d12"
  int hitDiceCount; // Anzahl der Trefferwürfel (normalerweise = Level)
  int hitDiceRemaining; // Verbleibende Trefferwürfel für Kurzrast

  PlayerCharacterEntity({
    required this.id,
    required this.name,
    required this.characterClass,
    required this.level,
    required this.race,
    this.background,
    this.alignment,
    this.abilities = const {
      'strength': 10,
      'dexterity': 10,
      'constitution': 10,
      'intelligence': 10,
      'wisdom': 10,
      'charisma': 10,
    },
    required this.hitPoints,
    required this.maxHitPoints,
    required this.armorClass,
    required this.speed,
    this.imageUrl,
    this.tags = const [],
    this.campaignId,
    this.isActive = false,
    this.characterData = const {},
    required this.createdAt,
    required this.updatedAt,
    this.hitDice = 'd8',
    this.hitDiceCount = 1,
    this.hitDiceRemaining = 1,
  });

  @override
  String get tableName => 'player_characters';

  @override
  String get primaryKeyField => 'id';

  @override
  List<String> get databaseFields => [
    'id',
    'name',
    'character_class',
    'level',
    'race',
    'background',
    'alignment',
    'abilities',
    'hit_points',
    'max_hit_points',
    'armor_class',
    'speed',
    'image_url',
    'tags',
    'campaign_id',
    'is_active',
    'character_data',
    'equipment',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get createTableSql => [
    '''
    CREATE TABLE player_characters (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      character_class TEXT NOT NULL,
      level INTEGER NOT NULL DEFAULT 1,
      race TEXT NOT NULL,
      background TEXT,
      alignment TEXT,
      abilities TEXT,
      hit_points INTEGER NOT NULL DEFAULT 0,
      max_hit_points INTEGER NOT NULL DEFAULT 0,
      armor_class INTEGER NOT NULL DEFAULT 10,
      speed INTEGER NOT NULL DEFAULT 30,
      image_url TEXT,
      tags TEXT,
      campaign_id TEXT,
      is_active INTEGER NOT NULL DEFAULT 0,
      character_data TEXT,
      equipment TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (campaign_id) REFERENCES campaigns (id) ON DELETE SET NULL
    )
    ''',
  ];

  @override
  List<String> get createIndexes => [
    'CREATE INDEX idx_player_characters_name ON player_characters(name)',
    'CREATE INDEX idx_player_characters_campaign_id ON player_characters(campaign_id)',
    'CREATE INDEX idx_player_characters_is_active ON player_characters(is_active)',
    'CREATE INDEX idx_player_characters_level ON player_characters(level)',
    'CREATE INDEX idx_player_characters_class ON player_characters(character_class)',
    'CREATE INDEX idx_player_characters_created_at ON player_characters(created_at)',
  ];

  @override
  Map<String, dynamic> toDatabaseMap() {
    return convertToSnakeCase({
      'id': id,
      'name': name,
      'characterClass': characterClass,
      'level': level,
      'race': race,
      'background': background,
      'alignment': alignment,
      'abilities': _encodeAbilities(abilities),
      'hitPoints': hitPoints,
      'maxHitPoints': maxHitPoints,
      'armorClass': armorClass,
      'speed': speed,
      'imageUrl': imageUrl,
      'tags': tags.join(','),
      'campaignId': campaignId,
      'isActive': isActive ? 1 : 0,
      'characterData': _encodeCharacterData(characterData),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'hitDice': hitDice,
      'hitDiceCount': hitDiceCount,
      'hitDiceRemaining': hitDiceRemaining,
    });
  }

  @override
  PlayerCharacterEntity fromDatabaseMap(Map<String, dynamic> map) {
    final camelCaseMap = convertToCamelCase(map);
    
    return PlayerCharacterEntity(
      id: camelCaseMap['id'] as String,
      name: camelCaseMap['name'] as String,
      characterClass: camelCaseMap['characterClass'] as String,
      level: camelCaseMap['level'] as int? ?? 1,
      race: camelCaseMap['race'] as String,
      background: camelCaseMap['background'] as String?,
      alignment: camelCaseMap['alignment'] as String?,
      abilities: _decodeAbilities(camelCaseMap['abilities'] as String?),
      hitPoints: camelCaseMap['hitPoints'] as int? ?? 0,
      maxHitPoints: camelCaseMap['maxHitPoints'] as int? ?? 0,
      armorClass: camelCaseMap['armorClass'] as int? ?? 10,
      speed: camelCaseMap['speed'] as int? ?? 30,
      imageUrl: camelCaseMap['imageUrl'] as String?,
      tags: _parseTags(camelCaseMap['tags'] as String?),
      campaignId: camelCaseMap['campaignId'] as String?,
      isActive: (camelCaseMap['isActive'] as int?) == 1,
      characterData: _decodeCharacterData(camelCaseMap['characterData'] as String?),
      createdAt: DateTime.parse(camelCaseMap['createdAt'] as String),
      updatedAt: DateTime.parse(camelCaseMap['updatedAt'] as String),
      hitDice: camelCaseMap['hitDice'] as String? ?? 'd8',
      hitDiceCount: camelCaseMap['hitDiceCount'] as int? ?? 1,
      hitDiceRemaining: camelCaseMap['hitDiceRemaining'] as int? ?? 1,
    );
  }

  @override
  bool get isValid {
    final errors = validationErrors;
    return errors.isEmpty;
  }

  @override
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (name.trim().isEmpty) {
      errors.add('Character name cannot be empty');
    }
    
    if (name.length > 100) {
      errors.add('Character name too long (max 100 characters)');
    }
    
    if (characterClass.trim().isEmpty) {
      errors.add('Character class cannot be empty');
    }
    
    if (race.trim().isEmpty) {
      errors.add('Race cannot be empty');
    }
    
    if (level < 1 || level > 20) {
      errors.add('Level must be between 1 and 20');
    }
    
    if (hitPoints < 0) {
      errors.add('Hit points cannot be negative');
    }
    
    if (maxHitPoints < 0) {
      errors.add('Max hit points cannot be negative');
    }
    
    if (hitPoints > maxHitPoints) {
      errors.add('Current hit points cannot exceed max hit points');
    }
    
    if (armorClass < 0) {
      errors.add('Armor class cannot be negative');
    }
    
    if (speed < 0) {
      errors.add('Speed cannot be negative');
    }
    
    // Validate abilities
    final abilityKeys = ['strength', 'dexterity', 'constitution', 'intelligence', 'wisdom', 'charisma'];
    for (final key in abilityKeys) {
      final value = abilities[key] ?? 0;
      if (value < 1 || value > 30) {
        errors.add('Ability $key must be between 1 and 30 (current: $value)');
      }
    }
    
    if (tags.length > 10) {
      errors.add('Too many tags (max 10)');
    }
    
    for (final tag in tags) {
      if (tag.length > 20) {
        errors.add('Tag too long: $tag (max 20 characters)');
      }
    }
    
    return errors;
  }

  @override
  Map<String, dynamic> get metadata => {
    'tableName': tableName,
    'recordCount': 1, // Would be set by repository
    'tags': tags,
    'isActive': isActive,
    'campaignId': campaignId,
    'level': level,
    'characterClass': characterClass,
    'race': race,
    'hasImage': imageUrl != null && imageUrl!.isNotEmpty,
    'hitPointRatio': maxHitPoints > 0 ? hitPoints / maxHitPoints : 0.0,
    'abilityScores': abilities,
  };

  @override
  PlayerCharacterEntity copyWith({
    String? id,
    String? name,
    String? characterClass,
    int? level,
    String? race,
    String? background,
    String? alignment,
    Map<String, int>? abilities,
    int? hitPoints,
    int? maxHitPoints,
    int? armorClass,
    int? speed,
    String? imageUrl,
    List<String>? tags,
    String? campaignId,
    bool? isActive,
    Map<String, dynamic>? characterData,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? hitDice,
    int? hitDiceCount,
    int? hitDiceRemaining,
  }) {
    return PlayerCharacterEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      characterClass: characterClass ?? this.characterClass,
      level: level ?? this.level,
      race: race ?? this.race,
      background: background ?? this.background,
      alignment: alignment ?? this.alignment,
      abilities: abilities ?? this.abilities,
      hitPoints: hitPoints ?? this.hitPoints,
      maxHitPoints: maxHitPoints ?? this.maxHitPoints,
      armorClass: armorClass ?? this.armorClass,
      speed: speed ?? this.speed,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      campaignId: campaignId ?? this.campaignId,
      isActive: isActive ?? this.isActive,
      characterData: characterData ?? this.characterData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hitDice: hitDice ?? this.hitDice,
      hitDiceCount: hitDiceCount ?? this.hitDiceCount,
      hitDiceRemaining: hitDiceRemaining ?? this.hitDiceRemaining,
    );
  }

  @override
  String toString() {
    return 'PlayerCharacterEntity(id: $id, name: $name, class: $characterClass, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerCharacterEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

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

  // Helper methods for data conversion

  String _encodeAbilities(Map<String, int> abilities) {
    try {
      return abilities.entries
          .map((e) => '${e.key}:${e.value}')
          .join('|');
    } catch (e) {
      return '';
    }
  }

  Map<String, int> _decodeAbilities(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return {
        'strength': 10,
        'dexterity': 10,
        'constitution': 10,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
      };
    }
    
    try {
      final Map<String, int> abilities = {};
      final pairs = encoded.split('|');
      
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0];
          final value = int.tryParse(parts[1]) ?? 10;
          abilities[key] = value;
        }
      }
      
      // Ensure all abilities are present
      final defaultAbilities = [
        'strength', 'dexterity', 'constitution', 
        'intelligence', 'wisdom', 'charisma'
      ];
      
      for (final ability in defaultAbilities) {
        abilities.putIfAbsent(ability, () => 10);
      }
      
      return abilities;
    } catch (e) {
      return {
        'strength': 10,
        'dexterity': 10,
        'constitution': 10,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
      };
    }
  }

  String _encodeCharacterData(Map<String, dynamic> data) {
    try {
      return data.entries
          .map((e) => '${e.key}:${e.value}')
          .join('|');
    } catch (e) {
      return '';
    }
  }

  Map<String, dynamic> _decodeCharacterData(String? encoded) {
    if (encoded == null || encoded.isEmpty) return {};
    
    try {
      final Map<String, dynamic> data = {};
      final pairs = encoded.split('|');
      
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          data[parts[0]] = parts[1];
        }
      }
      
      return data;
    } catch (e) {
      return {};
    }
  }

  List<String> _parseTags(String? tagsString) {
    if (tagsString == null || tagsString.trim().isEmpty) {
      return [];
    }
    
    return tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  /// Convenience factory for creating new player characters
  factory PlayerCharacterEntity.create({
    required String name,
    required String characterClass,
    required String race,
    int level = 1,
    String? background,
    String? alignment,
    Map<String, int>? abilities,
    String? campaignId,
    String? imageUrl,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    
    return PlayerCharacterEntity(
      id: _generateId(),
      name: name.trim(),
      characterClass: characterClass.trim(),
      level: level,
      race: race.trim(),
      background: background?.trim(),
      alignment: alignment?.trim(),
      abilities: abilities ?? {
        'strength': 10,
        'dexterity': 10,
        'constitution': 10,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
      },
      hitPoints: 10, // Default starting HP
      maxHitPoints: 10,
      armorClass: 10, // Default AC
      speed: 30, // Default speed
      imageUrl: imageUrl?.trim(),
      tags: tags,
      campaignId: campaignId,
      isActive: true,
      characterData: {},
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _generateId() {
    // Simple ID generation - in production use UUID service
    return 'pc_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Character management methods
  PlayerCharacterEntity levelUp(int levelsToGain) {
    if (levelsToGain <= 0) return this;
    
    final newLevel = (level + levelsToGain).clamp(1, 20);
    return copyWith(
      level: newLevel,
      maxHitPoints: maxHitPoints + (levelsToGain * 5), // Simple HP gain formula
      hitPoints: hitPoints + (levelsToGain * 5),
      updatedAt: DateTime.now(),
    );
  }

  PlayerCharacterEntity takeDamage(int damage) {
    if (damage <= 0) return this;
    
    final newHp = (hitPoints - damage).clamp(0, maxHitPoints);
    return copyWith(
      hitPoints: newHp,
      updatedAt: DateTime.now(),
    );
  }

  PlayerCharacterEntity heal(int healing) {
    if (healing <= 0) return this;
    
    final newHp = (hitPoints + healing).clamp(0, maxHitPoints);
    return copyWith(
      hitPoints: newHp,
      updatedAt: DateTime.now(),
    );
  }

  PlayerCharacterEntity setAbility(String ability, int value) {
    final normalizedAbility = ability.toLowerCase();
    final validAbilities = [
      'strength', 'dexterity', 'constitution', 
      'intelligence', 'wisdom', 'charisma'
    ];
    
    if (!validAbilities.contains(normalizedAbility)) {
      return this;
    }
    
    final clampedValue = value.clamp(1, 30);
    final newAbilities = Map<String, int>.from(abilities);
    newAbilities[normalizedAbility] = clampedValue;
    
    return copyWith(
      abilities: newAbilities,
      updatedAt: DateTime.now(),
    );
  }

  PlayerCharacterEntity addToCampaign(String campaignId) {
    return copyWith(
      campaignId: campaignId,
      updatedAt: DateTime.now(),
    );
  }

  PlayerCharacterEntity removeFromCampaign() {
    return copyWith(
      campaignId: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Calculate ability modifier
  int getAbilityModifier(String ability) {
    final score = abilities[ability.toLowerCase()] ?? 10;
    return ((score - 10) / 2).floor();
  }

  /// Check if character is alive
  bool get isAlive => hitPoints > 0;

  /// Get hit point percentage
  double get hpPercentage => maxHitPoints > 0 ? hitPoints / maxHitPoints : 0.0;

  /// Konvertiert die Entity in das PlayerCharacter-Modell
  PlayerCharacter toModel() {
    // Extrahiere Daten aus characterData
    final extractedData = characterData as Map<String, dynamic>? ?? {};
    
    return PlayerCharacter(
      id: id,
      campaignId: campaignId ?? '',
      name: name,
      playerName: background ?? '', // Verwende background als playerName-Platzhalter
      className: characterClass,
      raceName: race,
      level: level,
      maxHp: maxHitPoints,
      armorClass: armorClass,
      initiativeBonus: getAbilityModifier('dexterity'),
      imagePath: imageUrl,
      
      // Abilities
      strength: abilities['strength'] ?? 10,
      dexterity: abilities['dexterity'] ?? 10,
      constitution: abilities['constitution'] ?? 10,
      intelligence: abilities['intelligence'] ?? 10,
      wisdom: abilities['wisdom'] ?? 10,
      charisma: abilities['charisma'] ?? 10,
      
      // Fertigkeiten
      proficientSkills: extractedData['proficientSkills'] as List<String>? ?? [],
      
      // D&D Details
      size: extractedData['size'] as String? ?? 'Medium',
      type: extractedData['type'] as String? ?? 'Humanoid',
      subtype: extractedData['subtype'] as String?,
      alignment: alignment ?? 'Neutral',
      description: extractedData['description'] as String? ?? '',
      specialAbilities: extractedData['specialAbilities'] as String?,
      attacks: extractedData['attacks'] as String? ?? '',
      attackList: <Attack>[], // Wird aus characterData extrahieren
      inventory: <InventoryItem>[], // Wird aus characterData extrahieren
      
      // Währung
      gold: extractedData['gold'] as double? ?? 0.0,
      silver: extractedData['silver'] as double? ?? 0.0,
      copper: extractedData['copper'] as double? ?? 0.0,
      
      // Metadaten
      sourceType: 'custom',
      sourceId: campaignId,
      isFavorite: false,
      version: '1.0',
      
      // Trefferwürfel
      hitDice: hitDice,
      hitDiceCount: hitDiceCount,
      hitDiceRemaining: hitDiceRemaining,
    );
  }

  /// Konvertiert das PlayerCharacter-Modell in eine Entity
  static PlayerCharacterEntity fromModel(PlayerCharacter model) {
    return PlayerCharacterEntity(
      id: model.id,
      name: model.name,
      characterClass: model.className,
      level: model.level,
      race: model.raceName,
      background: model.playerName.isEmpty ? null : model.playerName,
      alignment: model.alignment,
      abilities: {
        'strength': model.strength,
        'dexterity': model.dexterity,
        'constitution': model.constitution,
        'intelligence': model.intelligence,
        'wisdom': model.wisdom,
        'charisma': model.charisma,
      },
      hitPoints: model.maxHp, // Verwende maxHp für hitPoints
      maxHitPoints: model.maxHp,
      armorClass: model.armorClass,
      speed: 30, // Standardwert
      imageUrl: model.imagePath,
      tags: [], // Aus model.tags extrahieren
      campaignId: model.campaignId,
      isActive: true,
      characterData: {
        'proficientSkills': model.proficientSkills,
        'size': model.size,
        'type': model.type,
        'subtype': model.subtype,
        'description': model.description,
        'specialAbilities': model.specialAbilities,
        'attacks': model.attacks,
        'attackList': model.attackList,
        'inventory': model.inventory,
        'gold': model.gold,
        'silver': model.silver,
        'copper': model.copper,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      hitDice: model.hitDice,
      hitDiceCount: model.hitDiceCount,
      hitDiceRemaining: model.hitDiceRemaining,
    );
  }
}
