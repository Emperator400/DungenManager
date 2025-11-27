import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

/// Typ von Wiki Links
enum WikiLinkType {
  reference,    // Normaler Verweis [[Entry]]
  parent,       // Parent/Child Beziehung
  related,       // Verwandter Eintrag
  seeAlso,       // "Siehe auch" Verweis
}

///单个 Wiki Link zwischen zwei Einträgen
class WikiLink {
  final String id;
  final String sourceEntryId;  // Ausgangs-Eintrag
  final String targetEntryId;  // Ziel-Eintrag
  final WikiLinkType linkType;
  final DateTime createdAt;
  final String? createdBy;  // Wer den Link erstellt hat

  WikiLink({
    String? id,
    required this.sourceEntryId,
    required this.targetEntryId,
    required this.linkType,
    DateTime? createdAt,
    this.createdBy,
  }) : id = id ?? UuidService().generateId(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_entry_id': sourceEntryId,
      'target_entry_id': targetEntryId,
      'link_type': linkType.toString(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'created_by': createdBy,
    };
  }

  factory WikiLink.fromMap(Map<String, dynamic> map) {
    return WikiLink(
      id: ModelParsingHelper.safeId(map, 'id'),
      sourceEntryId: ModelParsingHelper.safeString(map, 'source_entry_id', ''),
      targetEntryId: ModelParsingHelper.safeString(map, 'target_entry_id', ''),
      linkType: WikiLinkType.values.firstWhere(
        (e) => e.toString() == ModelParsingHelper.safeString(map, 'link_type', 'WikiLinkType.reference'),
        orElse: () => WikiLinkType.reference,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(ModelParsingHelper.safeInt(map, 'created_at', 0)),
      createdBy: ModelParsingHelper.safeStringOrNull(map, 'created_by', null),
    );
  }

  WikiLink copyWith({
    String? id,
    String? sourceEntryId,
    String? targetEntryId,
    WikiLinkType? linkType,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return WikiLink(
      id: id ?? this.id,
      sourceEntryId: sourceEntryId ?? this.sourceEntryId,
      targetEntryId: targetEntryId ?? this.targetEntryId,
      linkType: linkType ?? this.linkType,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WikiLink &&
        other.id == id &&
        other.sourceEntryId == sourceEntryId &&
        other.targetEntryId == targetEntryId &&
        other.linkType == linkType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sourceEntryId.hashCode ^
        targetEntryId.hashCode ^
        linkType.hashCode;
  }

  @override
  String toString() {
    return 'WikiLink(id: $id, source: $sourceEntryId, target: $targetEntryId, type: $linkType)';
  }
}
