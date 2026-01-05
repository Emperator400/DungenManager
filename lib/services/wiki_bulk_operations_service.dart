// lib/services/wiki_bulk_operations_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wiki_entry.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/repositories/wiki_link_model_repository.dart';
import 'exceptions/service_exceptions.dart';

/// Service für Massenoperationen auf Wiki-Einträge mit Repository-Architektur
/// 
/// Unterstützt mehrere Einträge gleichzeitig zu bearbeiten.
/// Verwendet Repository-Architektur und spezifische Exceptions.
class WikiBulkOperationsService {
  final WikiEntryModelRepository _wikiRepository;
  final WikiLinkModelRepository _wikiLinkRepository;

  WikiBulkOperationsService({
    WikiEntryModelRepository? wikiRepository,
    WikiLinkModelRepository? wikiLinkRepository,
  })  : _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance),
        _wikiLinkRepository = wikiLinkRepository ?? WikiLinkModelRepository(DatabaseConnection.instance);

  /// Togglet Favoriten-Status für mehrere Einträge
  Future<ServiceResult<BulkOperationResult>> toggleFavorites(
    List<String> entryIds, {
    required bool isFavorite,
  }) async {
    return performServiceOperation('toggleFavorites', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge für Favoriten-Änderung angegeben',
          operation: 'toggleFavorites',
        );
      }

      int updatedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final updatedEntry = entry.copyWith(isFavorite: isFavorite);
            await _wikiRepository.update(updatedEntry);
            updatedCount++;
          }
        } catch (e) {
          // Einzelne Fehler sammeln, aber mit anderen fortfahren
          debugPrint('Fehler bei Favoriten-Update für $entryId: $e');
        }
      }
      
      return BulkOperationResult(
        success: updatedCount > 0,
        message: '$updatedCount von ${entryIds.length} Einträgen als ${isFavorite ? 'Favorit' : 'nicht mehr Favorit'} markiert',
        affectedCount: updatedCount,
      );
    });
  }

  /// Fügt Tags zu mehreren Einträgen hinzu
  Future<ServiceResult<BulkOperationResult>> addTagsToEntries(
    List<String> entryIds,
    List<String> tags,
  ) async {
    return performServiceOperation('addTagsToEntries', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge für Tag-Addierung angegeben',
          operation: 'addTagsToEntries',
        );
      }

      if (tags.isEmpty) {
        throw ValidationException(
          'Keine Tags zum Hinzufügen angegeben',
          operation: 'addTagsToEntries',
        );
      }

      int updatedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            // Bereinige und kombiniere Tags
            final existingTags = entry.tags
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toSet();
            
            final newTags = tags
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty && !existingTags.contains(tag))
                .toList();
            
            if (newTags.isNotEmpty) {
              final combinedTags = [...existingTags, ...newTags].toList();
              final updatedEntry = entry.copyWith(tags: combinedTags);
              await _wikiRepository.update(updatedEntry);
              updatedCount++;
            }
          }
        } catch (e) {
          debugPrint('Fehler bei Tag-Addierung für $entryId: $e');
        }
      }
      
      return BulkOperationResult(
        success: updatedCount > 0,
        message: 'Tags zu $updatedCount Einträgen hinzugefügt',
        affectedCount: updatedCount,
      );
    });
  }

  /// Entfernt Tags von mehreren Einträgen
  Future<ServiceResult<BulkOperationResult>> removeTagsFromEntries(
    List<String> entryIds,
    List<String> tags,
  ) async {
    return performServiceOperation('removeTagsFromEntries', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge für Tag-Entfernung angegeben',
          operation: 'removeTagsFromEntries',
        );
      }

      if (tags.isEmpty) {
        throw ValidationException(
          'Keine Tags zum Entfernen angegeben',
          operation: 'removeTagsFromEntries',
        );
      }

      int updatedCount = 0;
      final tagsToRemove = tags.map((tag) => tag.trim()).toSet();
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final filteredTags = entry.tags
                .where((tag) => !tagsToRemove.contains(tag.trim()))
                .toList();
            
            // Nur updaten wenn sich etwas geändert hat
            if (filteredTags.length != entry.tags.length) {
              final updatedEntry = entry.copyWith(tags: filteredTags);
              await _wikiRepository.update(updatedEntry);
              updatedCount++;
            }
          }
        } catch (e) {
          debugPrint('Fehler bei Tag-Entfernung für $entryId: $e');
        }
      }
      
      return BulkOperationResult(
        success: updatedCount > 0,
        message: 'Tags von $updatedCount Einträgen entfernt',
        affectedCount: updatedCount,
      );
    });
  }

  /// Ändert den Typ für mehrere Einträge
  Future<ServiceResult<BulkOperationResult>> changeEntryType(
    List<String> entryIds,
    WikiEntryType newType,
  ) async {
    return performServiceOperation('changeEntryType', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge für Typ-Änderung angegeben',
          operation: 'changeEntryType',
        );
      }

      int updatedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final updatedEntry = entry.copyWith(entryType: newType);
            await _wikiRepository.update(updatedEntry);
            updatedCount++;
          }
        } catch (e) {
          debugPrint('Fehler bei Typ-Änderung für $entryId: $e');
        }
      }
      
      return BulkOperationResult(
        success: updatedCount > 0,
        message: 'Typ von $updatedCount Einträgen zu $newType geändert',
        affectedCount: updatedCount,
      );
    });
  }

  /// Weist mehrere Einträge einer Kampagne zu
  Future<ServiceResult<BulkOperationResult>> assignToCampaign(
    List<String> entryIds,
    String? campaignId,
  ) async {
    return performServiceOperation('assignToCampaign', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge für Kampagnen-Zuweisung angegeben',
          operation: 'assignToCampaign',
        );
      }

      int updatedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final updatedEntry = entry.copyWith(campaignId: campaignId);
            await _wikiRepository.update(updatedEntry);
            updatedCount++;
          }
        } catch (e) {
          debugPrint('Fehler bei Kampagnen-Zuweisung für $entryId: $e');
        }
      }
      
      final action = campaignId != null ? 'zugewiesen' : 'entfernt';
      return BulkOperationResult(
        success: updatedCount > 0,
        message: '$updatedCount Einträge der Kampagne $action',
        affectedCount: updatedCount,
      );
    });
  }

  /// Setzt den Ersteller für mehrere Einträge
  Future<ServiceResult<BulkOperationResult>> setCreator(
    List<String> entryIds,
    String? creator,
  ) async {
    return performServiceOperation('setCreator', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge für Ersteller-Setzung angegeben',
          operation: 'setCreator',
        );
      }

      int updatedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final updatedEntry = entry.copyWith(createdBy: creator);
            await _wikiRepository.update(updatedEntry);
            updatedCount++;
          }
        } catch (e) {
          debugPrint('Fehler bei Ersteller-Setzung für $entryId: $e');
        }
      }
      
      final action = creator != null ? 'gesetzt' : 'entfernt';
      return BulkOperationResult(
        success: updatedCount > 0,
        message: 'Ersteller für $updatedCount Einträge $action',
        affectedCount: updatedCount,
      );
    });
  }

  /// Löscht mehrere Einträge
  Future<ServiceResult<BulkOperationResult>> deleteEntries(
    List<String> entryIds, {
    required bool confirmDeletion,
  }) async {
    return performServiceOperation('deleteEntries', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge zum Löschen angegeben',
          operation: 'deleteEntries',
        );
      }

      if (!confirmDeletion) {
        throw ValidationException(
          'Löschen nicht bestätigt',
          operation: 'deleteEntries',
        );
      }

      int deletedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          // Zuerst alle Wiki-Links löschen
          await _wikiLinkRepository.deleteAll([entryId]);
          
          // Dann den Eintrag löschen
          await _wikiRepository.delete(entryId);
          deletedCount++;
        } catch (e) {
          debugPrint('Fehler beim Löschen von $entryId: $e');
        }
      }
      
      return BulkOperationResult(
        success: deletedCount > 0,
        message: '$deletedCount Einträge gelöscht',
        affectedCount: deletedCount,
      );
    });
  }

  /// Dupliziert mehrere Einträge
  Future<ServiceResult<BulkOperationResult>> duplicateEntries(
    List<String> entryIds,
  ) async {
    return performServiceOperation('duplicateEntries', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge zum Duplizieren angeben',
          operation: 'duplicateEntries',
        );
      }

      int duplicatedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final duplicate = entry.copyWith(
              id: '', // Neue ID wird generiert
              title: '${entry.title} (Kopie)',
              isFavorite: false, // Kopien sind nicht favorisiert
              createdAt: DateTime.now(), // Neue Erstellungszeit
              updatedAt: DateTime.now(), // Neue Updatezeit
            );
            
            await _wikiRepository.create(duplicate);
            duplicatedCount++;
          }
        } catch (e) {
          debugPrint('Fehler beim Duplizieren von $entryId: $e');
        }
      }
      
      return BulkOperationResult(
        success: duplicatedCount > 0,
        message: '$duplicatedCount Einträge dupliziert',
        affectedCount: duplicatedCount,
      );
    });
  }

  /// Setzt Markdown-Status für mehrere Einträge
  Future<ServiceResult<BulkOperationResult>> setMarkdownStatus(
    List<String> entryIds, {
    required bool isMarkdown,
  }) async {
    return performServiceOperation('setMarkdownStatus', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge für Markdown-Status-Änderung angeben',
          operation: 'setMarkdownStatus',
        );
      }

      int updatedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final updatedEntry = entry.copyWith(isMarkdown: isMarkdown);
            await _wikiRepository.update(updatedEntry);
            updatedCount++;
          }
        } catch (e) {
          debugPrint('Fehler bei Markdown-Status-Änderung für $entryId: $e');
        }
      }
      
      return BulkOperationResult(
        success: updatedCount > 0,
        message: 'Markdown-Status für $updatedCount Einträgen ${isMarkdown ? 'aktiviert' : 'deaktiviert'}',
        affectedCount: updatedCount,
      );
    });
  }

  /// Holt alle Tags aus den angegebenen Einträgen
  Future<ServiceResult<Set<String>>> getAllTagsFromEntries(List<String> entryIds) async {
    return performServiceOperation('getAllTagsFromEntries', () async {
      if (entryIds.isEmpty) {
        return <String>{}.toSet();
      }

      final allTags = <String>{};
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final tags = entry.tags
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty);
            allTags.addAll(tags);
          }
        } catch (e) {
          debugPrint('Fehler beim Abrufen der Tags für $entryId: $e');
        }
      }
      
      return allTags;
    });
  }

  /// Zählt Einträge nach Typ
  Future<ServiceResult<Map<WikiEntryType, int>>> countEntriesByType(
    List<String> entryIds,
  ) async {
    return performServiceOperation('countEntriesByType', () async {
      if (entryIds.isEmpty) {
        return <WikiEntryType, int>{};
      }

      final counts = <WikiEntryType, int>{};
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            counts[entry.entryType] = (counts[entry.entryType] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint('Fehler beim Zählen des Typs für $entryId: $e');
        }
      }
      
      return counts;
    });
  }

  /// Führt eine komplexe Massenoperation durch
  Future<ServiceResult<BulkOperationResult>> performBulkOperation(
    List<String> entryIds,
    BulkOperation operation,
  ) async {
    return performServiceOperation('performBulkOperation', () async {
      if (entryIds.isEmpty) {
        throw ValidationException(
          'Keine Einträge für Massenoperation angeben',
          operation: 'performBulkOperation',
        );
      }

      int updatedCount = 0;
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            final updatedEntry = operation.apply(entry);
            await _wikiRepository.update(updatedEntry);
            updatedCount++;
          }
        } catch (e) {
          debugPrint('Fehler bei Massenoperation für $entryId: $e');
        }
      }
      
      return BulkOperationResult(
        success: updatedCount > 0,
        message: '${operation.description} für $updatedCount Einträge durchgeführt',
        affectedCount: updatedCount,
      );
    });
  }

  /// Validiert eine Liste von Eintrags-IDs
  Future<ServiceResult<List<String>>> validateEntryIds(List<String> entryIds) async {
    return performServiceOperation('validateEntryIds', () async {
      if (entryIds.isEmpty) {
        return <String>[];
      }

      final validIds = <String>[];
      
      for (final entryId in entryIds) {
        try {
          final entry = await _wikiRepository.findById(entryId);
          if (entry != null) {
            validIds.add(entryId);
          }
        } catch (e) {
          debugPrint('Ungültige Eintrags-ID: $entryId');
        }
      }
      
      return validIds;
    });
  }

  // ========== STATISCHE HELPER METHODEN ==========

  /// Formatiert Bulk-Operation Ergebnis für Anzeige
  static String formatBulkResult(BulkOperationResult result) {
    final buffer = StringBuffer();
    buffer.writeln('BulkOperationResult:');
    buffer.writeln('  Erfolg: ${result.success}');
    buffer.writeln('  Nachricht: ${result.message}');
    buffer.writeln('  Betroffene Einträge: ${result.affectedCount}');
    
    if (result.requiresConfirmation) {
      buffer.writeln('  Bestätigung erforderlich: Ja');
    }
    
    return buffer.toString();
  }

  /// Prüft ob eine Massenoperation sicher ist
  static bool isOperationSafe(BulkOperation operation) {
    return switch (operation.type) {
      BulkOperationType.toggleFavorites => true,
      BulkOperationType.addTags => true,
      BulkOperationType.removeTags => true,
      BulkOperationType.changeType => false, // Kann Auswirkungen haben
      BulkOperationType.assignCampaign => false, // Kann Auswirkungen haben
      BulkOperationType.setCreator => false, // Kann Auswirkungen haben
      BulkOperationType.delete => false, // Destruktiv
      BulkOperationType.duplicate => true,
      BulkOperationType.setMarkdownStatus => true,
    };
  }
}

/// Ergebnis einer Massenoperation
class BulkOperationResult {
  final bool success;
  final String message;
  final int affectedCount;
  final bool requiresConfirmation;

  BulkOperationResult({
    required this.success,
    required this.message,
    this.affectedCount = 0,
    this.requiresConfirmation = false,
  });

  @override
  String toString() {
    return 'BulkOperationResult(success: $success, message: $message, affectedCount: $affectedCount)';
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'affectedCount': affectedCount,
      'requiresConfirmation': requiresConfirmation,
    };
  }

  factory BulkOperationResult.fromMap(Map<String, dynamic> map) {
    return BulkOperationResult(
      success: map['success'] as bool,
      message: map['message'] as String,
      affectedCount: map['affectedCount'] as int? ?? 0,
      requiresConfirmation: map['requiresConfirmation'] as bool? ?? false,
    );
  }
}

/// Definition einer Massenoperation
class BulkOperation {
  final BulkOperationType type;
  final dynamic value;
  final String description;

  BulkOperation({
    required this.type,
    required this.value,
    required this.description,
  });

  /// Wendet die Operation auf einen Eintrag an
  WikiEntry apply(WikiEntry entry) {
    return switch (type) {
      BulkOperationType.toggleFavorites => entry.copyWith(isFavorite: value as bool),
      BulkOperationType.addTags => _addTagsToEntry(entry, value as List<String>),
      BulkOperationType.removeTags => _removeTagsFromEntry(entry, value as List<String>),
      BulkOperationType.changeType => entry.copyWith(entryType: value as WikiEntryType),
      BulkOperationType.assignCampaign => entry.copyWith(campaignId: value as String?),
      BulkOperationType.setCreator => entry.copyWith(createdBy: value as String?),
      BulkOperationType.delete => throw UnsupportedError('Delete-Operation kann nicht auf Eintrag angewendet werden'),
      BulkOperationType.duplicate => throw UnsupportedError('Duplicate-Operation kann nicht auf Eintrag angewendet werden'),
      BulkOperationType.setMarkdownStatus => entry.copyWith(isMarkdown: value as bool),
    };
  }

  WikiEntry _addTagsToEntry(WikiEntry entry, List<String> tags) {
    final existingTags = entry.tags.toSet();
    final newTags = tags.where((tag) => !existingTags.contains(tag));
    final combinedTags = [...existingTags, ...newTags].toList();
    return entry.copyWith(tags: combinedTags);
  }

  WikiEntry _removeTagsFromEntry(WikiEntry entry, List<String> tags) {
    final tagsToRemove = tags.toSet();
    final filteredTags = entry.tags.where((tag) => !tagsToRemove.contains(tag)).toList();
    return entry.copyWith(tags: filteredTags);
  }

  /// Factory-Methoden für gängige Operationen
  static BulkOperation toggleFavorites(bool isFavorite) => BulkOperation(
    type: BulkOperationType.toggleFavorites,
    value: isFavorite,
    description: 'Favoriten-Status umschalten',
  );

  static BulkOperation addTags(List<String> tags) => BulkOperation(
    type: BulkOperationType.addTags,
    value: tags,
    description: 'Tags hinzufügen',
  );

  static BulkOperation removeTags(List<String> tags) => BulkOperation(
    type: BulkOperationType.removeTags,
    value: tags,
    description: 'Tags entfernen',
  );

  static BulkOperation changeType(WikiEntryType type) => BulkOperation(
    type: BulkOperationType.changeType,
    value: type,
    description: 'Eintragstyp ändern',
  );

  static BulkOperation assignCampaign(String? campaignId) => BulkOperation(
    type: BulkOperationType.assignCampaign,
    value: campaignId,
    description: 'Kampagne zuweisen',
  );

  static BulkOperation setCreator(String? creator) => BulkOperation(
    type: BulkOperationType.setCreator,
    value: creator,
    description: 'Ersteller setzen',
  );

  static BulkOperation setMarkdownStatus(bool isMarkdown) => BulkOperation(
    type: BulkOperationType.setMarkdownStatus,
    value: isMarkdown,
    description: 'Markdown-Status setzen',
  );
}

/// Typen von Massenoperationen
enum BulkOperationType {
  toggleFavorites,
  addTags,
  removeTags,
  changeType,
  assignCampaign,
  setCreator,
  delete,
  duplicate,
  setMarkdownStatus,
}
