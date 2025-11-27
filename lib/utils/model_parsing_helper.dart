/// Zentrale Utility für sicheres Parsen von Model-Daten
/// 
/// Bietet konsistente Fehlerbehandlung für alle .fromMap Methoden
/// und verhindert Runtime Exceptions bei Datenbank-Operationen.
library model_parsing_helper;

import '../services/uuid_service.dart';

class ModelParsingHelper {
  /// Safely gets a value from a map with type checking and default fallback
  static T safeGet<T>(Map<String, dynamic> map, String key, T defaultValue) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      return value as T;
    } catch (e) {
      print('Warning: Failed to parse $key as $T from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses an integer value
  static int safeInt(Map<String, dynamic> map, String key, int defaultValue) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      print('Warning: Failed to parse $key as int from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a double value
  static double safeDouble(Map<String, dynamic> map, String key, double defaultValue) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      print('Warning: Failed to parse $key as double from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a boolean value
  static bool safeBool(Map<String, dynamic> map, String key, bool defaultValue) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return defaultValue;
    } catch (e) {
      print('Warning: Failed to parse $key as bool from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a string value
  static String safeString(Map<String, dynamic> map, String key, String defaultValue) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      return value.toString();
    } catch (e) {
      print('Warning: Failed to parse $key as string from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a nullable string value
  static String? safeStringOrNull(Map<String, dynamic> map, String key, String? defaultValue) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value == '') return null;
      return value.toString();
    } catch (e) {
      print('Warning: Failed to parse $key as nullable string from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a nullable integer value
  static int? safeIntOrNull(Map<String, dynamic> map, String key, int? defaultValue) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed == 0 ? null : parsed; // 0 could indicate "not set"
      }
      return defaultValue;
    } catch (e) {
      print('Warning: Failed to parse $key as nullable int from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses an enum value
  static T safeEnum<T>(
    Map<String, dynamic> map, 
    String key, 
    List<T> values, 
    T defaultValue,
  ) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      
      final stringValue = value.toString();
      
      // Try exact match first
      for (final enumValue in values) {
        if (enumValue.toString() == stringValue) {
          return enumValue;
        }
      }
      
      // Try by name (for enum.name format)
      for (final enumValue in values) {
        if (enumValue.toString().split('.').last == stringValue) {
          return enumValue;
        }
      }
      
      print('Warning: Unknown enum value $stringValue for $key, using default');
      return defaultValue;
    } catch (e) {
      print('Warning: Failed to parse $key as enum from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a DateTime value
  static DateTime safeDateTime(
    Map<String, dynamic> map, 
    String key, 
    DateTime defaultValue,
  ) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      
      if (value is DateTime) return value;
      
      if (value is int) {
        // Assume milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return parsed ?? defaultValue;
      }
      
      return defaultValue;
    } catch (e) {
      print('Warning: Failed to parse $key as DateTime from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a nullable DateTime value
  static DateTime? safeDateTimeOrNull(
    Map<String, dynamic> map, 
    String key, 
    DateTime? defaultValue,
  ) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      
      if (value is DateTime) return value;
      
      if (value is int) {
        // Assume milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      
      if (value is String) {
        return DateTime.tryParse(value);
      }
      
      return defaultValue;
    } catch (e) {
      print('Warning: Failed to parse $key as nullable DateTime from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a Duration value (stored as milliseconds)
  static Duration safeDuration(
    Map<String, dynamic> map, 
    String key, 
    Duration defaultValue,
  ) {
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      
      if (value is Duration) return value;
      
      if (value is int) {
        return Duration(milliseconds: value);
      }
      
      if (value is String) {
        final milliseconds = int.tryParse(value);
        if (milliseconds != null) {
          return Duration(milliseconds: milliseconds);
        }
      }
      
      return defaultValue;
    } catch (e) {
      print('Warning: Failed to parse $key as Duration from map: $e');
      return defaultValue;
    }
  }

  /// Safely parses a list of strings (comma-separated or actual list)
  static List<String> safeStringList(
    Map<String, dynamic> map, 
    String key,
  ) {
    try {
      final value = map[key];
      if (value == null) return [];
      
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      
      if (value is String) {
        if (value.isEmpty) return [];
        return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      
      return [];
    } catch (e) {
      print('Warning: Failed to parse $key as string list from map: $e');
      return [];
    }
  }

  /// Safely generates an ID if not present
  static String safeId(Map<String, dynamic> map, String key) {
    final id = safeString(map, key, '');
    if (id.isEmpty) {
      return UuidService().generateId();
    }
    return id;
  }

  /// Validates that a map has all required keys
  static bool hasRequiredKeys(Map<String, dynamic> map, List<String> requiredKeys) {
    for (final key in requiredKeys) {
      if (!map.containsKey(key) || map[key] == null) {
        print('Error: Missing required key: $key');
        return false;
      }
    }
    return true;
  }

  /// Logs parsing errors with context
  static void logParsingError(String modelName, String field, dynamic value, Exception error) {
    print('Error parsing $modelName.$field with value $value: $error');
  }
}
