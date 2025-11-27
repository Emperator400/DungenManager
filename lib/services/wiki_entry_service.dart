// Dart Core
import 'dart:async';

// Eigene Projekte
import '../database/database_helper.dart';
import '../models/wiki_entry.dart';
import '../utils/string_list_parser.dart';
import 'exceptions/service_exceptions.dart';

/// Service für die Verwaltung von Wiki Entries
/// 
/// Bietet CRUD-Operationen und Business-Logic für Wiki-Einträge.
/// Verwendet spezifische Exceptions und ServiceResult Pattern.
class WikiEntryService {
  final DatabaseHelper _databaseHelper;

  WikiEntryService({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ========== CRUD OPERATIONS ==========

  /// Holt alle Wiki-Einträge aus der Datenbank
  Future<ServiceResult<List<WikiEntry>>> getAllWikiEntries() async =>
      performServiceOperation('getAllWikiEntries', () async {
        final maps = await (await _databaseHelper.database).query('wiki_entries');
        return maps.map((map) => _WikiEntryWithSerializedData.fromMap(map).toWikiEntry()).toList();
      });

  /// Holt einen Wiki-Eintrag per ID
  Future<ServiceResult<WikiEntry?>> getWikiEntryById(String id) async =>
      performServiceOperation('getWikiEntryById', () async {
        final maps = await (await _databaseHelper.database).query(
          'wiki_entries',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        
        if (maps.isEmpty) return null;
        return _WikiEntryWithSerializedData.fromMap(maps.first).toWikiEntry();
      });

  /// Erstellt einen neuen Wiki-Eintrag
  Future<ServiceResult<WikiEntry>> createWikiEntry(WikiEntry entry) async {
    return performServiceOperation('createWikiEntry', () async {
      // Validierung
      if (entry.title.trim().isEmpty) {
        throw ValidationException(
          'Titel darf nicht leer sein',
          operation: 'createWikiEntry',
        );
      }

      if (entry.content.trim().isEmpty) {
        throw ValidationException(
          'Inhalt darf nicht leer sein',
          operation: 'createWikiEntry',
        );
      }

      await _databaseHelper.insertWikiEntry(entry);
      return entry;
    });
  }

  /// Aktualisiert einen Wiki-Eintrag
  Future<ServiceResult<WikiEntry>> updateWikiEntry(WikiEntry entry) async {
    return performServiceOperation('updateWikiEntry', () async {
      // Prüfe ob Eintrag existiert
      final existing = await getWikiEntryById(entry.id);
      if (!existing.isSuccess || existing.data == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          entry.id,
          operation: 'updateWikiEntry',
        );
      }

      // Validierung
      if (entry.title.trim().isEmpty) {
        throw ValidationException(
          'Titel darf nicht leer sein',
          operation: 'updateWikiEntry',
        );
      }

      if (entry.content.trim().isEmpty) {
        throw ValidationException(
          'Inhalt darf nicht leer sein',
          operation: 'updateWikiEntry',
        );
      }

      await _databaseHelper.updateWikiEntry(entry);
      return entry;
    });
  }

  /// Löscht einen Wiki-Eintrag
  Future<ServiceResult<void>> deleteWikiEntry(String id) async {
    return performServiceOperation('deleteWikiEntry', () async {
      final existing = await getWikiEntryById(id);
      if (!existing.isSuccess || existing.data == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          id,
          operation: 'deleteWikiEntry',
        );
      }
      
      await _databaseHelper.deleteWikiEntry(id);
    });
  }

  // ========== SEARCH & FILTER OPERATIONS ==========

  /// Sucht Wiki-Einträge nach Titel und Inhalt
  Future<ServiceResult<List<WikiEntry>>> searchWikiEntries(String query) async {
    return performServiceOperation('searchWikiEntries', () async {
      if (query.trim().isEmpty) {
        throw ValidationException(
          'Suchbegriff darf nicht leer sein',
          operation: 'searchWikiEntries',
        );
      }

      final allEntriesResult = await getAllWikiEntries();
      if (!allEntriesResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Wiki-Einträge',
          operation: 'searchWikiEntries',
        );
      }

      final queryLower = query.toLowerCase();
      return allEntriesResult.data!.where((entry) {
        return entry.title.toLowerCase().contains(queryLower) ||
               entry.content.toLowerCase().contains(queryLower) ||
               entry.tags.any((tag) => tag.toLowerCase().contains(queryLower));
      }).toList();
    });
  }

  /// Holt Wiki-Einträge für eine bestimmte Kampagne
  Future<ServiceResult<List<WikiEntry>>> getWikiEntriesByCampaign(String campaignId) async {
    return performServiceOperation('getWikiEntriesByCampaign', () async {
      final allEntriesResult = await getAllWikiEntries();
      if (!allEntriesResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Wiki-Einträge',
          operation: 'getWikiEntriesByCampaign',
        );
      }

      return allEntriesResult.data!
          .where((entry) => belongsToCampaign(entry, campaignId))
          .toList();
    });
  }

  /// Holt globale Wiki-Einträge (nicht kampagnenspezifisch)
  Future<ServiceResult<List<WikiEntry>>> getGlobalWikiEntries() async {
    return performServiceOperation('getGlobalWikiEntries', () async {
      final allEntriesResult = await getAllWikiEntries();
      if (!allEntriesResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Wiki-Einträge',
          operation: 'getGlobalWikiEntries',
        );
      }

      return allEntriesResult.data!
          .where((entry) => isGlobal(entry))
          .toList();
    });
  }

  /// Holt favorisierte Wiki-Einträge
  Future<ServiceResult<List<WikiEntry>>> getFavoriteWikiEntries() async {
    return performServiceOperation('getFavoriteWikiEntries', () async {
      final allEntriesResult = await getAllWikiEntries();
      if (!allEntriesResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Wiki-Einträge',
          operation: 'getFavoriteWikiEntries',
        );
      }

      return allEntriesResult.data!
          .where((entry) => entry.isFavorite)
          .toList();
    });
  }

  /// Holt Wiki-Einträge nach Typ
  Future<ServiceResult<List<WikiEntry>>> getWikiEntriesByType(WikiEntryType type) async {
    return performServiceOperation('getWikiEntriesByType', () async {
      final allEntriesResult = await getAllWikiEntries();
      if (!allEntriesResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Wiki-Einträge',
          operation: 'getWikiEntriesByType',
        );
      }

      return allEntriesResult.data!
          .where((entry) => entry.entryType == type)
          .toList();
    });
  }

  // ========== BUSINESS LOGIC OPERATIONS ==========

  /// Toggle Favoriten-Status für einen Wiki-Eintrag
  Future<ServiceResult<WikiEntry>> toggleFavorite(String id) async {
    return performServiceOperation('toggleFavorite', () async {
      final entryResult = await getWikiEntryById(id);
      if (!entryResult.isSuccess || entryResult.data == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          id,
          operation: 'toggleFavorite',
        );
      }

      final updatedEntry = toggleFavoriteStatic(entryResult.data!);
      final result = await updateWikiEntry(updatedEntry);
      if (!result.isSuccess) {
        throw DatabaseException(
          'Fehler beim Aktualisieren des Favoriten-Status',
          operation: 'toggleFavorite',
        );
      }
      return result.data!;
    });
  }

  /// Fügt einen Tag zu einem Wiki-Eintrag hinzu
  Future<ServiceResult<WikiEntry>> addTagToEntry(String entryId, String tag) async {
    return performServiceOperation('addTagToEntry', () async {
      final entryResult = await getWikiEntryById(entryId);
      if (!entryResult.isSuccess || entryResult.data == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          entryId,
          operation: 'addTagToEntry',
        );
      }

      final trimmedTag = tag.trim();
      if (trimmedTag.isEmpty) {
        throw ValidationException(
          'Tag darf nicht leer sein',
          operation: 'addTagToEntry',
        );
      }

      final updatedEntry = addTagStatic(entryResult.data!, trimmedTag);
      final result = await updateWikiEntry(updatedEntry);
      if (!result.isSuccess) {
        throw DatabaseException(
          'Fehler beim Hinzufügen des Tags',
          operation: 'addTagToEntry',
        );
      }
      return result.data!;
    });
  }

  /// Entfernt einen Tag von einem Wiki-Eintrag
  Future<ServiceResult<WikiEntry>> removeTagFromEntry(String entryId, String tag) async {
    return performServiceOperation('removeTagFromEntry', () async {
      final entryResult = await getWikiEntryById(entryId);
      if (!entryResult.isSuccess || entryResult.data == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          entryId,
          operation: 'removeTagFromEntry',
        );
      }

      final updatedEntry = removeTagStatic(entryResult.data!, tag);
      final result = await updateWikiEntry(updatedEntry);
      if (!result.isSuccess) {
        throw DatabaseException(
          'Fehler beim Entfernen des Tags',
          operation: 'removeTagFromEntry',
        );
      }
      return result.data!;
    });
  }

  /// Setzt das Parent für einen Wiki-Eintrag (hierarchische Struktur)
  Future<ServiceResult<WikiEntry>> setParentEntry(String entryId, String? parentId) async {
    return performServiceOperation('setParentEntry', () async {
      final entryResult = await getWikiEntryById(entryId);
      if (!entryResult.isSuccess || entryResult.data == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          entryId,
          operation: 'setParentEntry',
        );
      }

      // Prüfe auf Zyklen bei der hierarchischen Struktur
      if (parentId != null && await _wouldCreateCycle(entryId, parentId)) {
        throw BusinessException(
          'Hierarchischer Zyklus detected - Eintrag kann nicht sein eigener Parent werden',
          operation: 'setParentEntry',
        );
      }

      final updatedEntry = setParentStatic(entryResult.data!, parentId);
      final result = await updateWikiEntry(updatedEntry);
      if (!result.isSuccess) {
        throw DatabaseException(
          'Fehler beim Setzen des Parent',
          operation: 'setParentEntry',
        );
      }
      return result.data!;
    });
  }

  // ========== UTILITY OPERATIONS ==========

  /// Dupliziert einen Wiki-Eintrag
  Future<ServiceResult<WikiEntry>> duplicateWikiEntry(String entryId) async {
    return performServiceOperation('duplicateWikiEntry', () async {
      final originalEntryResult = await getWikiEntryById(entryId);
      if (!originalEntryResult.isSuccess || originalEntryResult.data == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          entryId,
          operation: 'duplicateWikiEntry',
        );
      }

      final originalEntry = originalEntryResult.data!;
      final duplicatedEntry = WikiEntry.create(
        title: '${originalEntry.title} (Kopie)',
        content: originalEntry.content,
        entryType: originalEntry.entryType,
        campaignId: originalEntry.campaignId,
        parentId: originalEntry.parentId,
        tags: List.from(originalEntry.tags),
        imageUrl: originalEntry.imageUrl,
        isMarkdown: originalEntry.isMarkdown,
        createdBy: originalEntry.createdBy,
      );

      final result = await createWikiEntry(duplicatedEntry);
      if (!result.isSuccess) {
        throw DatabaseException(
          'Fehler beim Duplizieren des Wiki-Eintrags',
          operation: 'duplicateWikiEntry',
        );
      }
      return result.data!;
    });
  }

  /// Holt die Anzahl der Wiki-Einträge für eine Kampagne
  Future<ServiceResult<int>> getWikiEntryCountForCampaign(String campaignId) async {
    return performServiceOperation('getWikiEntryCountForCampaign', () async {
      final entriesResult = await getWikiEntriesByCampaign(campaignId);
      if (!entriesResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden der Kampagnen-Wiki-Einträge',
          operation: 'getWikiEntryCountForCampaign',
        );
      }

      return entriesResult.data!.length;
    });
  }

  // ========== STATIC HELPER METHODS ==========

  /// Prüft ob dieser Eintrag zu einer bestimmten Kampagne gehört
  static bool belongsToCampaign(WikiEntry entry, String campaignId) =>
      entry.campaignId == campaignId;

  /// Prüft ob der Eintrag eine Location hat
  static bool hasLocation(WikiEntry entry) =>
      entry.location != null;

  /// Prüft ob der Eintrag Tags hat
  static bool hasTags(WikiEntry entry) =>
      entry.tags.isNotEmpty;

  /// Prüft ob der Eintrag ein Bild hat
  static bool hasImage(WikiEntry entry) =>
      entry.imageUrl != null && entry.imageUrl!.isNotEmpty;

  /// Prüft ob der Eintrag einen Ersteller hat
  static bool hasCreator(WikiEntry entry) =>
      entry.createdBy != null && entry.createdBy!.isNotEmpty;

  /// Prüft ob der Eintrag ein Parent hat (hierarchische Struktur)
  static bool hasParent(WikiEntry entry) =>
      entry.parentId != null && entry.parentId!.isNotEmpty;

  /// Prüft ob der Eintrag Children hat (hierarchische Struktur)
  static bool hasChildren(WikiEntry entry) =>
      entry.childIds.isNotEmpty;

  /// Prüft ob der Eintrag global ist (nicht kampagnenspezifisch)
  static bool isGlobal(WikiEntry entry) =>
      entry.campaignId == null;

  /// Fügt einen Tag hinzu (ohne Duplikate)
  static WikiEntry addTagStatic(WikiEntry entry, String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty || entry.tags.contains(trimmedTag)) return entry;
    
    return entry.copyWith(
      tags: [...entry.tags, trimmedTag],
      updatedAt: DateTime.now(),
    );
  }

  /// Entfernt einen Tag
  static WikiEntry removeTagStatic(WikiEntry entry, String tag) {
    final newTags = entry.tags.where((t) => t != tag).toList();
    if (newTags.length == entry.tags.length) return entry; // Tag nicht gefunden
    
    return entry.copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  /// Fügt ein Child hinzu (hierarchische Struktur)
  static WikiEntry addChildStatic(WikiEntry entry, String childId) {
    if (childId.isEmpty || entry.childIds.contains(childId)) return entry;
    
    return entry.copyWith(
      childIds: [...entry.childIds, childId],
      updatedAt: DateTime.now(),
    );
  }

  /// Entfernt ein Child (hierarchische Struktur)
  static WikiEntry removeChildStatic(WikiEntry entry, String childId) {
    final newChildIds = entry.childIds.where((id) => id != childId).toList();
    if (newChildIds.length == entry.childIds.length) return entry; // Child nicht gefunden
    
    return entry.copyWith(
      childIds: newChildIds,
      updatedAt: DateTime.now(),
    );
  }

  /// Setzt das Parent (hierarchische Struktur)
  static WikiEntry setParentStatic(WikiEntry entry, String? parentId) {
    if (entry.parentId == parentId) return entry; // Keine Änderung
    
    return entry.copyWith(
      parentId: parentId,
      updatedAt: DateTime.now(),
    );
  }

  /// Setzt die Bild-URL
  static WikiEntry setImageStatic(WikiEntry entry, String? imageUrl) {
    if (entry.imageUrl == imageUrl) return entry; // Keine Änderung
    
    return entry.copyWith(
      imageUrl: imageUrl,
      updatedAt: DateTime.now(),
    );
  }

  /// Setzt den Ersteller
  static WikiEntry setCreatorStatic(WikiEntry entry, String? createdBy) {
    if (entry.createdBy == createdBy) return entry; // Keine Änderung
    
    return entry.copyWith(
      createdBy: createdBy,
      updatedAt: DateTime.now(),
    );
  }

  /// Setzt den Markdown-Status
  static WikiEntry setMarkdownStatic(WikiEntry entry, bool isMarkdown) {
    if (entry.isMarkdown == isMarkdown) return entry; // Keine Änderung
    
    return entry.copyWith(
      isMarkdown: isMarkdown,
      updatedAt: DateTime.now(),
    );
  }

  /// Setzt den Favoriten-Status
  static WikiEntry setFavoriteStatic(WikiEntry entry, bool isFavorite) {
    if (entry.isFavorite == isFavorite) return entry; // Keine Änderung
    
    return entry.copyWith(
      isFavorite: isFavorite,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle Favoriten-Status
  static WikiEntry toggleFavoriteStatic(WikiEntry entry) =>
      setFavoriteStatic(entry, !entry.isFavorite);

  /// Serialisiert Tags für Datenbank
  static String serializeTags(List<String> tags) =>
      StringListParser.stringListToString(tags);

  /// Deserialisiert Tags aus Datenbank
  static List<String> deserializeTags(String? tagsString) =>
      StringListParser.parseStringList(tagsString);

  /// Serialisiert Child IDs für Datenbank
  static String serializeChildIds(List<String> childIds) =>
      StringListParser.stringListToString(childIds);

  /// Deserialisiert Child IDs aus Datenbank
  static List<String> deserializeChildIds(String? childIdsString) =>
      StringListParser.parseStringList(childIdsString);

  /// Formatiert Wiki Entry für Anzeige
  static String formatWikiEntry(WikiEntry entry) {
    final buffer = StringBuffer();
    buffer.writeln('WikiEntry: ${entry.title}');
    buffer.writeln('  Type: ${entry.entryType}');
    buffer.writeln('  Tags: ${entry.tags.join(', ')}');
    buffer.writeln('  Campaign: ${entry.campaignId ?? 'Global'}');
    buffer.writeln('  Created: ${entry.createdAt}');
    buffer.writeln('  Updated: ${entry.updatedAt}');
    buffer.writeln('  Is Favorite: ${entry.isFavorite}');
    
    if (hasLocation(entry)) {
      buffer.writeln('  Has Location: Yes');
    }
    
    if (hasImage(entry)) {
      buffer.writeln('  Has Image: Yes');
    }
    
    if (hasParent(entry)) {
      buffer.writeln('  Parent: ${entry.parentId}');
    }
    
    if (hasChildren(entry)) {
      buffer.writeln('  Children: ${entry.childIds.length}');
    }
    
    return buffer.toString();
  }

  // ========== PRIVATE HELPER METHODS ==========

  /// Prüft ob das Setzen eines Parent einen Zyklus erzeugen würde
  static Future<bool> _wouldCreateCycle(String entryId, String parentId) async {
    // Einfache Zyklus-Erkennung - könnte verbessert werden
    var currentId = parentId;
    var maxIterations = 100; // Schutz vor Endlosschleifen
    
    while (currentId != null && currentId.isNotEmpty && maxIterations > 0) {
      if (currentId == entryId) {
        return true; // Zyklus detected
      }
      
      final parentResult = await WikiEntryService().getWikiEntryById(currentId);
      if (!parentResult.isSuccess || parentResult.data == null) {
        break; // Parent nicht gefunden
      }
      
      currentId = parentResult.data!.parentId ?? '';
      maxIterations--;
    }
    
    return false;
  }
}

/// Helper-Klasse für die Serialisierung/Deserialisierung von WikiEntry Daten
class _WikiEntryWithSerializedData {
  final String id;
  final String title;
  final String content;
  final WikiEntryType entryType;
  final String? campaignId;
  final String? parentId;
  final String serializedTags;
  final String serializedChildIds;
  final String? imageUrl;
  final bool isMarkdown;
  final bool isFavorite;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const _WikiEntryWithSerializedData({
    required this.id,
    required this.title,
    required this.content,
    required this.entryType,
    this.campaignId,
    this.parentId,
    required this.serializedTags,
    required this.serializedChildIds,
    this.imageUrl,
    required this.isMarkdown,
    required this.isFavorite,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _WikiEntryWithSerializedData.fromMap(Map<String, dynamic> map) {
    return _WikiEntryWithSerializedData(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      entryType: WikiEntryType.values.firstWhere(
        (e) => e.name == map['entry_type'],
        orElse: () => WikiEntryType.Place,
      ),
      campaignId: map['campaign_id'] as String?,
      parentId: map['parent_id'] as String?,
      serializedTags: map['tags'] as String? ?? '',
      serializedChildIds: map['child_ids'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      isMarkdown: (map['is_markdown'] as int?) == 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory _WikiEntryWithSerializedData.fromWikiEntry(WikiEntry entry) {
    return _WikiEntryWithSerializedData(
      id: entry.id,
      title: entry.title,
      content: entry.content,
      entryType: entry.entryType,
      campaignId: entry.campaignId,
      parentId: entry.parentId,
      serializedTags: WikiEntryService.serializeTags(entry.tags),
      serializedChildIds: WikiEntryService.serializeChildIds(entry.childIds),
      imageUrl: entry.imageUrl,
      isMarkdown: entry.isMarkdown,
      isFavorite: entry.isFavorite,
      createdBy: entry.createdBy,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  WikiEntry toWikiEntry() {
    return WikiEntry(
      id: id,
      title: title,
      content: content,
      entryType: entryType,
      campaignId: campaignId,
      parentId: parentId,
      tags: WikiEntryService.deserializeTags(serializedTags),
      childIds: WikiEntryService.deserializeChildIds(serializedChildIds),
      imageUrl: imageUrl,
      isMarkdown: isMarkdown,
      isFavorite: isFavorite,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'entry_type': entryType.name,
      'campaign_id': campaignId,
      'parent_id': parentId,
      'tags': serializedTags,
      'child_ids': serializedChildIds,
      'image_url': imageUrl,
      'is_markdown': isMarkdown ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
