/// Encounter-Model für D&D Kampagnen
/// 
/// Repräsentiert eine Kampfbegegnung mit Teilnehmern, HP und Conditions
/// für einfaches Combat-Tracking ohne Initiative/Turn-Order.
library;

import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

/// Encounter-Status
enum EncounterStatus {
  planning,
  active,
  completed,
  cancelled,
}

/// Repräsentiert eine Kampfbegegnung
class Encounter {
  final String id;
  final String sceneId;  // ← GEÄNDERT: Encounter gehört zu Scene, nicht Session
  final String title;
  final String description;
  final EncounterStatus status;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  Encounter({
    String? id,
    required this.sceneId,  // ← GEÄNDERT
    required this.title,
    this.description = '',
    this.status = EncounterStatus.planning,
    this.participantIds = const [],
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
  })  : id = id ?? UuidService().generateId(),
        createdAt = createdAt ?? DateTime.now();

  /// Factory für neue Encounters
  factory Encounter.create({
    required String sceneId,  // ← GEÄNDERT
    required String title,
    String description = '',
  }) {
    return Encounter(
      sceneId: sceneId,  // ← GEÄNDERT
      title: title,
      description: description,
      status: EncounterStatus.planning,
    );
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory Encounter.fromMap(Map<String, dynamic> map) {
    return Encounter.fromDatabaseMap(map);
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory Encounter.fromDatabaseMap(Map<String, dynamic> map) {
    return Encounter(
      id: ModelParsingHelper.safeId(map, 'id'),
      sceneId: ModelParsingHelper.safeString(map, 'scene_id', ''),  // ← GEÄNDERT
      title: ModelParsingHelper.safeString(map, 'title', 'Unbenannter Encounter'),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      status: EncounterStatus.values.firstWhere(
        (e) => e.toString() == 'EncounterStatus.${ModelParsingHelper.safeString(map, 'status', 'planning')}',
        orElse: () => EncounterStatus.planning,
      ),
      participantIds: _deserializeStringList(map['participant_ids'] as String?),
      createdAt: ModelParsingHelper.safeDateTime(map, 'created_at', DateTime.now()),
      startedAt: ModelParsingHelper.safeDateTimeOrNull(map, 'started_at', null),
      completedAt: ModelParsingHelper.safeDateTimeOrNull(map, 'completed_at', null),
    );
  }

  /// Hilfsmethode zum Deserialisieren einer String-Liste
  static List<String> _deserializeStringList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').where((s) => s.isNotEmpty).toList();
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
      'scene_id': sceneId,  // ← GEÄNDERT
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'participant_ids': _serializeStringList(participantIds),
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// CopyWith-Methode für unveränderliche Updates
  Encounter copyWith({
    String? id,
    String? sceneId,  // ← GEÄNDERT
    String? title,
    String? description,
    EncounterStatus? status,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Encounter(
      id: id ?? this.id,
      sceneId: sceneId ?? this.sceneId,  // ← GEÄNDERT
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Startet den Encounter
  Encounter startEncounter() {
    return copyWith(
      status: EncounterStatus.active,
      startedAt: DateTime.now(),
    );
  }

  /// Beendet den Encounter
  Encounter completeEncounter() {
    return copyWith(
      status: EncounterStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Cancelled den Encounter
  Encounter cancelEncounter() {
    return copyWith(
      status: EncounterStatus.cancelled,
    );
  }

  // ========== COMPATIBILITY GETTERS ==========

  /// Prüft ob Encounter aktiv ist
  bool get isActive => status == EncounterStatus.active;

  /// Prüft ob Encounter abgeschlossen ist
  bool get isCompleted => status == EncounterStatus.completed;

  /// Prüft ob Encounter geplant ist
  bool get isPlanning => status == EncounterStatus.planning;

  /// Prüft ob Encounter abgebrochen ist
  bool get isCancelled => status == EncounterStatus.cancelled;

  /// Anzahl der Teilnehmer
  int get participantCount => participantIds.length;

  /// Lokalisierte Beschreibung für Status
  String get statusDescription {
    switch (status) {
      case EncounterStatus.planning:
        return 'Planung';
      case EncounterStatus.active:
        return 'Aktiv';
      case EncounterStatus.completed:
        return 'Abgeschlossen';
      case EncounterStatus.cancelled:
        return 'Abgebrochen';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Encounter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Encounter(id: $id, title: $title, status: $status, participants: $participantCount)';
  }
}