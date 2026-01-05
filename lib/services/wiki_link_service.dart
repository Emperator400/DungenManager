// lib/services/wiki_link_service.dart
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/wiki_link.dart';
import '../models/wiki_entry.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_link_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import 'exceptions/service_exceptions.dart';

/// Service für Wiki-Link-Management
/// Handhabt Beziehungen zwischen Wiki-Einträgen
/// 
/// Bietet CRUD-Operationen und Business-Logic für Wiki-Links.
/// Verwendet spezifische Exceptions und ServiceResult Pattern.
/// 
/// MIGRIERT: Verwendet WikiLinkModelRepository und WikiEntryModelRepository
class WikiLinkService {
  final WikiLinkModelRepository _wikiLinkRepository;
  final WikiEntryModelRepository _wikiRepository;
  static const _uuid = Uuid();

  WikiLinkService({
    WikiLinkModelRepository? wikiLinkRepository,
    WikiEntryModelRepository? wikiRepository,
  }) : _wikiLinkRepository = wikiLinkRepository ?? WikiLinkModelRepository(DatabaseConnection.instance),
       _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance);

  // ========== CRUD OPERATIONS ==========

  /// Erstellt einen neuen Wiki-Link
  Future<ServiceResult<String>> createLink({
    required String sourceEntryId,
    required String targetEntryId,
    required WikiLinkType linkType,
    String? createdBy,
  }) async {
    return performServiceOperation('createLink', () async {
      // Validierung
      if (sourceEntryId.isEmpty || targetEntryId.isEmpty) {
        throw ValidationException(
          'Source und Target Entry IDs dürfen nicht leer sein',
          operation: 'createLink',
        );
      }

      if (sourceEntryId == targetEntryId) {
        throw ValidationException(
          'Source und Target Entry dürfen nicht identisch sein',
          operation: 'createLink',
        );
      }

      // Prüfen ob beide Einträge existieren
      final sourceEntry = await _wikiRepository.findById(sourceEntryId);
      final targetEntry = await _wikiRepository.findById(targetEntryId);
      
      if (sourceEntry == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          sourceEntryId,
          operation: 'createLink',
        );
      }

      if (targetEntry == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          targetEntryId,
          operation: 'createLink',
        );
      }

      final linkId = _uuid.v4();
      final link = WikiLink(
        id: linkId,
        sourceEntryId: sourceEntryId,
        targetEntryId: targetEntryId,
        linkType: linkType,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await _wikiLinkRepository.create(link);
      
      return linkId;
    });
  }

  /// Löscht einen Wiki-Link
  Future<ServiceResult<void>> deleteLink(String linkId) async {
    return performServiceOperation('deleteLink', () async {
      final existingLink = await _wikiLinkRepository.findById(linkId);
      if (existingLink == null) {
        throw ResourceNotFoundException.forId(
          'WikiLink',
          linkId,
          operation: 'deleteLink',
        );
      }
      
      await _wikiLinkRepository.delete(linkId);
      return;
    });
  }

  /// Löscht alle Links für einen Wiki-Eintrag
  Future<ServiceResult<void>> deleteAllLinksForEntry(String entryId) async {
    return performServiceOperation('deleteAllLinksForEntry', () async {
      final entry = await _wikiRepository.findById(entryId);
      if (entry == null) {
        throw ResourceNotFoundException.forId(
          'WikiEntry',
          entryId,
          operation: 'deleteAllLinksForEntry',
        );
      }
      
      final links = await _wikiLinkRepository.findBySourceEntry(entryId);
      for (final link in links) {
        await _wikiLinkRepository.delete(link.id);
      }
      return;
    });
  }

  // ========== QUERY OPERATIONS ==========

  /// Holt alle Links für einen Wiki-Eintrag (ausgehende Links)
  Future<List<WikiLink>> getLinksForEntry(String entryId) async {
    return await _wikiLinkRepository.findBySourceEntry(entryId);
  }

  /// Holt alle Backlinks für einen Wiki-Eintrag (eingehende Links)
  Future<List<WikiLink>> getBacklinksForEntry(String entryId) async {
    return await _wikiLinkRepository.findByTargetEntry(entryId);
  }

  /// Holt alle verknüpften Einträge für einen Wiki-Eintrag
  Future<ServiceResult<List<WikiEntry>>> getLinkedEntries(String entryId) async {
    try {
      final links = await _wikiLinkRepository.findBySourceEntry(entryId);
      
      final linkedEntries = <WikiEntry>[];
      for (final link in links) {
        final entry = await _wikiRepository.findById(link.targetEntryId);
        if (entry != null) {
          linkedEntries.add(entry);
        }
      }
      
      return ServiceResult.success(
        linkedEntries,
        operation: 'getLinkedEntries',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'getLinkedEntries',
      );
    }
  }

  /// Prüft ob ein Link zwischen zwei Einträgen existiert
  Future<ServiceResult<bool>> linkExists({
    required String sourceEntryId,
    required String targetEntryId,
    WikiLinkType? linkType,
  }) async {
    try {
      final sourceLinks = await _wikiLinkRepository.findBySourceEntry(sourceEntryId);
      
      for (final link in sourceLinks) {
        if (link.targetEntryId == targetEntryId) {
          if (linkType == null || link.linkType == linkType) {
            return ServiceResult.success(
              true,
              operation: 'linkExists',
            );
          }
        }
      }
      
      return ServiceResult.success(
        false,
        operation: 'linkExists',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'linkExists',
      );
    }
  }

  /// Holt Links nach Typ
  Future<List<WikiLink>> getLinksByType(WikiLinkType linkType) async {
    return await _wikiLinkRepository.findByType(linkType);
  }

  /// Holt alle Links eines bestimmten Benutzers
  Future<ServiceResult<List<WikiLink>>> getLinksByUser(String userId) async {
    try {
      // TODO: Implementiere userId-Filter im WikiLinkModelRepository
      final allLinks = await _wikiLinkRepository.findAll();
      
      final userLinks = allLinks.where((link) => 
          link.createdBy == userId).toList();
      
      return ServiceResult.success(
        userLinks,
        operation: 'getLinksByUser',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'getLinksByUser',
      );
    }
  }

  /// Sucht nach Links basierend auf Entry-Titeln
  Future<ServiceResult<List<WikiLink>>> searchLinks(String query) async {
    try {
      if (query.trim().isEmpty) {
        return ServiceResult.validationError(
          ValidationException(
            'Suchbegriff darf nicht leer sein',
            operation: 'searchLinks',
          ),
          operation: 'searchLinks',
        );
      }

      // Suche nach Einträgen und hole deren Links
      final entries = await _wikiRepository.search(query, fields: ['title']);
      
      final matchingLinks = <WikiLink>[];
      for (final entry in entries) {
        final outgoingLinks = await _wikiLinkRepository.findBySourceEntry(entry.id);
        matchingLinks.addAll(outgoingLinks);
        
        final incomingLinks = await _wikiLinkRepository.findByTargetEntry(entry.id);
        matchingLinks.addAll(incomingLinks);
      }
      
      return ServiceResult.success(
        matchingLinks,
        operation: 'searchLinks',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'searchLinks',
      );
    }
  }

  /// Holt Link-Statistiken
  Future<ServiceResult<Map<String, dynamic>>> getLinkStatistics() async {
    try {
      final totalLinks = await _wikiLinkRepository.count();
      
      // Verteilung nach Typ
      final typeDistribution = <String, int>{};
      for (final type in WikiLinkType.values) {
        final links = await _wikiLinkRepository.findByType(type);
        typeDistribution[type.name] = links.length;
      }
      
      return ServiceResult.success(
        {
          'totalLinks': totalLinks,
          'typeDistribution': typeDistribution,
          'timestamp': DateTime.now().toIso8601String(),
        },
        operation: 'getLinkStatistics',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'getLinkStatistics',
      );
    }
  }

  // ========== BUSINESS LOGIC OPERATIONS ==========

  /// Aktualisiert einen Wiki-Link
  Future<ServiceResult<WikiLink>> updateLink(String linkId, {
    WikiLinkType? linkType,
  }) async {
    try {
      final existing = await _wikiLinkRepository.findById(linkId);
      if (existing == null) {
        return ServiceResult.notFound(
          ResourceNotFoundException.forId(
            'WikiLink',
            linkId,
            operation: 'updateLink',
          ),
          operation: 'updateLink',
        );
      }

      if (linkType == null) {
        return ServiceResult.validationError(
          ValidationException(
            'LinkType darf nicht null sein',
            operation: 'updateLink',
          ),
          operation: 'updateLink',
        );
      }

      final updatedLink = WikiLink(
        id: existing.id,
        sourceEntryId: existing.sourceEntryId,
        targetEntryId: existing.targetEntryId,
        linkType: linkType,
        createdAt: existing.createdAt,
        createdBy: existing.createdBy,
      );

      await _wikiLinkRepository.update(updatedLink);
      return ServiceResult.success(
        updatedLink,
        operation: 'updateLink',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'updateLink',
      );
    }
  }

  /// Bereinigt ungültige Links (verweist auf nicht existierende Einträge)
  Future<ServiceResult<int>> cleanupInvalidLinks() async {
    try {
      final allLinks = await _wikiLinkRepository.findAll();
      
      int cleanedCount = 0;
      for (final link in allLinks) {
        // Prüfe Source Entry
        final sourceEntry = await _wikiRepository.findById(link.sourceEntryId);
        if (sourceEntry == null) {
          await _wikiLinkRepository.delete(link.id);
          cleanedCount++;
          continue;
        }
        
        // Prüfe Target Entry
        final targetEntry = await _wikiRepository.findById(link.targetEntryId);
        if (targetEntry == null) {
          await _wikiLinkRepository.delete(link.id);
          cleanedCount++;
        }
      }
      
      return ServiceResult.success(
        cleanedCount,
        operation: 'cleanupInvalidLinks',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'cleanupInvalidLinks',
      );
    }
  }

  /// Dupliziert Links für einen kopierten Eintrag
  Future<ServiceResult<void>> duplicateLinksForEntry({
    required String originalEntryId,
    required String newEntryId,
    String? createdBy,
  }) async {
    try {
      final originalEntry = await _wikiRepository.findById(originalEntryId);
      if (originalEntry == null) {
        return ServiceResult.notFound(
          ResourceNotFoundException.forId(
            'WikiEntry',
            originalEntryId,
            operation: 'duplicateLinksForEntry',
          ),
          operation: 'duplicateLinksForEntry',
        );
      }

      final newEntry = await _wikiRepository.findById(newEntryId);
      if (newEntry == null) {
        return ServiceResult.notFound(
          ResourceNotFoundException.forId(
            'WikiEntry',
            newEntryId,
            operation: 'duplicateLinksForEntry',
          ),
          operation: 'duplicateLinksForEntry',
        );
      }

      final originalLinks = await _wikiLinkRepository.findBySourceEntry(originalEntryId);
      
      for (final originalLink in originalLinks) {
        final newLink = WikiLink(
          id: _uuid.v4(),
          sourceEntryId: newEntryId,
          targetEntryId: originalLink.targetEntryId,
          linkType: originalLink.linkType,
          createdAt: DateTime.now(),
          createdBy: createdBy,
        );

        await _wikiLinkRepository.create(newLink);
      }
      
      return ServiceResult.success(
        null,
        operation: 'duplicateLinksForEntry',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'duplicateLinksForEntry',
      );
    }
  }

  /// Importiert Links aus einer Liste
  Future<ServiceResult<WikiLinkImportResult>> importLinks(List<Map<String, dynamic>> linkData) async {
    try {
      if (linkData.isEmpty) {
        return ServiceResult.validationError(
          ValidationException(
            'Link-Daten dürfen nicht leer sein',
            operation: 'importLinks',
          ),
          operation: 'importLinks',
        );
      }

      final wikiLinks = linkData.map((data) => WikiLink.fromMap(data)).toList();
      final importedIds = <String>[];
      final errors = <String>[];
      
      for (final link in wikiLinks) {
        try {
          // Prüfe ob Einträge existieren
          final sourceEntry = await _wikiRepository.findById(link.sourceEntryId);
          final targetEntry = await _wikiRepository.findById(link.targetEntryId);
          
          if (sourceEntry == null || targetEntry == null) {
            errors.add('Einträge nicht gefunden für Link: ${link.id}');
            continue;
          }
          
          await _wikiLinkRepository.create(link);
          importedIds.add(link.id);
        } catch (e) {
          errors.add('Fehler beim Import von Link ${link.id}: $e');
        }
      }
      
      return ServiceResult.success(
        WikiLinkImportResult(
          success: errors.isEmpty,
          importedCount: importedIds.length,
          skippedCount: linkData.length - importedIds.length,
          errors: errors,
        ),
        operation: 'importLinks',
        affectedCount: importedIds.length,
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'importLinks',
      );
    }
  }

  // ========== DETAILED QUERY OPERATIONS ==========

  /// Holt eingehende Links mit Details
  Future<ServiceResult<List<Map<String, dynamic>>>> getBacklinksWithDetails(String entryId) async {
    try {
      final entry = await _wikiRepository.findById(entryId);
      if (entry == null) {
        return ServiceResult.notFound(
          ResourceNotFoundException.forId(
            'WikiEntry',
            entryId,
            operation: 'getBacklinksWithDetails',
          ),
          operation: 'getBacklinksWithDetails',
        );
      }
      
      final links = await _wikiLinkRepository.findByTargetEntry(entryId);
      
      final details = <Map<String, dynamic>>[];
      for (final link in links) {
        final sourceEntry = await _wikiRepository.findById(link.sourceEntryId);
        if (sourceEntry != null) {
          details.add({
            'link': link.toMap(),
            'sourceEntry': sourceEntry.toMap(),
          });
        }
      }
      
      return ServiceResult.success(
        details,
        operation: 'getBacklinksWithDetails',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'getBacklinksWithDetails',
      );
    }
  }

  /// Holt ausgehende Links mit Details
  Future<ServiceResult<List<Map<String, dynamic>>>> getLinkedEntriesWithDetails(String entryId) async {
    try {
      final entry = await _wikiRepository.findById(entryId);
      if (entry == null) {
        return ServiceResult.notFound(
          ResourceNotFoundException.forId(
            'WikiEntry',
            entryId,
            operation: 'getLinkedEntriesWithDetails',
          ),
          operation: 'getLinkedEntriesWithDetails',
        );
      }
      
      final links = await _wikiLinkRepository.findBySourceEntry(entryId);
      
      final details = <Map<String, dynamic>>[];
      for (final link in links) {
        final targetEntry = await _wikiRepository.findById(link.targetEntryId);
        if (targetEntry != null) {
          details.add({
            'link': link.toMap(),
            'targetEntry': targetEntry.toMap(),
          });
        }
      }
      
      return ServiceResult.success(
        details,
        operation: 'getLinkedEntriesWithDetails',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'getLinkedEntriesWithDetails',
      );
    }
  }

  /// Baut Wiki-Hierarchie auf
  Future<ServiceResult<List<Map<String, dynamic>>>> buildHierarchy(String rootEntryId) async {
    try {
      final entry = await _wikiRepository.findById(rootEntryId);
      if (entry == null) {
        return ServiceResult.notFound(
          ResourceNotFoundException.forId(
            'WikiEntry',
            rootEntryId,
            operation: 'buildHierarchy',
          ),
          operation: 'buildHierarchy',
        );
      }
      
      final hierarchy = <Map<String, dynamic>>[];
      await _buildHierarchyRecursive(rootEntryId, hierarchy, 0, 3); // Max 3 Level tief
      
      return ServiceResult.success(
        hierarchy,
        operation: 'buildHierarchy',
      );
    } catch (e) {
      return ServiceResult.unexpectedError(
        e,
        operation: 'buildHierarchy',
      );
    }
  }

  Future<void> _buildHierarchyRecursive(
    String entryId,
    List<Map<String, dynamic>> hierarchy,
    int level,
    int maxLevel,
  ) async {
    if (level >= maxLevel) return;
    
    final entry = await _wikiRepository.findById(entryId);
    if (entry == null) return;
    
    final links = await _wikiLinkRepository.findBySourceEntry(entryId);
    
    hierarchy.add({
      'entry': entry.toMap(),
      'level': level,
      'linksCount': links.length,
    });
    
    for (final link in links) {
      await _buildHierarchyRecursive(link.targetEntryId, hierarchy, level + 1, maxLevel);
    }
  }

  // ========== CONVENIENCE METHODS ==========

  /// Manuellen Link erstellen (Alias für createLink)
  Future<ServiceResult<String>> createManualLink({
    required String sourceEntryId,
    required String targetEntryId,
    required WikiLinkType linkType,
    String? createdBy,
  }) async {
    return await createLink(
      sourceEntryId: sourceEntryId,
      targetEntryId: targetEntryId,
      linkType: linkType,
      createdBy: createdBy,
    );
  }

  /// Holt ausgehende Links (Alias für getLinksForEntry)
  Future<List<WikiLink>> getOutgoingLinks(String entryId) async {
    return await getLinksForEntry(entryId);
  }

  // ========== STATIC HELPER METHODS ==========

  /// Konvertiert WikiLinkType zu String
  static String linkTypeToString(WikiLinkType linkType) => linkType.name;

  /// Konvertiert String zu WikiLinkType
  static WikiLinkType stringToLinkType(String linkTypeString) {
    return WikiLinkType.values.firstWhere(
      (type) => type.name == linkTypeString,
      orElse: () => WikiLinkType.reference,
    );
  }

  /// Formatiert WikiLink für Anzeige
  static String formatWikiLink(WikiLink link) {
    final buffer = StringBuffer();
    buffer.writeln('WikiLink: ${link.id}');
    buffer.writeln('  Source: ${link.sourceEntryId}');
    buffer.writeln('  Target: ${link.targetEntryId}');
    buffer.writeln('  Type: ${link.linkType}');
    buffer.writeln('  Created: ${link.createdAt}');
    
    if (link.createdBy != null) {
      buffer.writeln('  Created By: ${link.createdBy}');
    }
    
    return buffer.toString();
  }

  /// Prüft ob ein Link-Valid ist
  static bool isValidLink(WikiLink link) {
    return link.sourceEntryId.isNotEmpty &&
           link.targetEntryId.isNotEmpty &&
           link.sourceEntryId != link.targetEntryId &&
           link.id.isNotEmpty;
  }
}

/// Ergebnis des Link-Import-Vorgangs
class WikiLinkImportResult {
  final bool success;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;

  WikiLinkImportResult({
    required this.success,
    required this.importedCount,
    required this.skippedCount,
    this.errors = const [],
  });
}
