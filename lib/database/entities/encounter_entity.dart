/// EncounterEntity für Datenbank-Operationen
/// 
/// Diese Klasse repräsentiert die Datenbank-Tabelle für Encounters
library;

import '../../models/encounter.dart';

/// Entity für Encounter-Tabelle
class EncounterEntity {
  final String id;
  final String sessionId;
  final String title;
  final String? description;
  final String status;
  final String? participantIds; // CSV
  final String createdAt;
  final String? startedAt;
  final String? completedAt;

  EncounterEntity({
    required this.id,
    required this.sessionId,
    required this.title,
    this.description,
    required this.status,
    this.participantIds,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  /// Konvertiert von Encounter-Model zu Entity
  factory EncounterEntity.fromModel(Encounter encounter) {
    return EncounterEntity(
      id: encounter.id,
      sessionId: encounter.sessionId,
      title: encounter.title,
      description: encounter.description.isEmpty ? null : encounter.description,
      status: encounter.status.toString().split('.').last,
      participantIds: encounter.participantIds.isEmpty ? null : encounter.participantIds.join(','),
      createdAt: encounter.createdAt.toIso8601String(),
      startedAt: encounter.startedAt?.toIso8601String(),
      completedAt: encounter.completedAt?.toIso8601String(),
    );
  }

  /// Konvertiert von Map (Datenbank) zu Entity
  factory EncounterEntity.fromMap(Map<String, dynamic> map) {
    return EncounterEntity(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String,
      participantIds: map['participant_ids'] as String?,
      createdAt: map['created_at'] as String,
      startedAt: map['started_at'] as String?,
      completedAt: map['completed_at'] as String?,
    );
  }

  /// Konvertiert zu Map für Datenbank-Operationen
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'title': title,
      'description': description,
      'status': status,
      'participant_ids': participantIds,
      'created_at': createdAt,
      'started_at': startedAt,
      'completed_at': completedAt,
    };
  }

  /// Konvertiert zu Encounter-Model
  Encounter toModel() {
    return Encounter(
      id: id,
      sessionId: sessionId,
      title: title,
      description: description ?? '',
      status: EncounterStatus.values.firstWhere(
        (e) => e.toString() == 'EncounterStatus.$status',
        orElse: () => EncounterStatus.planning,
      ),
      participantIds: participantIds != null 
          ? participantIds!.split(',').where((s) => s.isNotEmpty).toList() 
          : [],
      createdAt: DateTime.parse(createdAt),
      startedAt: startedAt != null ? DateTime.parse(startedAt!) : null,
      completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
    );
  }
}