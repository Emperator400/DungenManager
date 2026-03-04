/// SessionCharacterTracking-Model für D&D Kampagnen
/// 
/// Repräsentiert den Tracking-Status eines Charakters während einer Session
/// mit HP, Conditions, Anwesenheit und Notizen.
library;

import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';
import '../utils/string_list_parser.dart';

/// Repräsentiert den Tracking-Status eines Charakters in einer Session
class SessionCharacterTracking {
  final String id;
  final String sessionId;
  final String characterId;
  final String characterName;
  final bool isPresent; // Ist der Charakter anwesend?
  final int currentHp;
  final int maxHp;
  final int tempHp; // Temporäre HP
  final List<String> conditions; // Aktive Conditions
  final String notes; // Notizen zum Charakter
  final DateTime createdAt;

  SessionCharacterTracking({
    String? id,
    required this.sessionId,
    required this.characterId,
    required this.characterName,
    this.isPresent = true,
    required this.currentHp,
    required this.maxHp,
    this.tempHp = 0,
    this.conditions = const [],
    this.notes = '',
    DateTime? createdAt,
  })  : id = id ?? UuidService().generateId(),
        createdAt = createdAt ?? DateTime.now();

  /// Factory für neues Character Tracking
  factory SessionCharacterTracking.create({
    required String sessionId,
    required String characterId,
    required String characterName,
    int maxHp = 0,
  }) {
    return SessionCharacterTracking(
      sessionId: sessionId,
      characterId: characterId,
      characterName: characterName,
      isPresent: true,
      currentHp: maxHp,
      maxHp: maxHp,
      tempHp: 0,
      conditions: [],
      notes: '',
    );
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory SessionCharacterTracking.fromMap(Map<String, dynamic> map) {
    return SessionCharacterTracking.fromDatabaseMap(map);
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory SessionCharacterTracking.fromDatabaseMap(Map<String, dynamic> map) {
    return SessionCharacterTracking(
      id: ModelParsingHelper.safeId(map, 'id'),
      sessionId: ModelParsingHelper.safeString(map, 'session_id', ''),
      characterId: ModelParsingHelper.safeString(map, 'character_id', ''),
      characterName: ModelParsingHelper.safeString(map, 'character_name', 'Unbekannt'),
      isPresent: ModelParsingHelper.safeBool(map, 'is_present', true),
      currentHp: ModelParsingHelper.safeInt(map, 'current_hp', 0),
      maxHp: ModelParsingHelper.safeInt(map, 'max_hp', 0),
      tempHp: ModelParsingHelper.safeInt(map, 'temp_hp', 0),
      conditions: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'conditions', null)),
      notes: ModelParsingHelper.safeString(map, 'notes', ''),
      createdAt: ModelParsingHelper.safeDateTime(map, 'created_at', DateTime.now()),
    );
  }

  /// Hilfsmethode zum Serialisieren einer String-Liste
  static String? _serializeStringList(List<String> list) {
    if (list.isEmpty) return null;
    return list.join(',');
  }

  /// Konvertiert zu einer Map für die Datenbank
  Map<String, dynamic> toMap() {
    return toDatabaseMap();
  }

  /// Konvertiert zu einer Map für die Datenbank
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'character_id': characterId,
      'character_name': characterName,
      'is_present': isPresent ? 1 : 0,
      'current_hp': currentHp,
      'max_hp': maxHp,
      'temp_hp': tempHp,
      'conditions': _serializeStringList(conditions),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// CopyWith-Methode für unveränderliche Updates
  SessionCharacterTracking copyWith({
    String? id,
    String? sessionId,
    String? characterId,
    String? characterName,
    bool? isPresent,
    int? currentHp,
    int? maxHp,
    int? tempHp,
    List<String>? conditions,
    String? notes,
    DateTime? createdAt,
  }) {
    return SessionCharacterTracking(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      isPresent: isPresent ?? this.isPresent,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      tempHp: tempHp ?? this.tempHp,
      conditions: conditions ?? this.conditions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Setzt Anwesenheit
  SessionCharacterTracking setPresence(bool present) {
    return copyWith(isPresent: present);
  }

  /// Fügt Schaden zu
  SessionCharacterTracking takeDamage(int damage) {
    // Temp HP zuerst, dann normale HP
    int newTempHp = tempHp;
    int newCurrentHp = currentHp;
    
    if (newTempHp > 0) {
      final damageToTemp = damage.clamp(0, newTempHp);
      newTempHp -= damageToTemp;
      damage -= damageToTemp;
    }
    
    newCurrentHp = (currentHp - damage).clamp(0, maxHp);
    
    return copyWith(
      tempHp: newTempHp,
      currentHp: newCurrentHp,
    );
  }

  /// Heilt den Charakter
  SessionCharacterTracking heal(int amount) {
    return copyWith(
      currentHp: (currentHp + amount).clamp(0, maxHp),
    );
  }

  /// Setzt HP auf einen neuen Wert
  SessionCharacterTracking setHp(int newHp) {
    return copyWith(
      currentHp: newHp.clamp(0, maxHp),
    );
  }

  /// Setzt Max HP auf einen neuen Wert
  SessionCharacterTracking setMaxHp(int newMaxHp) {
    return copyWith(
      maxHp: newMaxHp,
      currentHp: currentHp.clamp(0, newMaxHp),
    );
  }

  /// Fügt temporäre HP hinzu
  SessionCharacterTracking addTempHp(int amount) {
    return copyWith(
      tempHp: tempHp + amount,
    );
  }

  /// Entfernt alle temporären HP
  SessionCharacterTracking clearTempHp() {
    return copyWith(tempHp: 0);
  }

  /// Fügt eine Condition hinzu
  SessionCharacterTracking addCondition(String condition) {
    final newConditions = List<String>.from(conditions);
    if (!newConditions.contains(condition)) {
      newConditions.add(condition);
    }
    return copyWith(conditions: newConditions);
  }

  /// Entfernt eine Condition
  SessionCharacterTracking removeCondition(String condition) {
    final newConditions = List<String>.from(conditions)..remove(condition);
    return copyWith(conditions: newConditions);
  }

  /// Entfernt alle Conditions
  SessionCharacterTracking clearConditions() {
    return copyWith(conditions: []);
  }

  /// Aktualisiert Notizen
  SessionCharacterTracking updateNotes(String newNotes) {
    return copyWith(notes: newNotes);
  }

  // ========== COMPATIBILITY GETTERS ==========

  /// Prüft ob Charakter anwesend ist
  bool get isAbsent => !isPresent;

  /// Prüft ob Charakter tot ist (0 HP oder weniger)
  bool get isDead => currentHp <= 0;

  /// Prüft ob Charakter am Leben ist
  bool get isAlive => currentHp > 0;

  /// Prüft ob Charakter bewusstlos ist (0 HP aber nicht tot)
  bool get isUnconscious => currentHp == 0 && !isDead;

  /// HP in Prozent
  double get hpPercent {
    if (maxHp == 0) return 0.0;
    return currentHp / maxHp;
  }

  /// Prüft ob Charakter eine Condition hat
  bool hasCondition(String condition) => conditions.contains(condition);

  /// Anzahl der aktiven Conditions
  int get conditionCount => conditions.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionCharacterTracking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SessionCharacterTracking(id: $id, name: $characterName, hp: $currentHp/$maxHp, temp: $tempHp, conditions: $conditions)';
  }
}