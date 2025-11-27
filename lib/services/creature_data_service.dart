// Dart Core
import 'dart:convert';

// Eigene Projekte
import '../models/attack.dart';
import 'exceptions/service_exceptions.dart';

/// Service für die Datenverarbeitung von Creature-Objekten
/// Verwendet spezifische Exceptions und ServiceResult Pattern.
class CreatureDataService {
  // ===========================================================================
  // PARSING OPERATIONS
  // ===========================================================================

  /// Parst Attack-Liste sicher aus verschiedenen Datenformaten
  static ServiceResult<List<Attack>> parseAttackList(dynamic attackListData) {
    try {
      if (attackListData == null) {
        return ServiceResult.success(<Attack>[], operation: 'parseAttackList');
      }
      
      List<dynamic> decodedList;
      if (attackListData is String) {
        // Neues Format: JSON-String
        decodedList = jsonDecode(attackListData) as List<dynamic>;
      } else if (attackListData is List) {
        // Altes Format: direkte Liste (für Abwärtskompatibilität)
        decodedList = attackListData as List<dynamic>;
      } else {
        decodedList = [];
      }
      
      final attacks = decodedList
          .where((attackMap) => attackMap != null && attackMap is Map<String, dynamic>)
          .map((attackMap) => Attack.fromMap(attackMap as Map<String, dynamic>))
          .where((attack) => attack != null)
          .cast<Attack>()
          .toList();

      if (attacks.isEmpty && decodedList.isNotEmpty) {
        final dataException = DataProcessingException(
          'Angriffsliste konnte nicht geparst werden - ungültiges Format',
          operation: 'parseAttackList',
        );
        return ServiceResult.unexpectedError(dataException, operation: 'parseAttackList');
      }

      return ServiceResult.success(attacks, operation: 'parseAttackList');
    } on FormatException catch (e) {
      final dataException = DataProcessingException.fromJsonError('parseAttackList', e);
      return ServiceResult.unexpectedError(dataException, operation: 'parseAttackList');
    } catch (e) {
      return ServiceResult.unexpectedError(e, operation: 'parseAttackList');
    }
  }

  /// Parst Inventar sicher aus verschiedenen Datenformaten
  static ServiceResult<List<Map<String, dynamic>>> parseInventory(dynamic inventoryData) {
    try {
      if (inventoryData == null) {
        return ServiceResult.success(<Map<String, dynamic>>[], operation: 'parseInventory');
      }
      
      List<dynamic> decodedList;
      if (inventoryData is String) {
        // Neues Format: JSON-String
        decodedList = jsonDecode(inventoryData) as List<dynamic>;
      } else if (inventoryData is List) {
        // Altes Format: direkte Liste (für Abwärtskompatibilität)
        decodedList = inventoryData as List<dynamic>;
      } else {
        decodedList = [];
      }
      
      final inventory = decodedList
          .where((itemMap) => itemMap != null && itemMap is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();

      if (inventory.isEmpty && decodedList.isNotEmpty) {
        final dataException = DataProcessingException(
          'Inventar konnte nicht geparst werden - ungültiges Format',
          operation: 'parseInventory',
        );
        return ServiceResult.unexpectedError(dataException, operation: 'parseInventory');
      }

      return ServiceResult.success(inventory, operation: 'parseInventory');
    } on FormatException catch (e) {
      final dataException = DataProcessingException.fromJsonError('parseInventory', e);
      return ServiceResult.unexpectedError(dataException, operation: 'parseInventory');
    } catch (e) {
      return ServiceResult.unexpectedError(e, operation: 'parseInventory');
    }
  }

  // ===========================================================================
  // SERIALIZATION OPERATIONS
  // ===========================================================================

  /// Serialisiert Attack-Liste für Datenbank-Speicherung
  static ServiceResult<String> serializeAttackList(List<Attack> attackList) {
    try {
      if (attackList.isEmpty) {
        return ServiceResult.success(jsonEncode([]), operation: 'serializeAttackList');
      }

      final serialized = jsonEncode(attackList.map((attack) => attack.toMap()).toList());
      return ServiceResult.success(serialized, operation: 'serializeAttackList');
    } catch (e) {
      final dataException = DataProcessingException(
        'Fehler bei der Serialisierung der Attack-Liste: $e',
        operation: 'serializeAttackList',
      );
      return ServiceResult.unexpectedError(dataException, operation: 'serializeAttackList');
    }
  }

  /// Serialisiert Inventar für Datenbank-Speicherung
  static ServiceResult<String> serializeInventory(List<Map<String, dynamic>> inventory) {
    try {
      if (inventory.isEmpty) {
        return ServiceResult.success(jsonEncode([]), operation: 'serializeInventory');
      }

      final serialized = jsonEncode(inventory);
      return ServiceResult.success(serialized, operation: 'serializeInventory');
    } catch (e) {
      final dataException = DataProcessingException(
        'Fehler bei der Serialisierung des Inventars: $e',
        operation: 'serializeInventory',
      );
      return ServiceResult.unexpectedError(dataException, operation: 'serializeInventory');
    }
  }

  // ===========================================================================
  // SAFE TYPE CONVERSION HELPERS
  // ===========================================================================

  /// Sichere Konvertierung von dynamischen Werten zu int mit Standardwerten
  static int safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      throw const ValidationException(
        'Ungültiger Integer-Wert',
        operation: 'safeInt',
      );
    }
    throw const ValidationException(
      'Typ kann nicht zu Integer konvertiert werden',
      operation: 'safeInt',
    );
  }

  /// Sichere Konvertierung von dynamischen Werten zu double mit Standardwerten
  static double safeDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
      throw const ValidationException(
        'Ungültiger Double-Wert',
        operation: 'safeDouble',
      );
    }
    throw const ValidationException(
      'Typ kann nicht zu Double konvertiert werden',
      operation: 'safeDouble',
    );
  }

  /// Sichere Konvertierung von dynamischen Werten zu String mit Standardwerten
  static String safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Sichere Konvertierung von dynamischen Werten zu String mit null-Standardwerten
  static String safeStringOrNull(dynamic value, String? defaultValue) {
    if (value == null) return defaultValue ?? '';
    return value.toString();
  }

  /// Sichere Konvertierung von dynamischen Werten zu bool mit Standardwerten
  static bool safeBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
      throw const ValidationException(
        'Ungültiger Boolean-Wert',
        operation: 'safeBool',
      );
    }
    throw const ValidationException(
      'Typ kann nicht zu Boolean konvertiert werden',
      operation: 'safeBool',
    );
  }

  /// Sichere Konvertierung von dynamischen Werten zu int mit null-Standardwerten
  static int safeIntOrNull(dynamic value, int? defaultValue) {
    if (value == null) return defaultValue ?? 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      throw const ValidationException(
        'Ungültiger Integer-Wert',
        operation: 'safeIntOrNull',
      );
    }
    throw const ValidationException(
      'Typ kann nicht zu Integer konvertiert werden',
      operation: 'safeIntOrNull',
    );
  }

  // ===========================================================================
  // VALIDATION HELPERS
  // ===========================================================================

  /// Validiert eine Attack-Liste
  static void validateAttackList(List<Attack> attacks) {
    for (int i = 0; i < attacks.length; i++) {
      final attack = attacks[i];
      if (attack.name.trim().isEmpty) {
        throw ValidationException(
          'Angriff $i: Name darf nicht leer sein',
          operation: 'validateAttackList',
        );
      }
      if (attack.damageDice.trim().isEmpty) {
        throw ValidationException(
          'Angriff $i: Schaden darf nicht leer sein',
          operation: 'validateAttackList',
        );
      }
      if (attack.attackBonus != null && (attack.attackBonus! < -10 || attack.attackBonus! > 20)) {
        throw ValidationException(
          'Angriff $i: Angriffsbonus muss zwischen -10 und 20 liegen',
          operation: 'validateAttackList',
        );
      }
    }
  }

  /// Validiert eine Inventar-Liste
  static void validateInventory(List<Map<String, dynamic>> inventory) {
    for (int i = 0; i < inventory.length; i++) {
      final item = inventory[i];
      if (item['name'] == null || item['name'].toString().trim().isEmpty) {
        throw ValidationException(
          'Inventar-Item $i: Name darf nicht leer sein',
          operation: 'validateInventory',
        );
      }
      if (item['quantity'] != null && (item['quantity'] as int) < 0) {
        throw ValidationException(
          'Inventar-Item $i: Menge darf nicht negativ sein',
          operation: 'validateInventory',
        );
      }
    }
  }

  /// Validiert JSON-Daten
  static void validateJsonString(String json, String context) {
    try {
      jsonDecode(json);
    } on FormatException catch (e) {
      throw ValidationException(
        'Ungültiges JSON in $context: ${e.message}',
        operation: 'validateJsonString',
      );
    }
  }

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  /// Prüft ob ein Wert ein gültiger Integer ist
  static bool isValidInt(dynamic value) {
    try {
      if (value == null) return false;
      if (value is int) return true;
      if (value is double) return value.isFinite;
      if (value is String) return int.tryParse(value) != null;
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Prüft ob ein Wert ein gültiger Double ist
  static bool isValidDouble(dynamic value) {
    try {
      if (value == null) return false;
      if (value is double) return value.isFinite;
      if (value is int) return true;
      if (value is String) return double.tryParse(value) != null;
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Prüft ob ein Wert ein gültiger Boolean ist
  static bool isValidBool(dynamic value) {
    try {
      if (value == null) return false;
      if (value is bool) return true;
      if (value is int) return value == 0 || value == 1;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == 'false' || lower == '1' || lower == '0';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Formatiert Attack-Liste für Anzeige
  static String formatAttackList(List<Attack> attacks) {
    if (attacks.isEmpty) return 'Keine Angriffe';
    
    final buffer = StringBuffer();
    for (int i = 0; i < attacks.length; i++) {
      final attack = attacks[i];
      buffer.writeln('${i + 1}. ${attack.name}');
      buffer.writeln('   Schaden: ${attack.damageDice}');
      if (attack.attackBonus != null) {
        buffer.writeln('   Bonus: +${attack.attackBonus}');
      }
      if (attack.abilityUsed != null) {
        buffer.writeln('   Attribut: ${attack.abilityUsed}');
      }
      buffer.writeln('');
    }
    return buffer.toString();
  }

  /// Formatiert Inventar für Anzeige
  static String formatInventory(List<Map<String, dynamic>> inventory) {
    if (inventory.isEmpty) return 'Keine Gegenstände im Inventar';
    
    final buffer = StringBuffer();
    double totalWeight = 0.0;
    
    for (int i = 0; i < inventory.length; i++) {
      final item = inventory[i];
      buffer.writeln('${i + 1}. ${item['name'] ?? 'Unbekannt'}');
      buffer.writeln('   Menge: ${item['quantity'] ?? 0}');
      if (item['weight'] != null) {
        final itemWeight = (item['weight'] as double) * (item['quantity'] as int? ?? 1);
        totalWeight += itemWeight;
        buffer.writeln('   Gewicht: ${itemWeight.toStringAsFixed(2)}');
      }
      if (item['cost'] != null) {
        buffer.writeln('   Wert: ${item['cost']}');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('Gesamtgewicht: ${totalWeight.toStringAsFixed(2)}');
    return buffer.toString();
  }

  /// Berechnet Gesamtgewicht des Inventars
  static double calculateTotalWeight(List<Map<String, dynamic>> inventory) {
    double totalWeight = 0.0;
    for (final item in inventory) {
      if (item['weight'] != null) {
        final weight = item['weight'] as double;
        final quantity = item['quantity'] as int? ?? 1;
        totalWeight += weight * quantity;
      }
    }
    return totalWeight;
  }

  /// Berechnet Gesamtwert des Inventars
  static double calculateTotalValue(List<Map<String, dynamic>> inventory) {
    double totalValue = 0.0;
    for (final item in inventory) {
      if (item['cost'] != null) {
        final cost = item['cost'] as double;
        final quantity = item['quantity'] as int? ?? 1;
        totalValue += cost * quantity;
      }
    }
    return totalValue;
  }

  /// Sucht Items im Inventar
  static List<Map<String, dynamic>> searchInventory(
    List<Map<String, dynamic>> inventory, 
    String query
  ) {
    if (query.trim().isEmpty) return inventory;
    
    final lowerQuery = query.toLowerCase();
    return inventory.where((item) {
      final name = item['name']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';
      return name.contains(lowerQuery) || description.contains(lowerQuery);
    }).toList();
  }

  /// Filtert Inventar nach Kriterium
  static List<Map<String, dynamic>> filterInventory(
    List<Map<String, dynamic>> inventory, 
    bool Function(Map<String, dynamic>) predicate
  ) {
    return inventory.where(predicate).toList();
  }

  /// Sortiert Inventar nach Name
  static List<Map<String, dynamic>> sortInventoryByName(
    List<Map<String, dynamic>> inventory, 
    {bool ascending = true}
  ) {
    final sorted = List<Map<String, dynamic>>.from(inventory);
    sorted.sort((a, b) {
      final nameA = a['name']?.toString() ?? '';
      final nameB = b['name']?.toString() ?? '';
      return nameA.compareTo(nameB);
    });
    return ascending ? sorted : sorted.reversed.toList();
  }

  /// Sortiert Inventar nach Gewicht
  static List<Map<String, dynamic>> sortInventoryByWeight(
    List<Map<String, dynamic>> inventory, 
    {bool ascending = true}
  ) {
    final sorted = List<Map<String, dynamic>>.from(inventory);
    sorted.sort((a, b) {
      final weightA = a['weight'] as double? ?? 0.0;
      final weightB = b['weight'] as double? ?? 0.0;
      return weightA.compareTo(weightB);
    });
    return ascending ? sorted : sorted.reversed.toList();
  }

  /// Sortiert Inventar nach Wert
  static List<Map<String, dynamic>> sortInventoryByValue(
    List<Map<String, dynamic>> inventory, 
    {bool ascending = true}
  ) {
    final sorted = List<Map<String, dynamic>>.from(inventory);
    sorted.sort((a, b) {
      final valueA = a['cost'] as double? ?? 0.0;
      final valueB = b['cost'] as double? ?? 0.0;
      return valueA.compareTo(valueB);
    });
    return ascending ? sorted : sorted.reversed.toList();
  }
}
