/// Basis-Interface für alle Entitäten im neuen Datenbanksystem
/// Definiert grundlegende Eigenschaften und Verhaltensweisen
abstract class BaseEntity {
  /// Eindeutige ID der Entität
  String get id;
  
  /// Setzt die ID der Entität (für CopyWith)
  set id(String value);
  
  /// Erstellt eine Kopie mit aktualisierten Werten
  BaseEntity copyWith();
  
  /// Konvertiert zu String für Debugging
  @override
  String toString();
  
  /// Gleichheitsprüfung basierend auf ID
  @override
  bool operator ==(Object other);
  
  /// Hash-Code für Vergleiche
  @override
  int get hashCode;
  
  /// Prüft ob die Entität gültig ist
  bool get isValid;
  
  /// Liste aller Validierungsfehler
  List<String> get validationErrors;
  
  /// Metadaten zur Entität
  Map<String, dynamic> get metadata;
}
