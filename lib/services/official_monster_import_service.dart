import '../models/official_monster.dart';
import 'uuid_service.dart';

/// Service für den Import von OfficialMonster aus 5e.tools JSON
class OfficialMonsterImportService {
  /// Importiert Monster aus 5e.tools JSON Format
  static OfficialMonster from5eToolsJson(Map<String, dynamic> json) {
    return OfficialMonster(
      id: UuidService().generateId(),
      name: json['name'] as String? ?? '',
      size: json['size'] as String? ?? '',
      type: json['type'] as String? ?? '',
      subtype: json['subtype'] as String?,
      alignment: json['alignment'] as String? ?? '',
      armorClass: _parseArmorClass(json['ac']),
      hitPoints: json['hp'] as int? ?? 0,
      hitDice: json['hitDice'] as String? ?? '',
      speed: _parseSpeed(json['speed']),
      strength: json['str'] as int? ?? 10,
      dexterity: json['dex'] as int? ?? 10,
      constitution: json['con'] as int? ?? 10,
      intelligence: json['int'] as int? ?? 10,
      wisdom: json['wis'] as int? ?? 10,
      charisma: json['cha'] as int? ?? 10,
      savingThrows: _parseStringListFromJson(json['save']),
      skills: _parseSkillsFromJson(json['skill']),
      damageVulnerabilities: _parseStringListFromJson(json['vulnerable']),
      damageResistances: _parseStringListFromJson(json['resist']),
      damageImmunities: _parseStringListFromJson(json['immune']),
      conditionImmunities: _parseStringListFromJson(json['conditionImmune']),
      senses: _parseSensesFromJson(json['senses']),
      languages: json['languages'] as String? ?? '',
      challengeRating: _parseChallengeRating(json['cr']),
      xp: json['xp'] as int? ?? 0,
      specialAbilities: _parseAbilitiesFromJson(json['trait']),
      actions: _parseActionsFromJson(json['action']),
      legendaryActions: _parseLegendaryActionsFromJson(json['legendary']),
      lairActions: _parseLairActionsFromJson(json['lairActions']),
      description: json['trait'] as String?,
      source: json['source'] as String? ?? '',
      page: json['page'] as int? ?? 1,
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
        if (value != null && value.toString().isNotEmpty) {
          parts.add('$key $value');
        }
      });
      return parts.isNotEmpty ? parts.join(', ') : '30 ft.';
    }
    return '30 ft.';
  }

  static Map<String, int> _parseSkillsFromJson(dynamic skillsData) {
    final skills = <String, int>{};
    if (skillsData is Map) {
      skillsData.forEach((key, value) => skills[key.toString()] = value as int);
    }
    return skills;
  }

  static Map<String, String> _parseSensesFromJson(dynamic sensesData) {
    final senses = <String, String>{};
    if (sensesData is String) {
      senses['passive'] = sensesData;
    } else if (sensesData is Map) {
      sensesData.forEach((key, value) => senses[key.toString()] = value.toString());
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
    return (crData as num?)?.toDouble() ?? 0.0;
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
      return data.entries.map((entry) => '${entry.key.toString()}: ${entry.value}').toList();
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
    
    return abilitiesList.map((a) => a is Map 
        ? MonsterAbility.from5eToolsJson(Map<String, dynamic>.from(a))
        : MonsterAbility(
            name: 'Unknown Ability',
            description: a.toString(),
          )).toList();
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
    
    return actionsList.map((a) => a is Map 
        ? MonsterAction.from5eToolsJson(Map<String, dynamic>.from(a))
        : MonsterAction(
            name: 'Unknown Action',
            description: a.toString(),
          )).toList();
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
    
    return actionsList.map((a) => a is Map 
        ? LegendaryAction.from5eToolsJson(Map<String, dynamic>.from(a))
        : LegendaryAction(
            name: 'Unknown Legendary Action',
            description: a.toString(),
          )).toList();
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
    
    return actionsList.map((a) => a is Map 
        ? LairAction.from5eToolsJson(Map<String, dynamic>.from(a))
        : LairAction(
            name: 'Unknown Lair Action',
            description: a.toString(),
          )).toList();
  }
}
