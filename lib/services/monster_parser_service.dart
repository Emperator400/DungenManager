import '../models/official_monster.dart';

/// Service für das Parsen von Monster-Daten aus verschiedenen Quellen
class MonsterParserService {
  /// Parst Skills aus String-Format "skill:value,skill2:value2"
  static Map<String, int> parseSkills(dynamic skillsData) {
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

  /// Parst Senses aus String-Format "sense:value,sense2:value2"
  static Map<String, String> parseSenses(dynamic sensesData) {
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

  /// Parst Abilities aus dynamischen Daten
  static List<MonsterAbility> parseAbilities(dynamic abilitiesData) {
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

  /// Parst Actions aus dynamischen Daten
  static List<MonsterAction> parseActions(dynamic actionsData) {
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

  /// Parst Legendary Actions aus dynamischen Daten
  static List<LegendaryAction>? parseLegendaryActions(dynamic actionsData) {
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

  /// Parst Lair Actions aus dynamischen Daten
  static List<LairAction>? parseLairActions(dynamic actionsData) {
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
}
