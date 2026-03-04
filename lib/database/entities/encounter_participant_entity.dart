/// EncounterParticipantEntity für Datenbank-Operationen
/// 
/// Diese Klasse repräsentiert die Datenbank-Tabelle für Encounter-Teilnehmer
library;

import '../../models/encounter_participant.dart';

/// Entity für EncounterParticipant-Tabelle
class EncounterParticipantEntity {
  final String id;
  final String encounterId;
  final String name;
  final String type;
  final int currentHp;
  final int maxHp;
  final String? conditions; // CSV
  final String? notes;
  final String? characterId;

  EncounterParticipantEntity({
    required this.id,
    required this.encounterId,
    required this.name,
    required this.type,
    required this.currentHp,
    required this.maxHp,
    this.conditions,
    this.notes,
    this.characterId,
  });

  /// Konvertiert von EncounterParticipant-Model zu Entity
  factory EncounterParticipantEntity.fromModel(EncounterParticipant participant) {
    return EncounterParticipantEntity(
      id: participant.id,
      encounterId: participant.encounterId,
      name: participant.name,
      type: participant.type.toString().split('.').last,
      currentHp: participant.currentHp,
      maxHp: participant.maxHp,
      conditions: participant.conditions.isEmpty ? null : participant.conditions.join(','),
      notes: participant.notes,
      characterId: participant.characterId,
    );
  }

  /// Konvertiert von Map (Datenbank) zu Entity
  factory EncounterParticipantEntity.fromMap(Map<String, dynamic> map) {
    return EncounterParticipantEntity(
      id: map['id'] as String,
      encounterId: map['encounter_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      currentHp: map['current_hp'] as int,
      maxHp: map['max_hp'] as int,
      conditions: map['conditions'] as String?,
      notes: map['notes'] as String?,
      characterId: map['character_id'] as String?,
    );
  }

  /// Konvertiert zu Map für Datenbank-Operationen
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'encounter_id': encounterId,
      'name': name,
      'type': type,
      'current_hp': currentHp,
      'max_hp': maxHp,
      'conditions': conditions,
      'notes': notes,
      'character_id': characterId,
    };
  }

  /// Konvertiert zu EncounterParticipant-Model
  EncounterParticipant toModel() {
    return EncounterParticipant(
      id: id,
      encounterId: encounterId,
      name: name,
      type: ParticipantType.values.firstWhere(
        (e) => e.toString() == 'ParticipantType.$type',
        orElse: () => ParticipantType.enemy,
      ),
      currentHp: currentHp,
      maxHp: maxHp,
      conditions: conditions != null 
          ? conditions!.split(',').where((s) => s.isNotEmpty).toList() 
          : [],
      notes: notes,
      characterId: characterId,
    );
  }
}