/// EncounterParticipant-Model für D&D Kampagnen
/// 
/// Repräsentiert einen Teilnehmer an einem Encounter (Spieler, Monster oder NPC)
/// mit HP und Conditions für einfaches Combat-Tracking.
library;

import '../services/uuid_service.dart';
import '../utils/string_list_parser.dart';
import '../utils/model_parsing_helper.dart';

/// Typ des Teilnehmers
enum ParticipantType {
  player,
  enemy,
  npc,
}

/// Repräsentiert einen Teilnehmer an einem Encounter
class EncounterParticipant {
  final String id;
  final String encounterId;
  final String name;
  final ParticipantType type;
  final int currentHp;
  final int maxHp;
  final List<String> conditions;
  final String? notes;
  final String? characterId; // Für Player-Typen

  EncounterParticipant({
    String? id,
    required this.encounterId,
    required this.name,
    required this.type,
    required this.currentHp,
    required this.maxHp,
    this.conditions = const [],
    this.notes,
    this.characterId,
  }) : id = id ?? UuidService().generateId();

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory EncounterParticipant.fromMap(Map<String, dynamic> map) {
    return EncounterParticipant.fromDatabaseMap(map);
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory EncounterParticipant.fromDatabaseMap(Map<String, dynamic> map) {
    return EncounterParticipant(
      id: ModelParsingHelper.safeId(map, 'id'),
      encounterId: ModelParsingHelper.safeString(map, 'encounter_id', ''),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbekannt'),
      type: ParticipantType.values.firstWhere(
        (e) => e.toString() == 'ParticipantType.${ModelParsingHelper.safeString(map, 'type', 'enemy')}',
        orElse: () => ParticipantType.enemy,
      ),
      currentHp: ModelParsingHelper.safeInt(map, 'current_hp', 0),
      maxHp: ModelParsingHelper.safeInt(map, 'max_hp', 0),
      conditions: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'conditions', null)),
      notes: ModelParsingHelper.safeStringOrNull(map, 'notes', null),
      characterId: ModelParsingHelper.safeStringOrNull(map, 'character_id', null),
    );
  }

  /// Konvertiert zu einer Map für die Datenbank
  Map<String, dynamic> toMap() {
    return toDatabaseMap();
  }

  /// Konvertiert zu einer Map für die Datenbank
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'encounter_id': encounterId,
      'name': name,
      'type': type.toString().split('.').last,
      'current_hp': currentHp,
      'max_hp': maxHp,
      'conditions': conditions.isNotEmpty ? conditions.join(',') : null,
      'notes': notes,
      'character_id': characterId,
    };
  }

  /// CopyWith-Methode für unveränderliche Updates
  EncounterParticipant copyWith({
    String? id,
    String? encounterId,
    String? name,
    ParticipantType? type,
    int? currentHp,
    int? maxHp,
    List<String>? conditions,
    String? notes,
    String? characterId,
  }) {
    return EncounterParticipant(
      id: id ?? this.id,
      encounterId: encounterId ?? this.encounterId,
      name: name ?? this.name,
      type: type ?? this.type,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      conditions: conditions ?? this.conditions,
      notes: notes ?? this.notes,
      characterId: characterId ?? this.characterId,
    );
  }

  /// Fügt Schaden hinzu
  EncounterParticipant takeDamage(int damage) {
    return copyWith(
      currentHp: (currentHp - damage).clamp(0, maxHp),
    );
  }

  /// Heilt den Teilnehmer
  EncounterParticipant heal(int amount) {
    return copyWith(
      currentHp: (currentHp + amount).clamp(0, maxHp),
    );
  }

  /// Setzt HP auf einen neuen Wert
  EncounterParticipant setHp(int newHp) {
    return copyWith(
      currentHp: newHp.clamp(0, maxHp),
    );
  }

  /// Fügt eine Condition hinzu
  EncounterParticipant addCondition(String condition) {
    final newConditions = List<String>.from(conditions);
    if (!newConditions.contains(condition)) {
      newConditions.add(condition);
    }
    return copyWith(conditions: newConditions);
  }

  /// Entfernt eine Condition
  EncounterParticipant removeCondition(String condition) {
    final newConditions = List<String>.from(conditions)..remove(condition);
    return copyWith(conditions: newConditions);
  }

  /// Prüft ob Teilnehmer tot ist
  bool get isDead => currentHp <= 0;

  /// Prüft ob Participant am Leben ist
  bool get isAlive => currentHp > 0;

  /// HP in Prozent
  double get hpPercent => maxHp > 0 ? currentHp / maxHp : 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EncounterParticipant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EncounterParticipant(id: $id, name: $name, type: $type, hp: $currentHp/$maxHp)';
  }
}