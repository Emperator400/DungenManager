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
  DateTime createdAt;
  DateTime updatedAt;

  // Konstruktor
  SessionEntity({
    required String id,
    required this.campaignId,
    required this.title,
    required this.inGameTimeInMinutes,
    required this.liveNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : _id = id,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Factory für Datenbank-Erstellung
  factory SessionEntity.fromMap(Map<String, dynamic> map) {
    return SessionEntity(
      id: map['id'] as String,
      campaignId: map['campaignId'] as String,
      title: map['title'] as String,
      inGameTimeInMinutes: map['inGameTimeInMinutes'] as int,
      liveNotes: map['liveNotes'] as String,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
    'createdAt',
    'updatedAt',
  ];

  @override
  List<String> get createTableSql => [
    '''
    CREATE TABLE sessions (
      id TEXT PRIMARY KEY,
      campaignId TEXT NOT NULL,
      title TEXT NOT NULL,
      inGameTimeInMinutes INTEGER NOT NULL DEFAULT 0,
      liveNotes TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionEntity(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      title: title ?? this.title,
      inGameTimeInMinutes: inGameTimeInMinutes ?? this.inGameTimeInMinutes,
      liveNotes: liveNotes ?? this.liveNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      updatedAt: now,
    );
  }

  static String _generateId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
}
