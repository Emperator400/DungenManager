// lib/models/official_spell.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class OfficialSpell {
  final String id;
  final String name;
  final int level;
  final String school;
  final bool ritual;
  final String castingTime;
  final String range;
  final String duration;
  final SpellComponents components;
  final String? materials;
  final String description;
  final String? higherLevels;
  final List<String> classes;
  final String source;
  final int page;
  final bool isCustom;
  final String? version;
  final Map<String, dynamic>? customData;

  OfficialSpell({
    String? id,
    required this.name,
    required this.level,
    required this.school,
    this.ritual = false,
    required this.castingTime,
    required this.range,
    required this.duration,
    required this.components,
    this.materials,
    required this.description,
    this.higherLevels,
    this.classes = const [],
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
      'level': level,
      'school': school,
      'ritual': ritual ? 1 : 0,
      'casting_time': castingTime,
      'range': range,
      'duration': duration,
      'components': components.toMap(),
      'materials': materials,
      'description': description,
      'higher_levels': higherLevels,
      'classes': classes.isNotEmpty ? classes.join(',') : null,
      'source': source,
      'page': page,
      'is_custom': isCustom ? 1 : 0,
      'version': version,
      'custom_data': customData,
    };
  }

  // Erstellung aus Datenbank
  factory OfficialSpell.fromMap(Map<String, dynamic> map) {
    return OfficialSpell(
      id: map['id'],
      name: map['name'],
      level: map['level'],
      school: map['school'],
      ritual: map['ritual'] == 1,
      castingTime: map['casting_time'],
      range: map['range'],
      duration: map['duration'],
      components: SpellComponents.fromMap(map['components']),
      materials: map['materials'],
      description: map['description'],
      higherLevels: map['higher_levels'],
      classes: map['classes']?.toString().split(',') ?? [],
      source: map['source'],
      page: map['page'] ?? 1,
      isCustom: map['is_custom'] == 1,
      version: map['version'],
      customData: map['custom_data'],
    );
  }

  // Import von 5e.tools JSON
  factory OfficialSpell.from5eToolsJson(Map<String, dynamic> json) {
    return OfficialSpell(
      name: json['name'],
      level: json['level'],
      school: json['school'],
      ritual: json['ritual'] ?? false,
      castingTime: _parseCastingTime(json['time']),
      range: _parseRange(json['range']),
      duration: _parseDuration(json['duration']),
      components: _parseComponents(json['components']),
      materials: _parseMaterials(json['components']),
      description: _parseDescription(json['entries']),
      higherLevels: _parseHigherLevels(json['entriesHigher']),
      classes: _parseClasses(json['classes']),
      source: json['source'],
      page: json['page'] ?? 1,
    );
  }

  static String _parseCastingTime(dynamic timeData) {
    if (timeData is String) return timeData;
    if (timeData is List && timeData.isNotEmpty) {
      final time = timeData.first;
      if (time is Map) {
        final unit = time['unit'] ?? 'action';
        final number = time['number'] ?? 1;
        return '$number $unit';
      }
    }
    return '1 action';
  }

  static String _parseRange(dynamic rangeData) {
    if (rangeData is String) return rangeData;
    if (rangeData is Map) {
      final type = rangeData['type'] ?? '';
      final distance = rangeData['distance'] ?? {};
      if (distance is Map) {
        final amount = distance['amount'] ?? 0;
        final unit = distance['unit'] ?? 'feet';
        return '$amount $unit';
      }
      return type;
    }
    return '60 feet';
  }

  static String _parseDuration(dynamic durationData) {
    if (durationData is String) return durationData;
    if (durationData is List && durationData.isNotEmpty) {
      final duration = durationData.first;
      if (duration is Map) {
        final type = duration['type'] ?? 'instant';
        final concentration = duration['concentration'] ?? false;
        final time = duration['duration'] ?? {};
        
        String result = '';
        if (concentration) result += 'Concentration, ';
        
        if (time is Map) {
          final type = time['type'] ?? 'instant';
          final amount = time['amount'] ?? 0;
          final unit = time['unit'] ?? '';
          if (type == 'instant') {
            result += 'Instantaneous';
          } else if (type == 'timed') {
            result += 'Up to $amount $unit';
          } else {
            result += '$amount $unit';
          }
        } else {
          result += type;
        }
        
        return result;
      }
    }
    return 'Instantaneous';
  }

  static SpellComponents _parseComponents(dynamic componentsData) {
    bool verbal = false;
    bool somatic = false;
    String? material;

    if (componentsData is List) {
      for (final component in componentsData) {
        if (component is String) {
          if (component == 'V') verbal = true;
          if (component == 'S') somatic = true;
          if (component.startsWith('M')) material = component;
        } else if (component is Map) {
          final type = component['type'];
          if (type == 'V') verbal = true;
          if (type == 'S') somatic = true;
          if (type == 'M') {
            material = component['text'] ?? 'M';
          }
        }
      }
    }

    return SpellComponents(
      verbal: verbal,
      somatic: somatic,
      material: material,
    );
  }

  static String? _parseMaterials(dynamic componentsData) {
    if (componentsData is List) {
      for (final component in componentsData) {
        if (component is Map && component['type'] == 'M') {
          return component['text'];
        } else if (component is String && component.startsWith('M')) {
          return component.substring(2).trim(); // Remove "M " prefix
        }
      }
    }
    return null;
  }

  static String _parseDescription(dynamic entriesData) {
    if (entriesData is List) {
      return entriesData.map((entry) {
        if (entry is String) return entry;
        if (entry is Map && entry['type'] == 'entries') {
          return (entry['entries'] as List).join('\n');
        }
        return entry.toString();
      }).join('\n\n');
    }
    return entriesData?.toString() ?? '';
  }

  static String? _parseHigherLevels(dynamic higherLevelsData) {
    if (higherLevelsData is List && higherLevelsData.isNotEmpty) {
      final higherLevel = higherLevelsData.first;
      if (higherLevel is Map && higherLevel['entries'] is List) {
        return (higherLevel['entries'] as List).join('\n');
      }
      return higherLevel.toString();
    }
    return null;
  }

  static List<String> _parseClasses(dynamic classesData) {
    final classes = <String>[];
    if (classesData is Map) {
      classesData.forEach((className, classInfo) {
        classes.add(className);
      });
    } else if (classesData is List) {
      for (final classInfo in classesData) {
        if (classInfo is Map) {
          classes.add(classInfo['name'] ?? classInfo['class']);
        } else if (classInfo is String) {
          classes.add(classInfo);
        }
      }
    }
    return classes;
  }

  @override
  String toString() {
    return 'OfficialSpell(name: $name, Level: $level, School: $school)';
  }
}

class SpellComponents {
  final bool verbal;
  final bool somatic;
  final String? material;

  SpellComponents({
    required this.verbal,
    required this.somatic,
    this.material,
  });

  Map<String, dynamic> toMap() {
    return {
      'verbal': verbal ? 1 : 0,
      'somatic': somatic ? 1 : 0,
      'material': material,
    };
  }

  factory SpellComponents.fromMap(Map<String, dynamic> map) {
    return SpellComponents(
      verbal: map['verbal'] == 1,
      somatic: map['somatic'] == 1,
      material: map['material'],
    );
  }

  String get displayString {
    final parts = <String>[];
    if (verbal) parts.add('V');
    if (somatic) parts.add('S');
    if (material != null) parts.add('M');
    return parts.join(', ');
  }

  @override
  String toString() {
    return displayString;
  }
}

// Hilfs-Enums für Spell-Daten
enum SpellSchool {
  abjuration,
  conjuration,
  divination,
  enchantment,
  evocation,
  illusion,
  necromancy,
  transmutation,
}

extension SpellSchoolExtension on SpellSchool {
  String get displayName {
    switch (this) {
      case SpellSchool.abjuration:
        return 'Abjuration';
      case SpellSchool.conjuration:
        return 'Conjuration';
      case SpellSchool.divination:
        return 'Divination';
      case SpellSchool.enchantment:
        return 'Enchantment';
      case SpellSchool.evocation:
        return 'Evocation';
      case SpellSchool.illusion:
        return 'Illusion';
      case SpellSchool.necromancy:
        return 'Necromancy';
      case SpellSchool.transmutation:
        return 'Transmutation';
    }
  }
}

enum SpellCastingTime {
  action,
  bonusAction,
  reaction,
  minute,
  hour,
  special,
}

enum SpellRange {
  self,
  touch,
  feet,
  miles,
  sight,
  unlimited,
  special,
}

enum SpellDuration {
  instantaneous,
  concentration,
  timed,
  permanent,
  special,
}
