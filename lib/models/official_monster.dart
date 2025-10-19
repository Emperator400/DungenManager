// lib/models/official_monster.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

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

  OfficialMonster({
    String? id,
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
  }) : id = id ?? uuid.v4();

  // Konvertierung für Datenbank
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

  // Erstellung aus Datenbank
  factory OfficialMonster.fromMap(Map<String, dynamic> map) {
    return OfficialMonster(
      id: map['id'],
      name: map['name'],
      size: map['size'],
      type: map['type'],
      subtype: map['subtype'],
      alignment: map['alignment'],
      armorClass: map['armor_class'],
      hitPoints: map['hit_points'],
      hitDice: map['hit_dice'],
      speed: map['speed'],
      strength: map['strength'],
      dexterity: map['dexterity'],
      constitution: map['constitution'],
      intelligence: map['intelligence'],
      wisdom: map['wisdom'],
      charisma: map['charisma'],
      savingThrows: map['saving_throws']?.toString().split(',') ?? [],
      skills: _parseSkills(map['skills']),
      damageVulnerabilities: map['damage_vulnerabilities']?.toString().split(',') ?? [],
      damageResistances: map['damage_resistances']?.toString().split(',') ?? [],
      damageImmunities: map['damage_immunities']?.toString().split(',') ?? [],
      conditionImmunities: map['condition_immunities']?.toString().split(',') ?? [],
      senses: _parseSenses(map['senses']),
      languages: map['languages'] ?? '',
      challengeRating: map['challenge_rating'],
      xp: map['xp'],
      specialAbilities: _parseAbilities(map['special_abilities']),
      actions: _parseActions(map['actions']),
      legendaryActions: _parseLegendaryActions(map['legendary_actions']),
      lairActions: _parseLairActions(map['lair_actions']),
      description: map['description'],
      source: map['source'],
      page: map['page'] ?? 1,
      isCustom: map['is_custom'] == 1,
      version: map['version'],
      customData: map['custom_data'],
    );
  }

  // Parser für komplexe Felder
  static Map<String, int> _parseSkills(dynamic skillsData) {
    if (skillsData == null || skillsData.toString().isEmpty) return {};
    final skills = <String, int>{};
    final parts = skillsData.toString().split(',');
    for (final part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        skills[keyValue[0]] = int.tryParse(keyValue[1]) ?? 0;
      }
    }
    return skills;
  }

  static Map<String, String> _parseSenses(dynamic sensesData) {
    if (sensesData == null || sensesData.toString().isEmpty) return {};
    final senses = <String, String>{};
    final parts = sensesData.toString().split(',');
    for (final part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        senses[keyValue[0]] = keyValue[1];
      }
    }
    return senses;
  }

  static List<MonsterAbility> _parseAbilities(dynamic abilitiesData) {
    if (abilitiesData == null) return [];
    
    List<dynamic> abilitiesList;
    if (abilitiesData is List) {
      abilitiesList = abilitiesData;
    } else if (abilitiesData is Map) {
      abilitiesList = [abilitiesData];
    } else {
      return [];
    }
    
    return abilitiesList.map((a) {
      if (a is Map) {
        return MonsterAbility.fromMap(Map<String, dynamic>.from(a));
      } else {
        return MonsterAbility(
          name: 'Unknown Ability',
          description: a.toString(),
        );
      }
    }).toList();
  }

  static List<MonsterAction> _parseActions(dynamic actionsData) {
    if (actionsData == null) return [];
    
    List<dynamic> actionsList;
    if (actionsData is List) {
      actionsList = actionsData;
    } else if (actionsData is Map) {
      actionsList = [actionsData];
    } else {
      return [];
    }
    
    return actionsList.map((a) {
      if (a is Map) {
        return MonsterAction.fromMap(Map<String, dynamic>.from(a));
      } else {
        return MonsterAction(
          name: 'Unknown Action',
          description: a.toString(),
        );
      }
    }).toList();
  }

  static List<LegendaryAction>? _parseLegendaryActions(dynamic actionsData) {
    if (actionsData == null) return null;
    
    List<dynamic> actionsList;
    if (actionsData is List) {
      actionsList = actionsData;
    } else if (actionsData is Map) {
      actionsList = [actionsData];
    } else {
      return null;
    }
    
    return actionsList.map((a) {
      if (a is Map) {
        return LegendaryAction.fromMap(Map<String, dynamic>.from(a));
      } else {
        return LegendaryAction(
          name: 'Unknown Legendary Action',
          description: a.toString(),
        );
      }
    }).toList();
  }

  static List<LairAction>? _parseLairActions(dynamic actionsData) {
    if (actionsData == null) return null;
    
    List<dynamic> actionsList;
    if (actionsData is List) {
      actionsList = actionsData;
    } else if (actionsData is Map) {
      actionsList = [actionsData];
    } else {
      return null;
    }
    
    return actionsList.map((a) {
      if (a is Map) {
        return LairAction.fromMap(Map<String, dynamic>.from(a));
      } else {
        return LairAction(
          name: 'Unknown Lair Action',
          description: a.toString(),
        );
      }
    }).toList();
  }

  // Import von 5e.tools JSON
  factory OfficialMonster.from5eToolsJson(Map<String, dynamic> json) {
    return OfficialMonster(
      name: json['name'],
      size: json['size'],
      type: json['type'],
      subtype: json['subtype'],
      alignment: json['alignment'],
      armorClass: _parseArmorClass(json['ac']),
      hitPoints: json['hp'],
      hitDice: json['hitDice'],
      speed: _parseSpeed(json['speed']),
      strength: json['str'],
      dexterity: json['dex'],
      constitution: json['con'],
      intelligence: json['int'],
      wisdom: json['wis'],
      charisma: json['cha'],
      savingThrows: _parseStringListFromJson(json['save']),
      skills: _parseSkillsFromJson(json['skill']),
      damageVulnerabilities: _parseStringListFromJson(json['vulnerable']),
      damageResistances: _parseStringListFromJson(json['resist']),
      damageImmunities: _parseStringListFromJson(json['immune']),
      conditionImmunities: _parseStringListFromJson(json['conditionImmune']),
      senses: _parseSensesFromJson(json['senses']),
      languages: json['languages'] ?? '',
      challengeRating: _parseChallengeRating(json['cr']),
      xp: json['xp'] ?? 0,
      specialAbilities: _parseAbilitiesFromJson(json['special']),
      actions: _parseActionsFromJson(json['action']),
      legendaryActions: _parseLegendaryActionsFromJson(json['legendary']),
      lairActions: _parseLairActionsFromJson(json['lairActions']),
      description: json['trait'],
      source: json['source'],
      page: json['page'] ?? 1,
    );
  }

  static String _parseArmorClass(dynamic acData) {
    if (acData is String) return acData;
    if (acData is Map) {
      final ac = acData['ac']?.toString() ?? '10';
      final notes = acData['notes']?.toString() ?? '';
      return notes.isNotEmpty ? '$ac ($notes)' : ac;
    }
    return '10';
  }

  static String _parseSpeed(dynamic speedData) {
    if (speedData is String) return speedData;
    if (speedData is Map) {
      final parts = <String>[];
      speedData.forEach((key, value) {
        if (value != null) {
          parts.add('$key $value');
        }
      });
      return parts.join(', ');
    }
    return '30 ft.';
  }

  static Map<String, int> _parseSkillsFromJson(dynamic skillsData) {
    final skills = <String, int>{};
    if (skillsData is Map) {
      skillsData.forEach((key, value) {
        skills[key] = value;
      });
    }
    return skills;
  }

  static Map<String, String> _parseSensesFromJson(dynamic sensesData) {
    final senses = <String, String>{};
    if (sensesData is String) {
      senses['passive'] = sensesData;
    } else if (sensesData is Map) {
      sensesData.forEach((key, value) {
        senses[key] = value.toString();
      });
    }
    return senses;
  }

  static double _parseChallengeRating(dynamic crData) {
    if (crData is String) {
      if (crData.contains('/')) {
        final parts = crData.split('/');
        return double.parse(parts[0]) / double.parse(parts[1]);
      }
      return double.tryParse(crData) ?? 0.0;
    }
    return (crData as num)?.toDouble() ?? 0.0;
  }

  static List<String> _parseStringListFromJson(dynamic data) {
    if (data == null) return [];
    
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    
    if (data is String) {
      // Wenn es ein String ist, könnte es kommagetrennt sein
      return data.split(',').map((s) => s.trim()).toList();
    }
    
    if (data is Map) {
      // Für komplexe Strukturen, die als Map vorliegen
      return data.entries.map((entry) => '${entry.key}: ${entry.value}').toList();
    }
    
    // Fallback: Konvertiere zu String und gib als Liste zurück
    return [data.toString()];
  }

  static List<MonsterAbility> _parseAbilitiesFromJson(dynamic abilitiesData) {
    if (abilitiesData == null) return [];
    
    List<dynamic> abilitiesList;
    if (abilitiesData is List) {
      abilitiesList = abilitiesData;
    } else if (abilitiesData is Map) {
      abilitiesList = [abilitiesData];
    } else {
      return [];
    }
    
    return abilitiesList.map((a) {
      if (a is Map) {
        return MonsterAbility.from5eToolsJson(Map<String, dynamic>.from(a));
      } else {
        return MonsterAbility(
          name: 'Unknown Ability',
          description: a.toString(),
        );
      }
    }).toList();
  }

  static List<MonsterAction> _parseActionsFromJson(dynamic actionsData) {
    if (actionsData == null) return [];
    
    List<dynamic> actionsList;
    if (actionsData is List) {
      actionsList = actionsData;
    } else if (actionsData is Map) {
      actionsList = [actionsData];
    } else {
      return [];
    }
    
    return actionsList.map((a) {
      if (a is Map) {
        return MonsterAction.from5eToolsJson(Map<String, dynamic>.from(a));
      } else {
        return MonsterAction(
          name: 'Unknown Action',
          description: a.toString(),
        );
      }
    }).toList();
  }

  static List<LegendaryAction>? _parseLegendaryActionsFromJson(dynamic actionsData) {
    if (actionsData == null) return null;
    
    List<dynamic> actionsList;
    if (actionsData is List) {
      actionsList = actionsData;
    } else if (actionsData is Map) {
      actionsList = [actionsData];
    } else {
      return null;
    }
    
    return actionsList.map((a) {
      if (a is Map) {
        return LegendaryAction.from5eToolsJson(Map<String, dynamic>.from(a));
      } else {
        return LegendaryAction(
          name: 'Unknown Legendary Action',
          description: a.toString(),
        );
      }
    }).toList();
  }

  static List<LairAction>? _parseLairActionsFromJson(dynamic actionsData) {
    if (actionsData == null) return null;
    
    List<dynamic> actionsList;
    if (actionsData is List) {
      actionsList = actionsData;
    } else if (actionsData is Map) {
      actionsList = [actionsData];
    } else {
      return null;
    }
    
    return actionsList.map((a) {
      if (a is Map) {
        return LairAction.from5eToolsJson(Map<String, dynamic>.from(a));
      } else {
        return LairAction(
          name: 'Unknown Lair Action',
          description: a.toString(),
        );
      }
    }).toList();
  }

  @override
  String toString() {
    return 'OfficialMonster(name: $name, CR: $challengeRating, Type: $type $subtype)';
  }
}

class MonsterAbility {
  final String name;
  final String description;
  final int? usage;

  MonsterAbility({
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

  factory MonsterAbility.fromMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return MonsterAbility(
        name: data['name']?.toString() ?? 'Unknown Ability',
        description: data['description']?.toString() ?? '',
        usage: data['usage'],
      );
    } else if (data is Map) {
      return MonsterAbility(
        name: data['name']?.toString() ?? 'Unknown Ability',
        description: data['description']?.toString() ?? '',
        usage: data['usage'],
      );
    } else {
      return MonsterAbility(
        name: 'Unknown Ability',
        description: data?.toString() ?? '',
      );
    }
  }

  factory MonsterAbility.from5eToolsJson(Map<String, dynamic> json) {
    return MonsterAbility(
      name: json['name'],
      description: json['entries']?.join('\n') ?? json['text'] ?? '',
      usage: json['usage'],
    );
  }
}

class MonsterAction {
  final String name;
  final String description;
  final String? attackBonus;
  final String? damage;
  final String? damageType;

  MonsterAction({
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

  factory MonsterAction.fromMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return MonsterAction(
        name: data['name']?.toString() ?? 'Unknown Action',
        description: data['description']?.toString() ?? '',
        attackBonus: data['attack_bonus']?.toString(),
        damage: data['damage']?.toString(),
        damageType: data['damage_type']?.toString(),
      );
    } else if (data is Map) {
      return MonsterAction(
        name: data['name']?.toString() ?? 'Unknown Action',
        description: data['description']?.toString() ?? '',
        attackBonus: data['attack_bonus']?.toString(),
        damage: data['damage']?.toString(),
        damageType: data['damage_type']?.toString(),
      );
    } else {
      return MonsterAction(
        name: 'Unknown Action',
        description: data?.toString() ?? '',
      );
    }
  }

  factory MonsterAction.from5eToolsJson(Map<String, dynamic> json) {
    final entries = json['entries'] ?? [];
    final description = entries is List ? entries.join('\n') : entries.toString();
    
    String? attackBonus;
    String? damage;
    String? damageType;

    if (json['entries'] is List) {
      for (final entry in json['entries']) {
        if (entry is Map && entry['type'] == 'attack') {
          attackBonus = entry['attackBonus'];
          damage = entry['damage'];
          damageType = entry['damageType'];
        }
      }
    }

    return MonsterAction(
      name: json['name'],
      description: description,
      attackBonus: attackBonus,
      damage: damage,
      damageType: damageType,
    );
  }
}

class LegendaryAction {
  final String name;
  final String description;
  final int? cost;

  LegendaryAction({
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

  factory LegendaryAction.fromMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return LegendaryAction(
        name: data['name']?.toString() ?? 'Unknown Legendary Action',
        description: data['description']?.toString() ?? '',
        cost: data['cost'],
      );
    } else if (data is Map) {
      return LegendaryAction(
        name: data['name']?.toString() ?? 'Unknown Legendary Action',
        description: data['description']?.toString() ?? '',
        cost: data['cost'],
      );
    } else {
      return LegendaryAction(
        name: 'Unknown Legendary Action',
        description: data?.toString() ?? '',
      );
    }
  }

  factory LegendaryAction.from5eToolsJson(Map<String, dynamic> json) {
    return LegendaryAction(
      name: json['name'],
      description: json['entries']?.join('\n') ?? json['text'] ?? '',
      cost: json['cost'],
    );
  }
}

class LairAction {
  final String name;
  final String description;

  LairAction({
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  factory LairAction.fromMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return LairAction(
        name: data['name']?.toString() ?? 'Unknown Lair Action',
        description: data['description']?.toString() ?? '',
      );
    } else if (data is Map) {
      return LairAction(
        name: data['name']?.toString() ?? 'Unknown Lair Action',
        description: data['description']?.toString() ?? '',
      );
    } else {
      return LairAction(
        name: 'Unknown Lair Action',
        description: data?.toString() ?? '',
      );
    }
  }

  factory LairAction.from5eToolsJson(Map<String, dynamic> json) {
    return LairAction(
      name: json['name'],
      description: json['entries']?.join('\n') ?? json['text'] ?? '',
    );
  }
}
