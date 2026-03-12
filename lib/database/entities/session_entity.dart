import '../core/database_entity.dart';
import 'base_entity.dart';
import '../../models/session.dart';

/// Session Entity für die neue Datenbankarchitektur
/// Implementiert DatabaseEntity und BaseEntity für konsistente Struktur und Typ-Sicherheit
class SessionEntity extends BaseEntity implements DatabaseEntity<SessionEntity> {
  // Core Felder
  String _id;
  final String campaignId;
  final String title;
  final int inGameTimeInMinutes;
  final String liveNotes;
  final String? sceneIds;
  final String? activeSceneId;
  final String? encounterIds;
  final String? questProgressIds;
  final String? characterTrackingIds;
  final String? linkedSoundIds;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Konstruktor
  SessionEntity({
    required String id,
    required this.campaignId,
    required this.title,
    required this.inGameTimeInMinutes,
    required this.liveNotes,
    this.sceneIds,
    this.activeSceneId,
    this.encounterIds,
    this.questProgressIds,
    this.characterTrackingIds,
    this.linkedSoundIds,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
  })  : _id = id,
        createdAt = createdAt ?? DateTime.now();

  /// Factory für Datenbank-Erstellung
  factory SessionEntity.fromMap(Map<String, dynamic> map) {
    return SessionEntity(
      id: map['id'] as String,
      campaignId: map['campaignId'] as String,
      title: map['title'] as String,
      inGameTimeInMinutes: map['inGameTimeInMinutes'] as int,
      liveNotes: map['liveNotes'] as String,
      sceneIds: map['sceneIds'] as String?,
      activeSceneId: map['activeSceneId'] as String?,
      encounterIds: map['encounterIds'] as String?,
      questProgressIds: map['questProgressIds'] as String?,
      characterTrackingIds: map['characterTrackingIds'] as String?,
      linkedSoundIds: map['linkedSoundIds'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt'] as String) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
    );
  }

  /// Factory von Session Model
  factory SessionEntity.fromModel(Session session) {
    return SessionEntity(
      id: session.id,
      campaignId: session.campaignId,
      title: session.title,
      inGameTimeInMinutes: session.inGameTimeInMinutes,
      liveNotes: session.liveNotes,
      sceneIds: session.sceneIds?.join(','),
      activeSceneId: session.activeSceneId,
      encounterIds: session.encounterIds?.join(','),
      questProgressIds: session.questProgressIds?.join(','),
      characterTrackingIds: session.characterTrackingIds?.join(','),
      linkedSoundIds: session.linkedSoundIds?.join(','),
      createdAt: session.createdAt,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
    );
  }

  // DatabaseEntity Implementation

  @override
  String get tableName => 'sessions';

  @override
  String get primaryKeyField => 'id';

  @override
  List<String> get databaseFields => [
    'id',
    'campaignId',
    'title',
    'inGameTimeInMinutes',
    'liveNotes',
    'sceneIds',
    'activeSceneId',
    'encounterIds',
    'questProgressIds',
    'characterTrackingIds',
    'linkedSoundIds',
    'createdAt',
    'startedAt',
    'completedAt',
  ];

  @override
  List<String> get createTableSql => [
    '''
    CREATE TABLE sessions (
      id TEXT PRIMARY KEY,
      campaignId TEXT NOT NULL,
      title TEXT NOT NULL,
      inGameTimeInMinutes INTEGER NOT NULL DEFAULT 480,
      liveNotes TEXT DEFAULT '',
      sceneIds TEXT,
      activeSceneId TEXT,
      encounterIds TEXT,
      questProgressIds TEXT,
      characterTrackingIds TEXT,
      linkedSoundIds TEXT,
      createdAt TEXT NOT NULL,
      startedAt TEXT,
      completedAt TEXT,
      FOREIGN KEY (campaignId) REFERENCES campaigns (id) ON DELETE CASCADE
    )
    ''',
  ];

  @override
  List<String> get createIndexes => [
    'CREATE INDEX idx_sessions_campaignId ON sessions(campaignId)',
    'CREATE INDEX idx_sessions_title ON sessions(title)',
    'CREATE INDEX idx_sessions_createdAt ON sessions(createdAt)',
  ];

  @override
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'campaignId': campaignId,
      'title': title,
      'inGameTimeInMinutes': inGameTimeInMinutes,
      'liveNotes': liveNotes,
      'sceneIds': sceneIds,
      'activeSceneId': activeSceneId,
      'encounterIds': encounterIds,
      'questProgressIds': questProgressIds,
      'characterTrackingIds': characterTrackingIds,
      'linkedSoundIds': linkedSoundIds,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  @override
  SessionEntity fromDatabaseMap(Map<String, dynamic> map) {
    return SessionEntity.fromMap(map);
  }

  @override
  bool get isValid {
    return campaignId.isNotEmpty && 
           title.isNotEmpty && 
           inGameTimeInMinutes >= 0;
  }

  @override
  List<String> get validationErrors {
    final errors = <String>[];
    if (campaignId.isEmpty) errors.add('Campaign ID darf nicht leer sein');
    if (title.isEmpty) errors.add('Titel darf nicht leer sein');
    if (inGameTimeInMinutes < 0) errors.add('Spielzeit darf nicht negativ sein');
    return errors;
  }

  @override
  Map<String, dynamic> get metadata => {
    'entityType': 'Session',
    'campaignId': campaignId,
    'tableName': tableName,
    'hasLiveNotes': liveNotes.isNotEmpty,
    'durationMinutes': inGameTimeInMinutes,
  };

  @override
  SessionEntity copyWith({
    String? id,
    String? campaignId,
    String? title,
    int? inGameTimeInMinutes,
    String? liveNotes,
    String? sceneIds,
    String? activeSceneId,
    String? encounterIds,
    String? questProgressIds,
    String? characterTrackingIds,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return SessionEntity(
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

  @override
  String toString() {
    return 'SessionEntity(id: $id, campaignId: $campaignId, title: $title, inGameTimeInMinutes: $inGameTimeInMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionEntity &&
           other.id == id &&
           other.campaignId == campaignId &&
           other.title == title &&
           other.inGameTimeInMinutes == inGameTimeInMinutes &&
           other.liveNotes == liveNotes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           campaignId.hashCode ^
           title.hashCode ^
           inGameTimeInMinutes.hashCode ^
           liveNotes.hashCode;
  }

  // BaseEntity Implementation

  /// ID Getter aus BaseEntity
  @override
  String get id => _id;
  
  /// ID Setter aus BaseEntity
  @override
  set id(String value) => _id = value;

  // DatabaseEntity Helper Methods

  @override
  String toSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .toLowerCase();
  }
  
  @override
  String toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.length == 1) return parts.first;
    
    return parts.first + parts
        .skip(1)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join('');
  }
  
  @override
  Map<String, dynamic> convertToSnakeCase(Map<String, dynamic> camelCaseMap) {
    final snakeCaseMap = <String, dynamic>{};
    
    for (final entry in camelCaseMap.entries) {
      final snakeKey = toSnakeCase(entry.key);
      snakeCaseMap[snakeKey] = entry.value;
    }
    
    return snakeCaseMap;
  }
  
  @override
  Map<String, dynamic> convertToCamelCase(Map<String, dynamic> snakeCaseMap) {
    final camelCaseMap = <String, dynamic>{};
    
    for (final entry in snakeCaseMap.entries) {
      final camelKey = toCamelCase(entry.key);
      camelCaseMap[camelKey] = entry.value;
    }
    
    return camelCaseMap;
  }

  /// Konvertierung zurück zum Session Model
  Session toModel() {
    return Session(
      id: id,
      campaignId: campaignId,
      title: title,
      inGameTimeInMinutes: inGameTimeInMinutes,
      liveNotes: liveNotes,
      sceneIds: sceneIds?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      activeSceneId: activeSceneId,
      encounterIds: encounterIds?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      questProgressIds: questProgressIds?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      characterTrackingIds: characterTrackingIds?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      linkedSoundIds: linkedSoundIds?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  /// Convenience factory for creating new sessions
  factory SessionEntity.create({
    required String campaignId,
    required String title,
    int inGameTimeInMinutes = 0,
    String? liveNotes,
  }) {
    final now = DateTime.now();
    
    return SessionEntity(
      id: _generateId(),
      campaignId: campaignId,
      title: title.trim(),
      inGameTimeInMinutes: inGameTimeInMinutes,
      liveNotes: liveNotes?.trim() ?? '',
      createdAt: now,
    );
  }

  static String _generateId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
}
