// lib/models/session.dart
/// Session-Model für D&D Kampagnen
/// 
/// Repräsentiert eine Spielsitzung mit erweiterten Features:
/// - Scene Planning (pre-session)
/// - Quest Progress Tracking
/// - Character Tracking (HP, Conditions)
/// - Encounter Management
/// - Live Notes
library;

import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

class Session {
  final String id;
  final String campaignId;
  final String title;
  final int inGameTimeInMinutes;
  final String liveNotes;
  
  // Neue Felder für erweiterte Session-Features
  final List<String> sceneIds; // Geplante Scenes
  final String? activeSceneId; // Aktive Scene
  final List<String> encounterIds; // Kampfbegegnungen
  final List<String> questProgressIds; // Quest-Fortschritt
  final List<String> characterTrackingIds; // Character-Tracking
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  Session({
    String? id,
    required this.campaignId,
    required this.title,
    this.inGameTimeInMinutes = 480,
    this.liveNotes = "",
    this.sceneIds = const [],
    this.activeSceneId,
    this.encounterIds = const [],
    this.questProgressIds = const [],
    this.characterTrackingIds = const [],
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
  }) : id = id ?? UuidService().generateId(),
        createdAt = createdAt ?? DateTime.now();

  /// Factory für neue Sessions
  factory Session.create({
    required String campaignId,
    required String title,
    String description = '',
  }) {
    return Session(
      campaignId: campaignId,
      title: title,
      liveNotes: description,
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

  /// Konvertiert das Session zu einer Datenbank-Map (Legacy)
  Map<String, dynamic> toMap() {
    return toDatabaseMap();
  }

  /// Konvertiert das Session zu einer Datenbank-Map (Neu)
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'campaignId': campaignId,
      'title': title,
      'inGameTimeInMinutes': inGameTimeInMinutes,
      'liveNotes': liveNotes,
      'sceneIds': _serializeStringList(sceneIds),
      'activeSceneId': activeSceneId,
      'encounterIds': _serializeStringList(encounterIds),
      'questProgressIds': _serializeStringList(questProgressIds),
      'characterTrackingIds': _serializeStringList(characterTrackingIds),
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Factory für Datenbank-Map mit sicherem Parsing (Legacy)
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session.fromDatabaseMap(map);
  }

  /// Factory für Datenbank-Map mit sicherem Parsing (Neu)
  factory Session.fromDatabaseMap(Map<String, dynamic> map) {
    return Session(
      id: ModelParsingHelper.safeId(map, 'id'),
      campaignId: ModelParsingHelper.safeString(map, 'campaignId', ''),
      title: ModelParsingHelper.safeString(map, 'title', 'Unbenannte Session'),
      inGameTimeInMinutes: ModelParsingHelper.safeInt(map, 'inGameTimeInMinutes', 480),
      liveNotes: ModelParsingHelper.safeString(map, 'liveNotes', ''),
      sceneIds: _deserializeStringList(map['sceneIds'] as String?),
      activeSceneId: ModelParsingHelper.safeStringOrNull(map, 'activeSceneId', null),
      encounterIds: _deserializeStringList(map['encounterIds'] as String?),
      questProgressIds: _deserializeStringList(map['questProgressIds'] as String?),
      characterTrackingIds: _deserializeStringList(map['characterTrackingIds'] as String?),
      createdAt: ModelParsingHelper.safeDateTime(map, 'createdAt', DateTime.now()),
      startedAt: ModelParsingHelper.safeDateTimeOrNull(map, 'startedAt', null),
      completedAt: ModelParsingHelper.safeDateTimeOrNull(map, 'completedAt', null),
    );
  }

  /// CopyWith-Methode für unveränderliche Updates
  Session copyWith({
    String? id,
    String? campaignId,
    String? title,
    int? inGameTimeInMinutes,
    String? liveNotes,
    List<String>? sceneIds,
    String? activeSceneId,
    List<String>? encounterIds,
    List<String>? questProgressIds,
    List<String>? characterTrackingIds,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Session(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      title: title ?? this.title,
      inGameTimeInMinutes: inGameTimeInMinutes ?? this.inGameTimeInMinutes,
      liveNotes: liveNotes ?? this.liveNotes,
      sceneIds: sceneIds ?? this.sceneIds,
      activeSceneId: activeSceneId ?? this.activeSceneId,
      encounterIds: encounterIds ?? this.encounterIds,
      questProgressIds: questProgressIds ?? this.questProgressIds,
      characterTrackingIds: characterTrackingIds ?? this.characterTrackingIds,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // ========== COMPATIBILITY GETTERS ==========

  /// Prüft ob Session aktiv ist
  bool get isActive => startedAt != null && completedAt == null;

  /// Prüft ob Session abgeschlossen ist
  bool get isCompleted => completedAt != null;

  /// Prüft ob Session noch nicht gestartet ist
  bool get isPending => startedAt == null;

  /// Anzahl der Scenes
  int get sceneCount => sceneIds.length;

  /// Anzahl der Encounters
  int get encounterCount => encounterIds.length;

  /// Anzahl der Quests
  int get questCount => questProgressIds.length;

  /// Anzahl der Character Trackings
  int get characterTrackingCount => characterTrackingIds.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Session(id: $id, title: $title, scenes: $sceneCount, encounters: $encounterCount)';
  }
}
