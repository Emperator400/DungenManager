/// SceneQuestStatus-Model für D&D Kampagnen
/// 
/// Repräsentiert den Status einer Quest innerhalb einer spezifischen Scene.
/// Dies ermöglicht es, Quests über mehrere Scenes hinweg zu tracken,
/// mit unterschiedlichen Status-Werten pro Scene.
library;

import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

/// Quest-Status für Scene-spezifisches Tracking
enum QuestStatus {
  /// Quest ist in dieser Scene relevant und aktiv
  active,
  
  /// Quest ist in dieser Scene nicht relevant (aber existiert noch)
  paused,
  
  /// Quest wurde in dieser Scene abgeschlossen
  completed,
  
  /// Quest ist in dieser Scene fehlgeschlagen
  failed,
}

/// Scene-spezifischer Quest-Status
class SceneQuestStatus {
  final String id;
  final String sceneId;
  final String questId;
  final QuestStatus status;
  final int progress; // 0-100%
  final String? notes;
  final DateTime lastUpdated;

  SceneQuestStatus({
    String? id,
    required this.sceneId,
    required this.questId,
    required this.status,
    this.progress = 0,
    this.notes,
    DateTime? lastUpdated,
  })  : id = id ?? UuidService().generateId(),
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Factory für neue SceneQuestStatus
  factory SceneQuestStatus.create({
    required String sceneId,
    required String questId,
    QuestStatus status = QuestStatus.active,
  }) {
    return SceneQuestStatus(
      sceneId: sceneId,
      questId: questId,
      status: status,
      progress: status == QuestStatus.completed ? 100 : 0,
    );
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory SceneQuestStatus.fromDatabaseMap(Map<String, dynamic> map) {
    return SceneQuestStatus(
      id: ModelParsingHelper.safeId(map, 'id'),
      sceneId: ModelParsingHelper.safeString(map, 'scene_id', ''),
      questId: ModelParsingHelper.safeString(map, 'quest_id', ''),
      status: QuestStatus.values.firstWhere(
        (e) => e.name == ModelParsingHelper.safeString(map, 'status', 'active'),
        orElse: () => QuestStatus.active,
      ),
      progress: ModelParsingHelper.safeInt(map, 'progress', 0).clamp(0, 100),
      notes: ModelParsingHelper.safeStringOrNull(map, 'notes', null),
      lastUpdated: ModelParsingHelper.safeDateTime(map, 'last_updated', DateTime.now()),
    );
  }

  /// Konvertiert zu einer Map für die Datenbank
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'scene_id': sceneId,
      'quest_id': questId,
      'status': status.name,
      'progress': progress,
      'notes': notes,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  /// CopyWith-Methode für unveränderliche Updates
  SceneQuestStatus copyWith({
    String? id,
    String? sceneId,
    String? questId,
    QuestStatus? status,
    int? progress,
    String? notes,
    DateTime? lastUpdated,
  }) {
    return SceneQuestStatus(
      id: id ?? this.id,
      sceneId: sceneId ?? this.sceneId,
      questId: questId ?? this.questId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  // ========== HELPER METHODS ==========

  /// Aktualisiert den Progress und setzt lastUpdated automatisch
  SceneQuestStatus updateProgress(int newProgress) {
    return copyWith(
      progress: newProgress.clamp(0, 100),
      lastUpdated: DateTime.now(),
    );
  }

  /// Setzt den Status und aktualisiert Progress automatisch
  SceneQuestStatus setStatus(QuestStatus newStatus) {
    final newProgress = newStatus == QuestStatus.completed ? 100 : 
                        newStatus == QuestStatus.active ? progress.clamp(0, 99) : progress;
    return copyWith(
      status: newStatus,
      progress: newProgress,
      lastUpdated: DateTime.now(),
    );
  }

  /// Markiert Quest als abgeschlossen
  SceneQuestStatus complete() {
    return setStatus(QuestStatus.completed);
  }

  /// Markiert Quest als fehlgeschlagen
  SceneQuestStatus fail() {
    return setStatus(QuestStatus.failed);
  }

  /// Pausiert Quest
  SceneQuestStatus pause() {
    return setStatus(QuestStatus.paused);
  }

  /// Reaktiviert Quest
  SceneQuestStatus activate() {
    return setStatus(QuestStatus.active);
  }

  // ========== COMPATIBILITY GETTERS ==========

  /// Prüft ob Quest aktiv ist
  bool get isActive => status == QuestStatus.active;

  /// Prüft ob Quest abgeschlossen ist
  bool get isCompleted => status == QuestStatus.completed;

  /// Prüft ob Quest fehlgeschlagen ist
  bool get isFailed => status == QuestStatus.failed;

  /// Prüft ob Quest pausiert ist
  bool get isPaused => status == QuestStatus.paused;

  /// Prüft ob Notizen vorhanden sind
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  /// Lokalisierte Beschreibung für Status
  String get statusDescription {
    switch (status) {
      case QuestStatus.active:
        return 'Aktiv';
      case QuestStatus.paused:
        return 'Pausiert';
      case QuestStatus.completed:
        return 'Abgeschlossen';
      case QuestStatus.failed:
        return 'Fehlgeschlagen';
    }
  }

  /// Progress-String (z.B. "75%")
  String get progressString => '$progress%';

  /// Prüft ob Quest vollständig abgeschlossen ist
  bool get isFullyCompleted => status == QuestStatus.completed && progress == 100;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SceneQuestStatus && 
           other.sceneId == sceneId && 
           other.questId == questId;
  }

  @override
  int get hashCode => Object.hash(sceneId, questId);

  @override
  String toString() {
    return 'SceneQuestStatus(sceneId: $sceneId, questId: $questId, status: $status, progress: $progress%)';
  }
}