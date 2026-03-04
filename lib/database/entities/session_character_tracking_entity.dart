/// SessionCharacterTrackingEntity für Datenbank-Operationen
/// 
/// Diese Klasse repräsentiert die Datenbank-Tabelle für Session-Character-Tracking
library;

import '../../models/session_character_tracking.dart';

/// Entity für SessionCharacterTracking-Tabelle
class SessionCharacterTrackingEntity {
  final String id;
  final String sessionId;
  final String characterId;
  final String characterName;
  final int isPresent;
  final int currentHp;
  final int maxHp;
  final int tempHp;
  final String? conditions; // CSV
  final String notes;
  final String createdAt;

  SessionCharacterTrackingEntity({
    required this.id,
    required this.sessionId,
    required this.characterId,
    required this.characterName,
    required this.isPresent,
    required this.currentHp,
    required this.maxHp,
    required this.tempHp,
    this.conditions,
    required this.notes,
    required this.createdAt,
  });

  /// Konvertiert von SessionCharacterTracking-Model zu Entity
  factory SessionCharacterTrackingEntity.fromModel(SessionCharacterTracking tracking) {
    return SessionCharacterTrackingEntity(
      id: tracking.id,
      sessionId: tracking.sessionId,
      characterId: tracking.characterId,
      characterName: tracking.characterName,
      isPresent: tracking.isPresent ? 1 : 0,
      currentHp: tracking.currentHp,
      maxHp: tracking.maxHp,
      tempHp: tracking.tempHp,
      conditions: tracking.conditions.isEmpty ? null : tracking.conditions.join(','),
      notes: tracking.notes,
      createdAt: tracking.createdAt.toIso8601String(),
    );
  }

  /// Konvertiert von Map (Datenbank) zu Entity
  factory SessionCharacterTrackingEntity.fromMap(Map<String, dynamic> map) {
    return SessionCharacterTrackingEntity(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      characterId: map['character_id'] as String,
      characterName: map['character_name'] as String,
      isPresent: map['is_present'] as int,
      currentHp: map['current_hp'] as int,
      maxHp: map['max_hp'] as int,
      tempHp: map['temp_hp'] as int,
      conditions: map['conditions'] as String?,
      notes: map['notes'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  /// Konvertiert zu Map für Datenbank-Operationen
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'character_id': characterId,
      'character_name': characterName,
      'is_present': isPresent,
      'current_hp': currentHp,
      'max_hp': maxHp,
      'temp_hp': tempHp,
      'conditions': conditions,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  /// Konvertiert zu SessionCharacterTracking-Model
  SessionCharacterTracking toModel() {
    return SessionCharacterTracking(
      id: id,
      sessionId: sessionId,
      characterId: characterId,
      characterName: characterName,
      isPresent: isPresent == 1,
      currentHp: currentHp,
      maxHp: maxHp,
      tempHp: tempHp,
      conditions: conditions != null 
          ? conditions!.split(',').where((s) => s.isNotEmpty).toList() 
          : [],
      notes: notes,
      createdAt: DateTime.parse(createdAt),
    );
  }
}