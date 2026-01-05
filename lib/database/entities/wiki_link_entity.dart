import 'base_entity.dart';
import '../../models/wiki_link.dart';

/// WikiLink Entity für die Datenbank
class WikiLinkEntity extends BaseEntity {
  String _id;
  final String sourceEntryId;
  final String targetEntryId;
  final WikiLinkType linkType;
  DateTime createdAt;
  final String? createdBy;

  WikiLinkEntity({
    required String id,
    required this.sourceEntryId,
    required this.targetEntryId,
    required this.linkType,
    DateTime? createdAt,
    this.createdBy,
  }) : _id = id,
       createdAt = createdAt ?? DateTime.now();

  /// Erstellt eine WikiLinkEntity aus einem WikiLink Model
  factory WikiLinkEntity.fromModel(WikiLink wikiLink) {
    return WikiLinkEntity(
      id: wikiLink.id,
      sourceEntryId: wikiLink.sourceEntryId,
      targetEntryId: wikiLink.targetEntryId,
      linkType: wikiLink.linkType,
      createdAt: wikiLink.createdAt,
      createdBy: wikiLink.createdBy,
    );
  }

  /// Konvertiert die Entity zu einem WikiLink Model
  WikiLink toModel() {
    return WikiLink(
      id: id,
      sourceEntryId: sourceEntryId,
      targetEntryId: targetEntryId,
      linkType: linkType,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  /// Erstellt eine WikiLinkEntity aus einer Datenbank-Map
  factory WikiLinkEntity.fromMap(Map<String, dynamic> map) {
    return WikiLinkEntity(
      id: map['id'] as String,
      sourceEntryId: map['source_entry_id'] as String,
      targetEntryId: map['target_entry_id'] as String,
      linkType: WikiLinkType.values.firstWhere(
        (type) => type.name == map['link_type'],
        orElse: () => WikiLinkType.reference,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as String?,
    );
  }

  /// Erstellt eine Kopie mit aktualisierten Werten
  WikiLinkEntity copyWith({
    String? id,
    String? sourceEntryId,
    String? targetEntryId,
    WikiLinkType? linkType,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return WikiLinkEntity(
      id: id ?? this.id,
      sourceEntryId: sourceEntryId ?? this.sourceEntryId,
      targetEntryId: targetEntryId ?? this.targetEntryId,
      linkType: linkType ?? this.linkType,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
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
    'entityType': 'WikiLink',
    'linkType': linkType.toString(),
    'sourceEntryId': sourceEntryId,
    'targetEntryId': targetEntryId,
    'createdBy': createdBy,
  };
  
  /// Validierung Getter aus BaseEntity
  @override
  bool get isValid {
    return sourceEntryId.isNotEmpty && 
           targetEntryId.isNotEmpty &&
           sourceEntryId != targetEntryId;
  }
  
  /// Validation Errors Getter aus BaseEntity
  @override
  List<String> get validationErrors {
    final errors = <String>[];
    if (sourceEntryId.isEmpty) errors.add('Source entry ID cannot be empty');
    if (targetEntryId.isEmpty) errors.add('Target entry ID cannot be empty');
    if (sourceEntryId == targetEntryId) errors.add('Source and target cannot be the same');
    return errors;
  }

  @override
  String toString() {
    return 'WikiLinkEntity(id: $id, sourceEntryId: $sourceEntryId, targetEntryId: $targetEntryId, linkType: $linkType, createdBy: $createdBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WikiLinkEntity &&
        other.id == id &&
        other.sourceEntryId == sourceEntryId &&
        other.targetEntryId == targetEntryId &&
        other.linkType == linkType &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sourceEntryId.hashCode ^
        targetEntryId.hashCode ^
        linkType.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode;
  }
}
