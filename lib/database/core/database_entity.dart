import '../entities/base_entity.dart';

/// Abstrakte Basisklasse für alle Datenbank-Entitäten
/// Stellt sicher, dass alle Entitäten konsistente Methoden haben
abstract class DatabaseEntity<T extends BaseEntity> {
  /// Tabellenname in der Datenbank
  String get tableName;
  
  /// Konvertiert die Entität zu einer Datenbank-Map
  /// Berücksichtigt snake_case Konvention
  Map<String, dynamic> toDatabaseMap();
  
  /// Erstellt eine Entität aus einer Datenbank-Map
  /// Behandelt snake_case zu camelCase Konvertierung
  T fromDatabaseMap(Map<String, dynamic> map);
  
  /// SQL für Tabellenerstellung
  List<String> get createTableSql;
  
  /// Alle Indizes für diese Tabelle
  List<String> get createIndexes => [];
  
  /// Feldnamen für die Datenbank (snake_case)
  List<String> get databaseFields;
  
  /// Primärschlüsselfeld
  String get primaryKeyField => 'id';
  
  /// Prüft ob die Entität gültig ist
  bool get isValid;
  
  /// Validierungsfehler
  List<String> get validationErrors;
  
  /// Konvertiert camelCase zu snake_case für Datenbankfelder
  String toSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .toLowerCase();
  }
  
  /// Konvertiert snake_case zu camelCase für Modelfelder
  String toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.length == 1) return parts.first;
    
    return parts.first + parts
        .skip(1)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join('');
  }
  
  /// Erstellt eine Map mit snake_case Schlüsseln aus camelCase properties
  Map<String, dynamic> convertToSnakeCase(Map<String, dynamic> camelCaseMap) {
    final snakeCaseMap = <String, dynamic>{};
    
    for (final entry in camelCaseMap.entries) {
      final snakeKey = toSnakeCase(entry.key);
      snakeCaseMap[snakeKey] = entry.value;
    }
    
    return snakeCaseMap;
  }
  
  /// Erstellt eine Map mit camelCase Schlüsseln aus snakeCase Datenbankdaten
  Map<String, dynamic> convertToCamelCase(Map<String, dynamic> snakeCaseMap) {
    final camelCaseMap = <String, dynamic>{};
    
    for (final entry in snakeCaseMap.entries) {
      final camelKey = toCamelCase(entry.key);
      camelCaseMap[camelKey] = entry.value;
    }
    
    return camelCaseMap;
  }
}
