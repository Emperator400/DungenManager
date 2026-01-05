// lib/services/player_character_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/player_character.dart';
import '../models/attack.dart';
import '../models/inventory_item.dart';

/// Service für die Verwaltung von Player Characters mit Repository-Architektur
/// 
/// Bietet erweiterte Funktionalität für Charakterverwaltung.
/// Dieser Service ist ein Utility-Service mit statischen Methoden.
/// Direkte Repository-Operationen sollten in den ViewModels erfolgen.
class PlayerCharacterService {
  // Verhindere Instanziierung - nur statische Methoden
  PlayerCharacterService._();

  /// Serialisiert Skills für Datenbank
  static String serializeSkills(List<String> skills) {
    return jsonEncode(skills);
  }

  /// Deserialisiert Skills aus Datenbank
  static List<String> deserializeSkills(String? skillsString) {
    if (skillsString == null || skillsString.isEmpty) return [];
    try {
      final decoded = jsonDecode(skillsString);
      if (decoded is List) {
        return List<String>.from(decoded);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Skills-Deserialisierung: $e');
      }
    }
    return [];
  }

  /// Serialisiert Attack List für Datenbank
  static String serializeAttackList(List<Attack> attacks) {
    if (attacks.isEmpty) return jsonEncode([]);
    return jsonEncode(attacks.map((attack) => attack.toMap()).toList());
  }

  /// Deserialisiert Attack List aus Datenbank
  static List<Attack> deserializeAttackList(dynamic attackData) {
    if (attackData == null) return [];
    
    try {
      List<dynamic> decodedList;
      if (attackData is String) {
        decodedList = jsonDecode(attackData) as List<dynamic>;
      } else if (attackData is List) {
        decodedList = attackData as List<dynamic>;
      } else {
        return [];
      }
      
      return decodedList
          .where((attackMap) => attackMap != null && attackMap is Map<String, dynamic>)
          .map((attackMap) {
            try {
              return Attack.fromMap(attackMap as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                print('Fehler bei Attack-Konvertierung: $e');
              }
              return null;
            }
          })
          .where((attack) => attack != null)
          .cast<Attack>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Attacken-Deserialisierung: $e');
      }
      return [];
    }
  }

  /// Serialisiert Inventory für Datenbank
  static String serializeInventory(List<InventoryItem> inventory) {
    if (inventory.isEmpty) return jsonEncode([]);
    return jsonEncode(inventory.map((item) => item.toMap()).toList());
  }

  /// Deserialisiert Inventory aus Datenbank
  static List<InventoryItem> deserializeInventory(dynamic inventoryData) {
    if (inventoryData == null) return [];
    
    try {
      List<dynamic> decodedList;
      if (inventoryData is String) {
        decodedList = jsonDecode(inventoryData) as List<dynamic>;
      } else if (inventoryData is List) {
        decodedList = inventoryData as List<dynamic>;
      } else {
        return [];
      }
      
      return decodedList
          .where((itemMap) => itemMap != null && itemMap is Map<String, dynamic>)
          .map((itemMap) {
            try {
              return InventoryItem.fromMap(itemMap as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                print('Fehler bei InventoryItem-Konvertierung: $e');
              }
              return null;
            }
          })
          .where((item) => item != null)
          .cast<InventoryItem>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Fehler bei Inventory-Deserialisierung: $e');
      }
      return [];
    }
  }

  /// Formatiert Attacken als String
  static String formatAttacks(PlayerCharacter character) {
    if (character.attackList.isNotEmpty) {
      return character.attackList.map((attack) => attack.toString()).join('\n');
    }
    
    // Fallback auf Legacy-String
    if (character.attacks?.isNotEmpty == true) {
      return character.attacks!;
    }
    
    return '';
  }

  /// Berechnet Modifier für Attribut
  static int getAbilityModifier(int abilityScore) {
    return ((abilityScore - 10) ~/ 2);
  }

  /// Formatiert PlayerCharacter für Anzeige
  static String formatPlayerCharacter(PlayerCharacter character) {
    final buffer = StringBuffer();
    buffer.writeln('PlayerCharacter: ${character.name}');
    buffer.writeln('  Player: ${character.playerName}');
    buffer.writeln('  Class: ${character.className}');
    buffer.writeln('  Race: ${character.raceName}');
    buffer.writeln('  Level: ${character.level}');
    buffer.writeln('  HP: ${character.maxHp}');
    buffer.writeln('  AC: ${character.armorClass}');
    buffer.writeln('  Campaign: ${character.campaignId}');
    
    if (character.imagePath != null) {
      buffer.writeln('  Has Image: Yes');
    }
    
    buffer.writeln('  Attributes:');
    buffer.writeln('    STR: ${character.strength} (+${getAbilityModifier(character.strength)})');
    buffer.writeln('    DEX: ${character.dexterity} (+${getAbilityModifier(character.dexterity)})');
    buffer.writeln('    CON: ${character.constitution} (+${getAbilityModifier(character.constitution)})');
    buffer.writeln('    INT: ${character.intelligence} (+${getAbilityModifier(character.intelligence)})');
    buffer.writeln('    WIS: ${character.wisdom} (+${getAbilityModifier(character.wisdom)})');
    buffer.writeln('    CHA: ${character.charisma} (+${getAbilityModifier(character.charisma)})');
    
    if (character.proficientSkills.isNotEmpty) {
      buffer.writeln('  Skills: ${character.proficientSkills.join(', ')}');
    }
    
    if (character.attackList.isNotEmpty) {
      buffer.writeln('  Attacks: ${character.attackList.length}');
    }
    
    if (character.inventory.isNotEmpty) {
      buffer.writeln('  Inventory: ${character.inventory.length} items');
    }
    
    buffer.writeln('  Gold: ${character.gold}');
    buffer.writeln('  Silver: ${character.silver}');
    buffer.writeln('  Copper: ${character.copper}');
    
    return buffer.toString();
  }

  // ========== STATISCHE HELPER METHODEN ==========

  /// Formatiert Charakter-Statistiken
  static String formatCharacterStats(Map<String, dynamic> stats) {
    final buffer = StringBuffer();
    buffer.writeln('Charakter-Statistiken:');
    buffer.writeln('Gesamtzahl: ${stats['totalCharacters']}');
    buffer.writeln('Durchschnittliches Level: ${stats['averageLevel']}');
    
    if (stats['levelDistribution'] != null) {
      buffer.writeln('\nLevel-Verteilung:');
      final levelDist = stats['levelDistribution'] as Map<int, int>;
      final sortedLevels = levelDist.keys.toList()..sort();
      for (final level in sortedLevels) {
        buffer.writeln('  Level $level: ${levelDist[level]} Charaktere');
      }
    }
    
    if (stats['classDistribution'] != null) {
      buffer.writeln('\nKlassen-Verteilung:');
      final classDist = stats['classDistribution'] as Map<String, int>;
      for (final entry in classDist.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value} Charaktere');
      }
    }
    
    if (stats['raceDistribution'] != null) {
      buffer.writeln('\nRassen-Verteilung:');
      final raceDist = stats['raceDistribution'] as Map<String, int>;
      for (final entry in raceDist.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value} Charaktere');
      }
    }
    
    return buffer.toString();
  }

  /// Validiert Charakter-Name
  static bool isValidCharacterName(String name) {
    if (name.isEmpty) return false;
    if (name.length > 50) return false;
    // Erlaube Buchstaben, Zahlen, Leerzeichen und einige Sonderzeichen
    final validPattern = RegExp(r'^[a-zA-ZäöüßÄÖÜ0-9\s\-\_\.]+$');
    return validPattern.hasMatch(name);
  }

  /// Gibt empfohlene Attribute für Klasse zurück
  static Map<String, int> getRecommendedAttributes(String className) {
    return switch (className.toLowerCase()) {
      'fighter' || 'krieger' => {
        'strength': 15,
        'dexterity': 13,
        'constitution': 14,
        'intelligence': 10,
        'wisdom': 12,
        'charisma': 10,
      },
      'wizard' || 'magier' => {
        'strength': 8,
        'dexterity': 14,
        'constitution': 12,
        'intelligence': 15,
        'wisdom': 13,
        'charisma': 10,
      },
      'rogue' || 'schurke' => {
        'strength': 10,
        'dexterity': 15,
        'constitution': 12,
        'intelligence': 12,
        'wisdom': 10,
        'charisma': 14,
      },
      'cleric' || 'kleriker' => {
        'strength': 12,
        'dexterity': 10,
        'constitution': 14,
        'intelligence': 10,
        'wisdom': 15,
        'charisma': 13,
      },
      _ => {
        'strength': 12,
        'dexterity': 12,
        'constitution': 12,
        'intelligence': 12,
        'wisdom': 12,
        'charisma': 12,
      },
    };
  }

  /// Berechnet HP für Level-Up
  static int calculateHpIncrease(int constitution, int hitDie) {
    final modifier = ((constitution - 10) ~/ 2);
    return ((hitDie ~/ 2) + 1) + modifier;
  }

  /// Formatiert Modifikatoren als String
  static String formatModifier(int modifier) {
    if (modifier >= 0) {
      return '+$modifier';
    } else {
      return modifier.toString();
    }
  }
}
