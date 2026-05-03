import '../services/uuid_service.dart';

enum OrtType {
  dungeon,
  city,
  building,
  wilderness,
  other,
}

extension OrtTypeLabel on OrtType {
  String get label {
    switch (this) {
      case OrtType.dungeon:    return 'Dungeon';
      case OrtType.city:       return 'Stadt';
      case OrtType.building:   return 'Gebäude';
      case OrtType.wilderness: return 'Wildnis';
      case OrtType.other:      return 'Sonstiges';
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

  // Zustandsfelder — werden beim Template-Sync NIE überschrieben
  final DateTime? lastVisitedAt;
  final String? memory;

  // Template-Linking
  final String? templateOrtId;

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
    this.lastVisitedAt,
    this.memory,
    this.templateOrtId,
  });

  factory Ort.create({
    required String campaignId,
    required String name,
    OrtType type = OrtType.other,
    String description = '',
    int sortOrder = 0,
    String? templateOrtId,
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
      templateOrtId: templateOrtId,
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
      lastVisitedAt: map['last_visited_at'] != null
          ? DateTime.tryParse(map['last_visited_at'] as String)
          : null,
      memory: map['memory'] as String?,
      templateOrtId: map['template_ort_id'] as String?,
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
        'last_visited_at': lastVisitedAt?.toIso8601String(),
        'memory': memory,
        'template_ort_id': templateOrtId,
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
    Object? lastVisitedAt = _sentinel,
    Object? memory = _sentinel,
    Object? templateOrtId = _sentinel,
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
        lastVisitedAt: lastVisitedAt == _sentinel
            ? this.lastVisitedAt
            : lastVisitedAt as DateTime?,
        memory: memory == _sentinel ? this.memory : memory as String?,
        templateOrtId: templateOrtId == _sentinel
            ? this.templateOrtId
            : templateOrtId as String?,
      );

  static const Object _sentinel = Object();

  bool get hasBeenVisited => lastVisitedAt != null;
  bool get hasMemory => memory != null && memory!.isNotEmpty;
  bool get isCopy => templateOrtId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ort && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Ort(id: $id, name: $name, type: $type)';
}
