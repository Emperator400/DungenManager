/// SessionQuestProgress-Model für D&D Kampagnen
/// 
/// Repräsentiert den Fortschritt eines Quests innerhalb einer Session
/// mit manueller Komplettierung und Belohnungsverteilung.
library;

import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

/// Quest-Status in Session
enum SessionQuestStatus {
  active,
  completed,
  failed,
  abandoned,
}

/// Repräsentiert den Fortschritt eines Quests in einer Session
class SessionQuestProgress {
  final String id;
  final String sessionId;
  final int questId;
  final SessionQuestStatus status;
  final int progress; // Aktueller Fortschritt
  final int maxProgress; // Maximaler Fortschritt
  final String notes;
  final DateTime createdAt;
  final DateTime? completedAt;

  SessionQuestProgress({
    String? id,
    required this.sessionId,
    required this.questId,
    this.status = SessionQuestStatus.active,
    this.progress = 0,
    this.maxProgress = 100,
    this.notes = '',
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? UuidService().generateId(),
        createdAt = createdAt ?? DateTime.now();

  /// Factory für neuen Quest-Progress
  factory SessionQuestProgress.create({
    required String sessionId,
    required int questId,
  }) {
    return SessionQuestProgress(
      sessionId: sessionId,
      questId: questId,
      status: SessionQuestStatus.active,
      progress: 0,
      maxProgress: 100,
    );
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory SessionQuestProgress.fromMap(Map<String, dynamic> map) {
    return SessionQuestProgress.fromDatabaseMap(map);
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory SessionQuestProgress.fromDatabaseMap(Map<String, dynamic> map) {
    return SessionQuestProgress(
      id: ModelParsingHelper.safeId(map, 'id'),
      sessionId: ModelParsingHelper.safeString(map, 'session_id', ''),
      questId: ModelParsingHelper.safeInt(map, 'quest_id', 0),
      status: SessionQuestStatus.values.firstWhere(
        (e) => e.toString() == 'SessionQuestStatus.${ModelParsingHelper.safeString(map, 'status', 'active')}',
        orElse: () => SessionQuestStatus.active,
      ),
      progress: ModelParsingHelper.safeInt(map, 'progress', 0),
      maxProgress: ModelParsingHelper.safeInt(map, 'max_progress', 100),
      notes: ModelParsingHelper.safeString(map, 'notes', ''),
      createdAt: ModelParsingHelper.safeDateTime(map, 'created_at', DateTime.now()),
      completedAt: ModelParsingHelper.safeDateTimeOrNull(map, 'completed_at', null),
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
      'session_id': sessionId,
      'quest_id': questId,
      'status': status.toString().split('.').last,
      'progress': progress,
      'max_progress': maxProgress,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// CopyWith-Methode für unveränderliche Updates
  SessionQuestProgress copyWith({
    String? id,
    String? sessionId,
    int? questId,
    SessionQuestStatus? status,
    int? progress,
    int? maxProgress,
    String? notes,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SessionQuestProgress(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      questId: questId ?? this.questId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Aktualisiert den Fortschritt
  SessionQuestProgress updateProgress(int newProgress) {
    return copyWith(
      progress: newProgress.clamp(0, maxProgress),
    );
  }

  /// Setzt den Status auf "abgeschlossen"
  SessionQuestProgress complete() {
    return copyWith(
      status: SessionQuestStatus.completed,
      progress: maxProgress,
      completedAt: DateTime.now(),
    );
  }

  /// Setzt den Status auf "fehlgeschlagen"
  SessionQuestProgress fail() {
    return copyWith(
      status: SessionQuestStatus.failed,
      completedAt: DateTime.now(),
    );
  }

  /// Setzt den Status auf "aufgegeben"
  SessionQuestProgress abandon() {
    return copyWith(
      status: SessionQuestStatus.abandoned,
    );
  }

  /// Setzt den Status auf "aktiv"
  SessionQuestProgress reactivate() {
    return copyWith(
      status: SessionQuestStatus.active,
      completedAt: null,
    );
  }

  // ========== COMPATIBILITY GETTERS ==========

  /// Prüft ob Quest aktiv ist
  bool get isActive => status == SessionQuestStatus.active;

  /// Prüft ob Quest abgeschlossen ist
  bool get isCompleted => status == SessionQuestStatus.completed;

  /// Prüft ob Quest fehlgeschlagen ist
  bool get isFailed => status == SessionQuestStatus.failed;

  /// Prüft ob Quest aufgegeben wurde
  bool get isAbandoned => status == SessionQuestStatus.abandoned;

  /// Fortschritt in Prozent
  double get progressPercent {
    if (maxProgress == 0) return 0.0;
    return progress / maxProgress * 100;
  }

  /// Prüft ob Quest komplett abgeschlossen ist
  bool get isFullyComplete => isCompleted && progress >= maxProgress;

  /// Lokalisierte Beschreibung für Status
  String get statusDescription {
    switch (status) {
      case SessionQuestStatus.active:
        return 'Aktiv';
      case SessionQuestStatus.completed:
        return 'Abgeschlossen';
      case SessionQuestStatus.failed:
        return 'Fehlgeschlagen';
      case SessionQuestStatus.abandoned:
        return 'Aufgegeben';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionQuestProgress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SessionQuestProgress(id: $id, questId: $questId, status: $status, progress: $progress/$maxProgress)';
  }
}