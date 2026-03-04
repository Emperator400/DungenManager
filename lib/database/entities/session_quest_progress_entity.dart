/// SessionQuestProgressEntity für Datenbank-Operationen
/// 
/// Diese Klasse repräsentiert die Datenbank-Tabelle für Session-Quest-Fortschritt
library;

import '../../models/session_quest_progress.dart';

/// Entity für SessionQuestProgress-Tabelle
class SessionQuestProgressEntity {
  final String id;
  final String sessionId;
  final int questId;
  final String status;
  final int progress;
  final int maxProgress;
  final String notes;
  final String createdAt;
  final String? completedAt;

  SessionQuestProgressEntity({
    required this.id,
    required this.sessionId,
    required this.questId,
    required this.status,
    required this.progress,
    required this.maxProgress,
    required this.notes,
    required this.createdAt,
    this.completedAt,
  });

  /// Konvertiert von SessionQuestProgress-Model zu Entity
  factory SessionQuestProgressEntity.fromModel(SessionQuestProgress questProgress) {
    return SessionQuestProgressEntity(
      id: questProgress.id,
      sessionId: questProgress.sessionId,
      questId: questProgress.questId,
      status: questProgress.status.toString().split('.').last,
      progress: questProgress.progress,
      maxProgress: questProgress.maxProgress,
      notes: questProgress.notes,
      createdAt: questProgress.createdAt.toIso8601String(),
      completedAt: questProgress.completedAt?.toIso8601String(),
    );
  }

  /// Konvertiert von Map (Datenbank) zu Entity
  factory SessionQuestProgressEntity.fromMap(Map<String, dynamic> map) {
    return SessionQuestProgressEntity(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      questId: map['quest_id'] as int,
      status: map['status'] as String,
      progress: map['progress'] as int,
      maxProgress: map['max_progress'] as int,
      notes: map['notes'] as String,
      createdAt: map['created_at'] as String,
      completedAt: map['completed_at'] as String?,
    );
  }

  /// Konvertiert zu Map für Datenbank-Operationen
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'quest_id': questId,
      'status': status,
      'progress': progress,
      'max_progress': maxProgress,
      'notes': notes,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }

  /// Konvertiert zu SessionQuestProgress-Model
  SessionQuestProgress toModel() {
    return SessionQuestProgress(
      id: id,
      sessionId: sessionId,
      questId: questId,
      status: SessionQuestStatus.values.firstWhere(
        (e) => e.toString() == 'SessionQuestStatus.$status',
        orElse: () => SessionQuestStatus.active,
      ),
      progress: progress,
      maxProgress: maxProgress,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
    );
  }
}