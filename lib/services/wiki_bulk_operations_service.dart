// lib/services/wiki_bulk_operations_service.dart
import 'package:flutter/foundation.dart';
import '../models/wiki_entry.dart';
import '../database/database_helper.dart';

/// Service für Massenoperationen auf Wiki-Einträgen
/// Unterstützt mehrere Einträge gleichzeitig zu bearbeiten
class WikiBulkOperationsService {
  static DatabaseHelper get _db => DatabaseHelper.instance;

  /// Togglet Favoriten-Status für mehrere Einträge
  static Future<BulkOperationResult> toggleFavorites(
    List<String> entryIds,
    bool isFavorite,
  ) async {
    try {
      final db = await _db.database;
      int updatedCount = 0;
      
      await db.transaction((txn) async {
        for (final entryId in entryIds) {
          final result = await txn.update(
            'wiki_entries',
            {'isFavorite': isFavorite ? 1 : 0},
            where: 'id = ?',
            whereArgs: [entryId],
          );
          if (result > 0) updatedCount++;
        }
      });
      
      return BulkOperationResult(
        success: true,
        message: '$updatedCount Einträge als ${isFavorite ? 'Favorit' : 'nicht mehr Favorit'} markiert',
        affectedCount: updatedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Aktualisieren der Favoriten: $e',
      );
    }
  }

  /// Fügt Tags zu mehreren Einträgen hinzu
  static Future<BulkOperationResult> addTagsToEntries(
    List<String> entryIds,
    List<String> tags,
  ) async {
    try {
      final db = await _db.database;
      int updatedCount = 0;
      
      await db.transaction((txn) async {
        for (final entryId in entryIds) {
          // Aktuelle Tags holen
          final existing = await txn.query(
            'wiki_entries',
            columns: ['tags'],
            where: 'id = ?',
            whereArgs: [entryId],
          );
          
          if (existing.isNotEmpty) {
            final currentTagsStr = existing.first['tags'] as String? ?? '';
            final currentTags = currentTagsStr.isNotEmpty
                ? currentTagsStr.split(',').where((tag) => tag.isNotEmpty).toSet()
                : <String>{};
            
            // Neue Tags hinzufügen
            for (final tag in tags) {
              final trimmedTag = tag.trim();
              if (trimmedTag.isNotEmpty) {
                currentTags.add(trimmedTag);
              }
            }
            
            // Update durchführen
            final result = await txn.update(
              'wiki_entries',
              {
                'tags': currentTags.join(','),
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [entryId],
            );
            
            if (result > 0) updatedCount++;
          }
        }
      });
      
      return BulkOperationResult(
        success: true,
        message: 'Tags zu $updatedCount Einträgen hinzugefügt',
        affectedCount: updatedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Hinzufügen der Tags: $e',
      );
    }
  }

  /// Entfernt Tags von mehreren Einträgen
  static Future<BulkOperationResult> removeTagsFromEntries(
    List<String> entryIds,
    List<String> tags,
  ) async {
    try {
      final db = await _db.database;
      int updatedCount = 0;
      
      await db.transaction((txn) async {
        for (final entryId in entryIds) {
          // Aktuelle Tags holen
          final existing = await txn.query(
            'wiki_entries',
            columns: ['tags'],
            where: 'id = ?',
            whereArgs: [entryId],
          );
          
          if (existing.isNotEmpty) {
            final currentTagsStr = existing.first['tags'] as String? ?? '';
            final currentTags = currentTagsStr.isNotEmpty
                ? currentTagsStr.split(',').where((tag) => tag.isNotEmpty).toSet()
                : <String>{};
            
            // Tags entfernen
            for (final tag in tags) {
              currentTags.remove(tag.trim());
            }
            
            // Update durchführen
            final result = await txn.update(
              'wiki_entries',
              {
                'tags': currentTags.join(','),
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [entryId],
            );
            
            if (result > 0) updatedCount++;
          }
        }
      });
      
      return BulkOperationResult(
        success: true,
        message: 'Tags von $updatedCount Einträgen entfernt',
        affectedCount: updatedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Entfernen der Tags: $e',
      );
    }
  }

  /// Ändert den Typ für mehrere Einträge
  static Future<BulkOperationResult> changeEntryType(
    List<String> entryIds,
    WikiEntryType newType,
  ) async {
    try {
      final db = await _db.database;
      int updatedCount = 0;
      
      await db.transaction((txn) async {
        for (final entryId in entryIds) {
          final result = await txn.update(
            'wiki_entries',
            {
              'entryType': newType.toString(),
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [entryId],
          );
          if (result > 0) updatedCount++;
        }
      });
      
      return BulkOperationResult(
        success: true,
        message: 'Typ von $updatedCount Einträgen geändert',
        affectedCount: updatedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Ändern des Typs: $e',
      );
    }
  }

  /// Weist mehrere Einträge einer Kampagne zu
  static Future<BulkOperationResult> assignToCampaign(
    List<String> entryIds,
    String? campaignId,
  ) async {
    try {
      final db = await _db.database;
      int updatedCount = 0;
      
      await db.transaction((txn) async {
        for (final entryId in entryIds) {
          final result = await txn.update(
            'wiki_entries',
            {
              'campaignId': campaignId,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [entryId],
          );
          if (result > 0) updatedCount++;
        }
      });
      
      final action = campaignId != null ? 'zugewiesen' : 'entfernt';
      return BulkOperationResult(
        success: true,
        message: '$updatedCount Einträge der Kampagne $action',
        affectedCount: updatedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Zuweisen zur Kampagne: $e',
      );
    }
  }

  /// Setzt den Ersteller für mehrere Einträge
  static Future<BulkOperationResult> setCreator(
    List<String> entryIds,
    String? creator,
  ) async {
    try {
      final db = await _db.database;
      int updatedCount = 0;
      
      await db.transaction((txn) async {
        for (final entryId in entryIds) {
          final result = await txn.update(
            'wiki_entries',
            {
              'createdBy': creator,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [entryId],
          );
          if (result > 0) updatedCount++;
        }
      });
      
      final action = creator != null ? 'gesetzt' : 'entfernt';
      return BulkOperationResult(
        success: true,
        message: 'Ersteller für $updatedCount Einträge $action',
        affectedCount: updatedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Setzen des Erstellers: $e',
      );
    }
  }

  /// Löscht mehrere Einträge
  static Future<BulkOperationResult> deleteEntries(
    List<String> entryIds, {
    bool confirmDeletion = false,
  }) async {
    if (!confirmDeletion) {
      return BulkOperationResult(
        success: false,
        message: 'Löschen nicht bestätigt',
        requiresConfirmation: true,
      );
    }

    try {
      final db = await _db.database;
      int deletedCount = 0;
      
      await db.transaction((txn) async {
        // Zuerst alle Wiki-Links löschen
        for (final entryId in entryIds) {
          await txn.delete(
            'wiki_links',
            where: 'source_entry_id = ? OR target_entry_id = ?',
            whereArgs: [entryId, entryId],
          );
        }
        
        // Dann die Einträge löschen
        for (final entryId in entryIds) {
          final result = await txn.delete(
            'wiki_entries',
            where: 'id = ?',
            whereArgs: [entryId],
          );
          if (result > 0) deletedCount++;
        }
      });
      
      return BulkOperationResult(
        success: true,
        message: '$deletedCount Einträge gelöscht',
        affectedCount: deletedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Löschen der Einträge: $e',
      );
    }
  }

  /// Dupliziert mehrere Einträge
  static Future<BulkOperationResult> duplicateEntries(
    List<String> entryIds,
  ) async {
    try {
      final db = await _db.database;
      int duplicatedCount = 0;
      
      await db.transaction((txn) async {
        for (final entryId in entryIds) {
          // Original-Eintrag holen
          final existing = await txn.query(
            'wiki_entries',
            where: 'id = ?',
            whereArgs: [entryId],
          );
          
          if (existing.isNotEmpty) {
            final originalEntry = WikiEntry.fromMap(existing.first);
            final duplicate = originalEntry.copyWith(
              id: null, // Neue ID wird generiert
              title: '${originalEntry.title} (Kopie)',
              isFavorite: false, // Kopien sind nicht favorisiert
            );
            
            await txn.insert('wiki_entries', duplicate.toMap());
            duplicatedCount++;
          }
        }
      });
      
      return BulkOperationResult(
        success: true,
        message: '$duplicatedCount Einträge dupliziert',
        affectedCount: duplicatedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Duplizieren der Einträge: $e',
      );
    }
  }

  /// Setzt Markdown-Status für mehrere Einträge
  static Future<BulkOperationResult> setMarkdownStatus(
    List<String> entryIds,
    bool isMarkdown,
  ) async {
    try {
      final db = await _db.database;
      int updatedCount = 0;
      
      await db.transaction((txn) async {
        for (final entryId in entryIds) {
          final result = await txn.update(
            'wiki_entries',
            {
              'isMarkdown': isMarkdown ? 1 : 0,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [entryId],
          );
          if (result > 0) updatedCount++;
        }
      });
      
      return BulkOperationResult(
        success: true,
        message: 'Markdown-Status für $updatedCount Einträge ${isMarkdown ? 'aktiviert' : 'deaktiviert'}',
        affectedCount: updatedCount,
      );
    } catch (e) {
      return BulkOperationResult(
        success: false,
        message: 'Fehler beim Ändern des Markdown-Status: $e',
      );
    }
  }

  /// Holt alle Tags aus den angegebenen Einträgen
  static Future<Set<String>> getAllTagsFromEntries(List<String> entryIds) async {
    if (entryIds.isEmpty) return <String>{};
    
    try {
      final db = await _db.database;
      final placeholders = List.filled(entryIds.length, '?').join(',');
      
      final result = await db.query(
        'wiki_entries',
        columns: ['tags'],
        where: 'id IN ($placeholders)',
        whereArgs: entryIds,
      );
      
      final allTags = <String>{};
      
      for (final row in result) {
        final tagsStr = row['tags'] as String? ?? '';
        if (tagsStr.isNotEmpty) {
          final tags = tagsStr.split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty);
          allTags.addAll(tags);
        }
      }
      
      return allTags;
    } catch (e) {
      if (kDebugMode) print('Fehler beim Abrufen der Tags: $e');
      return <String>{};
    }
  }

  /// Zählt Einträge nach Typ
  static Future<Map<WikiEntryType, int>> countEntriesByType(
    List<String> entryIds,
  ) async {
    if (entryIds.isEmpty) return {};
    
    try {
      final db = await _db.database;
      final placeholders = List.filled(entryIds.length, '?').join(',');
      
      final result = await db.query(
        'wiki_entries',
        columns: ['entryType', 'COUNT(*) as count'],
        where: 'id IN ($placeholders)',
        whereArgs: entryIds,
        groupBy: 'entryType',
      );
      
      final counts = <WikiEntryType, int>{};
      
      for (final row in result) {
        final typeStr = row['entryType'] as String;
        final count = row['count'] as int;
        
        final type = WikiEntryType.values.firstWhere(
          (type) => type.toString() == typeStr,
          orElse: () => WikiEntryType.Lore,
        );
        
        counts[type] = count;
      }
      
      return counts;
    } catch (e) {
      if (kDebugMode) print('Fehler beim Zählen der Einträge: $e');
      return {};
    }
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
}
