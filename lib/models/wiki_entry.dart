// lib/models/wiki_entry.dart
import '../services/uuid_service.dart';
import '../services/wiki_entry_service.dart';
import '../utils/model_parsing_helper.dart';
import 'map_location.dart';

enum WikiEntryType { 
  Person, 
  Place, 
  Lore, 
  Faction, 
  Magic,
  History,
  Item,
  Quest,
  Creature
}

/// Reines Datenmodell für Wiki Entries
class WikiEntry {
  final String id;
  final String title;
  final String content;
  final WikiEntryType entryType;
  final MapLocation? location;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? campaignId;
  final String? imageUrl;
  final String? createdBy;
  final String? parentId;
  final List<String> childIds;
  final bool isMarkdown;
  final bool isFavorite;

  const WikiEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.entryType,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.campaignId,
    this.imageUrl,
    this.createdBy,
    this.parentId,
    required this.childIds,
    required this.isMarkdown,
    required this.isFavorite,
  });

  /// Factory für neuen Wiki Entry
  factory WikiEntry.create({
    required String title,
    required String content,
    required WikiEntryType entryType,
    MapLocation? location,
    List<String>? tags,
    String? campaignId,
    String? imageUrl,
    String? createdBy,
    String? parentId,
    List<String>? childIds,
    bool isMarkdown = false,
    bool isFavorite = false,
  }) {
    final now = DateTime.now();
    return WikiEntry(
      id: UuidService().generateId(),
      title: title,
      content: content,
      entryType: entryType,
      location: location,
      tags: tags ?? [],
      createdAt: now,
      updatedAt: now,
      campaignId: campaignId,
      imageUrl: imageUrl,
      createdBy: createdBy,
      parentId: parentId,
      childIds: childIds ?? [],
      isMarkdown: isMarkdown,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'entry_type': entryType.name,
      'location_data': location?.toJsonString(),
      'tags': WikiEntryService.serializeTags(tags),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'campaign_id': campaignId,
      'image_url': imageUrl,
      'created_by': createdBy,
      'parent_id': parentId,
      'child_ids': WikiEntryService.serializeChildIds(childIds),
      'is_markdown': isMarkdown ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory WikiEntry.fromMap(Map<String, dynamic> map) {
    return WikiEntry(
      id: ModelParsingHelper.safeId(map, 'id'),
      title: ModelParsingHelper.safeString(map, 'title', ''),
      content: ModelParsingHelper.safeString(map, 'content', ''),
      entryType: WikiEntryType.values.firstWhere(
        (e) => e.name == ModelParsingHelper.safeString(map, 'entry_type', 'Lore'),
        orElse: () => WikiEntryType.Lore,
      ),
      location: ModelParsingHelper.safeStringOrNull(map, 'location_data', null) != null 
          ? MapLocation.fromJsonString(ModelParsingHelper.safeString(map, 'location_data', ''))
          : null,
      tags: WikiEntryService.deserializeTags(ModelParsingHelper.safeStringOrNull(map, 'tags', null)),
      createdAt: DateTime.fromMillisecondsSinceEpoch(ModelParsingHelper.safeInt(map, 'created_at', DateTime.now().millisecondsSinceEpoch)),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(ModelParsingHelper.safeInt(map, 'updated_at', DateTime.now().millisecondsSinceEpoch)),
      campaignId: ModelParsingHelper.safeStringOrNull(map, 'campaign_id', null),
      imageUrl: ModelParsingHelper.safeStringOrNull(map, 'image_url', null),
      createdBy: ModelParsingHelper.safeStringOrNull(map, 'created_by', null),
      parentId: ModelParsingHelper.safeStringOrNull(map, 'parent_id', null),
      childIds: WikiEntryService.deserializeChildIds(ModelParsingHelper.safeStringOrNull(map, 'child_ids', null)),
      isMarkdown: ModelParsingHelper.safeBool(map, 'is_markdown', false),
      isFavorite: ModelParsingHelper.safeBool(map, 'is_favorite', false),
    );
  }

  /// Erstellt eine Kopie mit aktualisierten Werten
  WikiEntry copyWith({
    String? id,
    String? title,
    String? content,
    WikiEntryType? entryType,
    MapLocation? location,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? campaignId,
    String? imageUrl,
    String? createdBy,
    String? parentId,
    List<String>? childIds,
    bool? isMarkdown,
    bool? isFavorite,
  }) {
    return WikiEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      entryType: entryType ?? this.entryType,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      campaignId: campaignId ?? this.campaignId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? this.childIds,
      isMarkdown: isMarkdown ?? this.isMarkdown,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WikiEntry &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.entryType == entryType &&
        other.location == location &&
        other.campaignId == campaignId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        entryType.hashCode ^
        location.hashCode ^
        campaignId.hashCode;
  }

  @override
  String toString() {
    return 'WikiEntry(id: $id, title: $title, type: $entryType, tags: ${tags.length}, campaignId: $campaignId, isFavorite: $isFavorite)';
  }

  // Helper getters für Tests
  bool get hasLocation => location != null;
  bool get hasTags => tags.isNotEmpty;
  bool get isGlobal => campaignId == null || campaignId!.isEmpty;
  bool get hasParent => parentId != null && parentId!.isNotEmpty;
  bool get hasWikiLinks => childIds.isNotEmpty;

  // Helper methods für Tests
  bool belongsToCampaign(String campaignId) {
    return this.campaignId == campaignId;
  }

  WikiEntry addTag(String tag) {
    final newTags = List<String>.from(tags);
    if (!newTags.contains(tag)) {
      newTags.add(tag);
    }
    return copyWith(tags: newTags);
  }

  WikiEntry removeTag(String tag) {
    final newTags = List<String>.from(tags);
    newTags.remove(tag);
    return copyWith(tags: newTags);
  }
}
