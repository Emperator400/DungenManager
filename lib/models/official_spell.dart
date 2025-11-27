// lib/models/official_spell.dart
import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

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
  }) : id = id ?? UuidService().generateId();

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
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', 'Unknown Spell'),
      level: ModelParsingHelper.safeInt(map, 'level', 0),
      school: ModelParsingHelper.safeString(map, 'school', 'Unknown'),
      ritual: ModelParsingHelper.safeBool(map, 'ritual', false),
      castingTime: ModelParsingHelper.safeString(map, 'casting_time', '1 action'),
      range: ModelParsingHelper.safeString(map, 'range', 'Self'),
      duration: ModelParsingHelper.safeString(map, 'duration', 'Instantaneous'),
      components: SpellComponents.fromMap(map['components'] is Map ? map['components'] as Map<String, dynamic> : {}),
      materials: ModelParsingHelper.safeStringOrNull(map, 'materials', null),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      higherLevels: ModelParsingHelper.safeStringOrNull(map, 'higher_levels', null),
      classes: ModelParsingHelper.safeString(map, 'classes', '').split(',').where((s) => s.isNotEmpty).toList(),
      source: ModelParsingHelper.safeString(map, 'source', 'Unknown'),
      page: ModelParsingHelper.safeInt(map, 'page', 1),
      isCustom: ModelParsingHelper.safeBool(map, 'is_custom', false),
      version: ModelParsingHelper.safeStringOrNull(map, 'version', null),
      customData: map['custom_data'] is Map ? map['custom_data'] as Map<String, dynamic> : null,
    );
  }

  // Import von 5e.tools JSON
  factory OfficialSpell.from5eToolsJson(Map<String, dynamic> json) {
    return OfficialSpell(
      name: ModelParsingHelper.safeString(json, 'name', 'Unknown Spell'),
      level: ModelParsingHelper.safeInt(json, 'level', 0),
      school: ModelParsingHelper.safeString(json, 'school', 'Unknown'),
      ritual: ModelParsingHelper.safeBool(json, 'ritual', false),
      castingTime: _parseCastingTime(json['time']),
      range: _parseRange(json['range']),
      duration: _parseDuration(json['duration']),
      components: _parseComponents(json['components']),
      materials: _parseMaterials(json['components']),
      description: _parseDescription(json['entries']),
      higherLevels: _parseHigherLevels(json['entriesHigher']),
      classes: _parseClasses(json['classes']),
      source: ModelParsingHelper.safeString(json, 'source', 'Unknown'),
      page: ModelParsingHelper.safeInt(json, 'page', 1),
    );
  }

  static String _parseCastingTime(dynamic timeData) {
    if (timeData is String) return timeData;
    if (timeData is List && timeData.isNotEmpty) {
      final time = timeData.first;
      if (time is Map<String, dynamic>) {
        final unit = ModelParsingHelper.safeString(time, 'unit', 'action');
        final number = ModelParsingHelper.safeInt(time, 'number', 1);
        return '$number $unit';
      }
    }
    return '1 action';
  }

  static String _parseRange(dynamic rangeData) {
    if (rangeData is String) return rangeData;
    if (rangeData is Map<String, dynamic>) {
      final distance = rangeData['distance'] as Map? ?? {};
        if (distance is Map<String, dynamic>) {
          final amount = ModelParsingHelper.safeInt(distance, 'amount', 0);
          final unit = ModelParsingHelper.safeString(distance, 'unit', 'feet');
          return '$amount $unit';
        }
        return ModelParsingHelper.safeString(rangeData, 'type', '');
    }
    return '60 feet';
  }

  static String _parseDuration(dynamic durationData) {
    if (durationData is String) return durationData;
    if (durationData is List && durationData.isNotEmpty) {
      final duration = durationData.first;
      if (duration is Map<String, dynamic>) {
        final concentration = ModelParsingHelper.safeBool(duration, 'concentration', false);
        final time = duration['duration'] as Map<String, dynamic>? ?? {};
        
        String result = '';
        if (concentration) result += 'Concentration, ';
        
        final timeType = ModelParsingHelper.safeString(time, 'type', 'instant');
        final amount = ModelParsingHelper.safeInt(time, 'amount', 0);
        final unit = ModelParsingHelper.safeString(time, 'unit', '');
        if (timeType == 'instant') {
          result += 'Instantaneous';
        } else if (timeType == 'timed') {
          result += 'Up to $amount $unit';
        } else {
          result += '$amount $unit';
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
        } else if (component is Map<String, dynamic>) {
          final type = ModelParsingHelper.safeString(component, 'type', '');
          if (type == 'V') verbal = true;
          if (type == 'S') somatic = true;
          if (type == 'M') {
            material = ModelParsingHelper.safeString(component, 'text', 'M');
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
        if (component is Map<String, dynamic> && component['type'] == 'M') {
          return ModelParsingHelper.safeString(component, 'text', 'M');
        } else if (component is String && component.startsWith('M')) {
          return component.length > 2 ? component.substring(2).trim() : component; // Remove "M " prefix safely
        }
      }
    }
    return null;
  }

  static String _parseDescription(dynamic entriesData) {
    if (entriesData is List) {
      return entriesData.map((entry) {
        if (entry is String) return entry;
        if (entry is Map<String, dynamic> && entry['type'] == 'entries') {
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
      if (higherLevel is Map<String, dynamic> && higherLevel['entries'] is List) {
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
        classes.add(className.toString());
      });
    } else if (classesData is List) {
      for (final classInfo in classesData) {
        if (classInfo is Map<String, dynamic>) {
          classes.add(ModelParsingHelper.safeString(classInfo, 'name', ModelParsingHelper.safeString(classInfo, 'class', 'Unknown')));
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
      verbal: ModelParsingHelper.safeBool(map, 'verbal', false),
      somatic: ModelParsingHelper.safeBool(map, 'somatic', false),
      material: ModelParsingHelper.safeStringOrNull(map, 'material', null),
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
