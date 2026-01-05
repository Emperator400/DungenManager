// lib/services/wiki_entry_service.dart
import 'dart:async';

// Dart Core
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../models/wiki_entry.dart';
import 'exceptions/service_exceptions.dart';

/// Service für die Verwaltung von Wiki Entries
/// 
/// Bietet CRUD-Operationen und Business-Logic für Wiki-Einträge.
/// Verwendet ModelRepository-Architektur und spezifische Exceptions.
class WikiEntryService {
  final WikiEntryModelRepository _wikiRepository;

  WikiEntryService({
    WikiEntryModelRepository? wikiRepository,
  }) : _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance);

  // ========== CRUD OPERATIONS ==========

  /// Holt alle Wiki-Einträge aus der Datenbank
  Future<ServiceResult<List<WikiEntry>>> getAllWikiEntries() async =>
      performServiceOperation('getAllWikiEntries', () async {
        return await _wikiRepository.findAll();
      });

  /// Holt einen Wiki-Eintrag per ID
  Future<ServiceResult<WikiEntry?>> getWikiEntryById(String id) async =>
      performServiceOperation('getWikiEntryById', () async {
        return await _wikiRepository.findById(id);
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

      return await _wikiRepository.create(entry);
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

      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
      return await _wikiRepository.update(updatedEntry);
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
      
      return await _wikiRepository.delete(id);
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
      return await _wikiRepository.update(updatedEntry);
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
      return await _wikiRepository.update(updatedEntry);
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
      return await _wikiRepository.update(updatedEntry);
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
      return await _wikiRepository.update(updatedEntry);
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

      return await _wikiRepository.create(duplicatedEntry);
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
      tags.join(',');

  /// Deserialisiert Tags aus Datenbank
  static List<String> deserializeTags(String? tagsString) {
    if (tagsString == null || tagsString.isEmpty) return [];
    return tagsString.split(',').where((tag) => tag.trim().isNotEmpty).toList();
  }

  /// Serialisiert Child IDs für Datenbank
  static String serializeChildIds(List<String> childIds) =>
      childIds.join(',');

  /// Deserialisiert Child IDs aus Datenbank
  static List<String> deserializeChildIds(String? childIdsString) {
    if (childIdsString == null || childIdsString.isEmpty) return [];
    return childIdsString.split(',').where((id) => id.trim().isNotEmpty).toList();
  }

  /// Formatiiert Wiki Entry für Anzeige
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
    
    final service = WikiEntryService();
    
    while (currentId != null && currentId.isNotEmpty && maxIterations > 0) {
      if (currentId == entryId) {
        return true; // Zyklus detected
      }
      
      final parentResult = await service.getWikiEntryById(currentId);
      if (!parentResult.isSuccess || parentResult.data == null) {
        break; // Parent nicht gefunden
      }
      
      currentId = parentResult.data!.parentId ?? '';
      maxIterations--;
    }
    
    return false;
  }
}
