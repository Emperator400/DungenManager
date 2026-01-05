import 'base_entity.dart';
import '../../models/wiki_entry.dart';

/// Wiki Entity für die neue Datenbankarchitektur
/// Implementiert BaseEntity für konsistente Struktur und Typ-Sicherheit
class WikiEntity extends BaseEntity {
  // Core Felder
  String _id;
  final String title;
  final String content;
  final WikiEntryType entryType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? campaignId;
  final String? parentId;
  final List<String> tags;
  final List<String> childIds;
  final bool isMarkdown;
  final bool isFavorite;
  
  // Erweiterte Entity-Felder
  final String sourceType; // 'custom', 'official', 'import'
  final String? sourceId; // Referenz zur Original-Quelle
  final bool isCustom;
  final String version;
  final int priority; // Sortierung für Wiki-Listen
  final bool isPublic; // Sichtbarkeit für andere Spieler
  final String? imageUrl; // Bild für den Wiki-Eintrag
  final String? authorId; // Ersteller des Eintrags

  // Wiki-spezifische Felder
  final bool isLocked; // Bearbeitung gesperrt
  final DateTime? lockedUntil; // Sperrung endet
  final String? lockedBy; // Wer gesperrt hat
  final int viewCount; // Anzahl der Aufrufe
  final String? lastEditedBy; // Letzter Bearbeiter

  // Konstruktor
  WikiEntity({
    required String id,
    required this.title,
    required this.content,
    required this.entryType,
    required this.createdAt,
    required this.updatedAt,
    this.campaignId,
    this.parentId,
    this.tags = const [],
    this.childIds = const [],
    this.isMarkdown = false,
    this.isFavorite = false,
    this.sourceType = 'custom',
    this.sourceId,
    this.isCustom = true,
    this.version = '1.0',
    this.priority = 0,
    this.isPublic = false,
    this.imageUrl,
    this.authorId,
    this.isLocked = false,
    this.lockedUntil,
    this.lockedBy,
    this.viewCount = 0,
    this.lastEditedBy,
  }) : _id = id;

  /// Factory für Datenbank-Erstellung
  factory WikiEntity.fromMap(Map<String, dynamic> map) {
    return WikiEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      entryType: _parseWikiEntryType(map['entry_type'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      campaignId: map['campaign_id'] as String?,
      parentId: map['parent_id'] as String?,
      tags: _parseStringList(map['tags'] as String?),
      childIds: _parseStringList(map['child_ids'] as String?),
      isMarkdown: (map['is_markdown'] as int?) == 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      sourceType: map['source_type'] as String? ?? 'custom',
      sourceId: map['source_id'] as String?,
      isCustom: (map['is_custom'] as int?) == 1,
      version: map['version'] as String? ?? '1.0',
      priority: map['priority'] as int? ?? 0,
      isPublic: (map['is_public'] as int?) == 1,
      imageUrl: map['image_url'] as String?,
      authorId: map['author_id'] as String?,
      isLocked: (map['is_locked'] as int?) == 1,
      lockedUntil: map['locked_until'] != null 
          ? DateTime.parse(map['locked_until'] as String)
          : null,
      lockedBy: map['locked_by'] as String?,
      viewCount: map['view_count'] as int? ?? 0,
      lastEditedBy: map['last_edited_by'] as String?,
    );
  }

  /// Factory von WikiEntry Model
  factory WikiEntity.fromModel(WikiEntry entry, {
    String? sourceType,
    String? sourceId,
    bool? isCustom,
    String? version,
    int? priority,
    bool? isPublic,
    String? imageUrl,
    String? authorId,
    bool? isLocked,
    DateTime? lockedUntil,
    String? lockedBy,
    int? viewCount,
    String? lastEditedBy,
  }) {
    return WikiEntity(
      id: entry.id,
      title: entry.title,
      content: entry.content,
      entryType: entry.entryType,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      campaignId: entry.campaignId,
      parentId: entry.parentId,
      tags: entry.tags,
      childIds: entry.childIds,
      isMarkdown: entry.isMarkdown,
      isFavorite: entry.isFavorite,
      sourceType: sourceType ?? 'custom',
      sourceId: sourceId,
      isCustom: isCustom ?? true,
      version: version ?? '1.0',
      priority: priority ?? 0,
      isPublic: isPublic ?? false,
      imageUrl: imageUrl ?? entry.imageUrl,
      authorId: authorId ?? entry.createdBy,
      isLocked: isLocked ?? false,
      lockedUntil: lockedUntil,
      lockedBy: lockedBy,
      viewCount: viewCount ?? 0,
      lastEditedBy: lastEditedBy,
    );
  }

  /// Hilfsmethoden zum Parsen der Enums
  static WikiEntryType _parseWikiEntryType(String? typeString) {
    if (typeString == null) return WikiEntryType.Lore;
    
    try {
      return WikiEntryType.values.firstWhere(
        (type) => type.name == typeString,
        orElse: () => WikiEntryType.Lore,
      );
    } catch (e) {
      return WikiEntryType.Lore;
    }
  }

  /// Hilfsmethoden zur Serialisierung
  static String? _serializeStringList(List<String> list) {
    if (list.isEmpty) return null;
    return list.map((item) => item.replaceAll('"', '\\"')).join(',');
  }

  /// Hilfsmethoden zur Deserialisierung
  static List<String> _parseStringList(String? serialized) {
    if (serialized == null || serialized.isEmpty) return [];
    
    try {
      return serialized.split(',').map((item) {
        return item.replaceAll('\\"', '"').trim();
      }).where((item) => item.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  /// ID Getter aus BaseEntity
  @override
  String get id => _id;
  
  /// ID Setter aus BaseEntity
  @override
  set id(String value) => _id = value;
  
  /// Metadata Getter aus BaseEntity
  @override
  Map<String, dynamic> get metadata => {
    'entityType': 'Wiki',
    'tableName': tableName,
    'entryType': entryType.name,
    'campaignId': campaignId,
    'sourceType': sourceType,
    'priority': priority,
    'isPublic': isPublic,
    'viewCount': viewCount,
  };
  
  /// Validierung Getter aus BaseEntity
  @override
  bool get isValid {
    return title.isNotEmpty && 
           content.isNotEmpty &&
           (priority >= -1000 && priority <= 1000) &&
           (viewCount >= 0 && viewCount <= 1000000);
  }
  
  /// Validation Errors Getter aus BaseEntity
  @override
  List<String> get validationErrors {
    final errors = <String>[];
    if (title.isEmpty) errors.add('Titel darf nicht leer sein');
    if (content.isEmpty) errors.add('Inhalt darf nicht leer sein');
    if (title.length > 200) errors.add('Titel darf nicht länger als 200 Zeichen sein');
    if (priority < -1000 || priority > 1000) {
      errors.add('Priorität muss zwischen -1000 und 1000 liegen');
    }
    if (viewCount < 0 || viewCount > 1000000) {
      errors.add('View Count muss zwischen 0 und 1000000 liegen');
    }
    return errors;
  }

  /// Konvertierung zu Map für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'entry_type': entryType.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'campaign_id': campaignId,
      'parent_id': parentId,
      'tags': _serializeStringList(tags),
      'child_ids': _serializeStringList(childIds),
      'is_markdown': isMarkdown ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'source_type': sourceType,
      'source_id': sourceId,
      'is_custom': isCustom ? 1 : 0,
      'version': version,
      'priority': priority,
      'is_public': isPublic ? 1 : 0,
      'image_url': imageUrl,
      'author_id': authorId,
      'is_locked': isLocked ? 1 : 0,
      'locked_until': lockedUntil?.toIso8601String(),
      'locked_by': lockedBy,
      'view_count': viewCount,
      'last_edited_by': lastEditedBy,
    };
  }

  /// Konvertierung zurück zum WikiEntry Model
  WikiEntry toModel() {
    return WikiEntry(
      id: id,
      title: title,
      content: content,
      entryType: entryType,
      createdAt: createdAt,
      updatedAt: updatedAt,
      campaignId: campaignId,
      parentId: parentId,
      tags: tags,
      childIds: childIds,
      isMarkdown: isMarkdown,
      isFavorite: isFavorite,
      imageUrl: imageUrl,
      createdBy: authorId,
    );
  }

  /// Kopie mit geänderten Werten erstellen
  WikiEntity copyWith({
    String? id,
    String? title,
    String? content,
    WikiEntryType? entryType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? campaignId,
    String? parentId,
    List<String>? tags,
    List<String>? childIds,
    bool? isMarkdown,
    bool? isFavorite,
    String? sourceType,
    String? sourceId,
    bool? isCustom,
    String? version,
    int? priority,
    bool? isPublic,
    String? imageUrl,
    String? authorId,
    bool? isLocked,
    DateTime? lockedUntil,
    String? lockedBy,
    int? viewCount,
    String? lastEditedBy,
  }) {
    return WikiEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      entryType: entryType ?? this.entryType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      campaignId: campaignId ?? this.campaignId,
      parentId: parentId ?? this.parentId,
      tags: tags ?? this.tags,
      childIds: childIds ?? this.childIds,
      isMarkdown: isMarkdown ?? this.isMarkdown,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isCustom: isCustom ?? this.isCustom,
      version: version ?? this.version,
      priority: priority ?? this.priority,
      isPublic: isPublic ?? this.isPublic,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      isLocked: isLocked ?? this.isLocked,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      lockedBy: lockedBy ?? this.lockedBy,
      viewCount: viewCount ?? this.viewCount,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
    );
  }

  /// Datenbank-Tabellenname
  static const String tableName = 'wiki_entries';

  /// Erstelle Tabelle SQL
  static String createTableSql() {
    return '''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        entry_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        campaign_id TEXT,
        parent_id TEXT,
        tags TEXT,
        child_ids TEXT,
        is_markdown INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_custom INTEGER DEFAULT 1,
        version TEXT DEFAULT '1.0',
        priority INTEGER DEFAULT 0,
        is_public INTEGER DEFAULT 0,
        image_url TEXT,
        author_id TEXT,
        is_locked INTEGER DEFAULT 0,
        locked_until TEXT,
        locked_by TEXT,
        view_count INTEGER DEFAULT 0,
        last_edited_by TEXT
      )
    ''';
  }

  @override
  String toString() {
    return 'WikiEntity(id: $id, title: $title, type: $entryType, campaign: $campaignId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WikiEntity &&
           other.id == id &&
           other.title == title &&
           other.entryType == entryType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           title.hashCode ^
           entryType.hashCode;
  }
}
