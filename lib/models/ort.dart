import '../services/uuid_service.dart';
import '../utils/string_list_parser.dart';

enum OrtType {
  dungeon,
  city,
  building,
  wilderness,
  region,
  other,
  token,
}

extension OrtTypeLabel on OrtType {
  String get label {
    switch (this) {
      case OrtType.dungeon:    return 'Dungeon';
      case OrtType.city:       return 'Stadt';
      case OrtType.building:   return 'Gebäude';
      case OrtType.wilderness: return 'Wildnis';
      case OrtType.region:     return 'Region';
      case OrtType.other:      return 'Sonstiges';
      case OrtType.token:      return 'Token';
    }
  }
}

class Ort {
  final String id;
  final String campaignId;
  final String name;
  final OrtType type;
  final String description;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Wiki-Verlinkungen
  final List<String> linkedWikiEntryIds;

  // Verbindungen zu anderen Orten (für Graph-Darstellung)
  final List<String> connectedOrtIds;

  // Zustandsfelder — werden beim Template-Sync NIE überschrieben
  final DateTime? lastVisitedAt;
  final String? memory;

  // Template-Linking
  final String? templateOrtId;

  // Karten-Koordinaten (0.0–1.0 relativ zur Kartengröße)
  final double? mapX;
  final double? mapY;

  // Subkarten-Hierarchie: null = Weltkarte, gesetzt = Subkarte dieses Eltern-Ortes
  final String? parentOrtId;

  // Hintergrundbild für die Subkarte dieses Ortes
  final String? mapImagePath;

  // Bild für OrtType.token — wird im Token-Kreis statt Buchstaben gezeigt
  final String? tokenImagePath;

  // Pin-Position auf der Karte gesperrt (kein Drag möglich)
  final bool mapPositionLocked;

  // Vom Template-Sync ausgeblendet (Ort wurde aus Vorlage entfernt)
  final bool isHidden;

  static const String tableName = 'orte';

  const Ort({
    required this.id,
    required this.campaignId,
    required this.name,
    this.type = OrtType.other,
    this.description = '',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.linkedWikiEntryIds = const [],
    this.connectedOrtIds = const [],
    this.lastVisitedAt,
    this.memory,
    this.templateOrtId,
    this.mapX,
    this.mapY,
    this.parentOrtId,
    this.mapImagePath,
    this.tokenImagePath,
    this.mapPositionLocked = false,
    this.isHidden = false,
  });

  factory Ort.create({
    required String campaignId,
    required String name,
    OrtType type = OrtType.other,
    String description = '',
    int sortOrder = 0,
    String? templateOrtId,
    String? parentOrtId,
    List<String> linkedWikiEntryIds = const [],
  }) {
    final now = DateTime.now();
    return Ort(
      id: UuidService().generateId(),
      campaignId: campaignId,
      name: name,
      type: type,
      description: description,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
      linkedWikiEntryIds: linkedWikiEntryIds,
      connectedOrtIds: const [],
      templateOrtId: templateOrtId,
      parentOrtId: parentOrtId,
    );
  }

  factory Ort.fromDatabaseMap(Map<String, dynamic> map) {
    return Ort(
      id: map['id'] as String,
      campaignId: map['campaign_id'] as String,
      name: map['name'] as String? ?? '',
      type: OrtType.values.firstWhere(
        (t) => t.toString().split('.').last == (map['type'] as String? ?? 'other'),
        orElse: () => OrtType.other,
      ),
      description: map['description'] as String? ?? '',
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      linkedWikiEntryIds: StringListParser.parseStringList(map['linked_wiki_entry_ids'] as String?),
      connectedOrtIds: StringListParser.parseStringList(map['connected_ort_ids'] as String?),
      lastVisitedAt: map['last_visited_at'] != null
          ? DateTime.tryParse(map['last_visited_at'] as String)
          : null,
      memory: map['memory'] as String?,
      templateOrtId: map['template_ort_id'] as String?,
      mapX: (map['map_x'] as num?)?.toDouble(),
      mapY: (map['map_y'] as num?)?.toDouble(),
      parentOrtId: map['parent_ort_id'] as String?,
      mapImagePath: map['map_image_path'] as String?,
      tokenImagePath: map['token_image_path'] as String?,
      mapPositionLocked: (map['map_position_locked'] as int? ?? 0) == 1,
      isHidden: (map['is_hidden'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toDatabaseMap() => {
        'id': id,
        'campaign_id': campaignId,
        'name': name,
        'type': type.toString().split('.').last,
        'description': description,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'linked_wiki_entry_ids': linkedWikiEntryIds.isEmpty ? null : linkedWikiEntryIds.join(','),
        'connected_ort_ids': connectedOrtIds.isEmpty ? null : connectedOrtIds.join(','),
        'last_visited_at': lastVisitedAt?.toIso8601String(),
        'memory': memory,
        'template_ort_id': templateOrtId,
        'map_x': mapX,
        'map_y': mapY,
        'parent_ort_id': parentOrtId,
        'map_image_path': mapImagePath,
        'token_image_path': tokenImagePath,
        'map_position_locked': mapPositionLocked ? 1 : 0,
        'is_hidden': isHidden ? 1 : 0,
      };

  Ort copyWith({
    String? id,
    String? campaignId,
    String? name,
    OrtType? type,
    String? description,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? linkedWikiEntryIds,
    List<String>? connectedOrtIds,
    Object? lastVisitedAt = _sentinel,
    Object? memory = _sentinel,
    Object? templateOrtId = _sentinel,
    Object? mapX = _sentinel,
    Object? mapY = _sentinel,
    Object? parentOrtId = _sentinel,
    Object? mapImagePath = _sentinel,
    Object? tokenImagePath = _sentinel,
    bool? mapPositionLocked,
    bool? isHidden,
  }) =>
      Ort(
        id: id ?? this.id,
        campaignId: campaignId ?? this.campaignId,
        name: name ?? this.name,
        type: type ?? this.type,
        description: description ?? this.description,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        linkedWikiEntryIds: linkedWikiEntryIds ?? List<String>.from(this.linkedWikiEntryIds),
        connectedOrtIds: connectedOrtIds ?? List<String>.from(this.connectedOrtIds),
        lastVisitedAt: lastVisitedAt == _sentinel
            ? this.lastVisitedAt
            : lastVisitedAt as DateTime?,
        memory: memory == _sentinel ? this.memory : memory as String?,
        templateOrtId: templateOrtId == _sentinel
            ? this.templateOrtId
            : templateOrtId as String?,
        mapX: mapX == _sentinel ? this.mapX : mapX as double?,
        mapY: mapY == _sentinel ? this.mapY : mapY as double?,
        parentOrtId: parentOrtId == _sentinel ? this.parentOrtId : parentOrtId as String?,
        mapImagePath: mapImagePath == _sentinel ? this.mapImagePath : mapImagePath as String?,
        tokenImagePath: tokenImagePath == _sentinel ? this.tokenImagePath : tokenImagePath as String?,
        mapPositionLocked: mapPositionLocked ?? this.mapPositionLocked,
        isHidden: isHidden ?? this.isHidden,
      );

  static const Object _sentinel = Object();

  bool get hasBeenVisited => lastVisitedAt != null;
  bool get hasMemory => memory != null && memory!.isNotEmpty;
  bool get isCopy => templateOrtId != null;
  bool get isOnMap => mapX != null && mapY != null;
  bool get isOnSubMap => parentOrtId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ort && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Ort(id: $id, name: $name, type: $type)';
}
