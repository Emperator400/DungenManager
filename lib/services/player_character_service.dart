// Dart Core
import 'dart:convert';

// Eigene Projekte
import '../models/player_character.dart';
import '../models/attack.dart';
import '../models/inventory_item.dart';

/// Service für die Verwaltung von Player Characters
class PlayerCharacterService {
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
      // Ignoriere Fehler bei der Deserialisierung
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
          .map((attackMap) => Attack.fromMap(attackMap as Map<String, dynamic>))
          .where((attack) => attack != null)
          .cast<Attack>()
          .toList();
    } catch (e) {
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
          .map((itemMap) => InventoryItem.fromMap(itemMap as Map<String, dynamic>))
          .where((item) => item != null)
          .cast<InventoryItem>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Formatiert Angriffe als String
  static String formatAttacks(PlayerCharacter character) {
    if (character.attackList.isNotEmpty) {
      // TODO: Implementiere AttackFormatter wenn verfügbar
      return character.attackList.map((a) => a.name).join(', ');
    }
    return character.attacks ?? '';
  }

  /// Gibt effektive Angriffsliste zurück
  static List<Attack> getEffectiveAttacks(PlayerCharacter character) {
    if (character.attackList.isNotEmpty) {
      return character.attackList;
    }
    // TODO: Implementiere AttackParser wenn Legacy-String genutzt wird
    return [];
  }

  /// Validiert PlayerCharacter Daten
  static bool isValidPlayerCharacter(PlayerCharacter character) {
    return character.name.isNotEmpty && 
           character.playerName.isNotEmpty &&
           character.className.isNotEmpty &&
           character.raceName.isNotEmpty &&
           character.level > 0 &&
           character.maxHp > 0;
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
}
