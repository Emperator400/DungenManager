// lib/services/wiki_link_service.dart
import 'package:uuid/uuid.dart';
import '../models/wiki_link.dart';
import '../models/wiki_entry.dart';
import '../database/database_helper.dart';

/// Service für Wiki-Link-Management
/// Handhabt Beziehungen zwischen Wiki-Einträgen
class WikiLinkService {
  static const _uuid = Uuid();
  static DatabaseHelper get _db => DatabaseHelper.instance;

  /// Erstellt einen neuen Wiki-Link
  static Future<String> createLink({
    required String sourceEntryId,
    required String targetEntryId,
    required WikiLinkType linkType,
    String? createdBy,
  }) async {
    final db = await _db.database;
    final linkId = _uuid.v4();
    
    final link = WikiLink(
      id: linkId,
      sourceEntryId: sourceEntryId,
      targetEntryId: targetEntryId,
      linkType: linkType,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
    
    await db.insert('wiki_links', link.toMap());
    return linkId;
  }

  /// Löscht einen Wiki-Link
  static Future<void> deleteLink(String linkId) async {
    final db = await _db.database;
    await db.delete('wiki_links', where: 'id = ?', whereArgs: [linkId]);
  }

  /// Löscht alle Links für einen Wiki-Eintrag
  static Future<void> deleteAllLinksForEntry(String entryId) async {
    final db = await _db.database;
    await db.delete('wiki_links', where: 'source_entry_id = ? OR target_entry_id = ?', whereArgs: [entryId, entryId]);
  }

  /// Holt alle Links für einen Wiki-Eintrag ( ausgehende Links )
  static Future<List<WikiLink>> getLinksForEntry(String entryId) async {
    final db = await _db.database;
    final maps = await db.query(
      'wiki_links',
      where: 'source_entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => WikiLink.fromMap(map)).toList();
  }

  /// Holt alle Backlinks für einen Wiki-Eintrag ( eingehende Links )
  static Future<List<WikiLink>> getBacklinksForEntry(String entryId) async {
    final db = await _db.database;
    final maps = await db.query(
      'wiki_links',
      where: 'target_entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => WikiLink.fromMap(map)).toList();
  }

  /// Holt alle verknüpften Einträge für einen Wiki-Eintrag
  static Future<List<WikiEntry>> getLinkedEntries(String entryId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT we.* FROM wiki_entries we
      INNER JOIN wiki_links wl ON we.id = wl.target_entry_id
      WHERE wl.source_entry_id = ?
      ORDER BY wl.created_at DESC
    ''', [entryId]);
    
    return maps.map((map) => WikiEntry.fromMap(map)).toList();
  }

  /// Prüft ob ein Link zwischen zwei Einträgen existiert
  static Future<bool> linkExists({
    required String sourceEntryId,
    required String targetEntryId,
    WikiLinkType? linkType,
  }) async {
    final db = await _db.database;
    String whereClause = 'source_entry_id = ? AND target_entry_id = ?';
    List<dynamic> whereArgs = [sourceEntryId, targetEntryId];
    
    if (linkType != null) {
      whereClause += ' AND link_type = ?';
      whereArgs.add(linkType.toString());
    }
    
    final maps = await db.query('wiki_links', where: whereClause, whereArgs: whereArgs);
    return maps.isNotEmpty;
  }

  /// Aktualisiert einen Wiki-Link
  static Future<void> updateLink(String linkId, {
    WikiLinkType? linkType,
  }) async {
    final db = await _db.database;
    final updates = <String, dynamic>{};
    
    if (linkType != null) {
      updates['link_type'] = linkType.toString();
    }
    
    if (updates.isNotEmpty) {
      await db.update('wiki_links', updates, where: 'id = ?', whereArgs: [linkId]);
    }
  }

  /// Holt Links nach Typ
  static Future<List<WikiLink>> getLinksByType(WikiLinkType linkType) async {
    final db = await _db.database;
    final maps = await db.query(
      'wiki_links',
      where: 'link_type = ?',
      whereArgs: [linkType.toString()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => WikiLink.fromMap(map)).toList();
  }

  /// Holt alle Links eines bestimmten Benutzers
  static Future<List<WikiLink>> getLinksByUser(String userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'wiki_links',
      where: 'created_by = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => WikiLink.fromMap(map)).toList();
  }

  /// Sucht nach Links basierend auf Entry-Titeln
  static Future<List<WikiLink>> searchLinks(String query) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT wl.* FROM wiki_links wl
      INNER JOIN wiki_entries we_source ON wl.source_entry_id = we_source.id
      INNER JOIN wiki_entries we_target ON wl.target_entry_id = we_target.id
      WHERE we_source.title LIKE ? OR we_target.title LIKE ?
      ORDER BY wl.created_at DESC
    ''', ['%$query%', '%$query%']);
    
    return maps.map((map) => WikiLink.fromMap(map)).toList();
  }

  /// Holt Link-Statistiken
  static Future<Map<String, dynamic>> getLinkStatistics() async {
    final db = await _db.database;
    
    // Gesamtzahl der Links
    final totalLinksResult = await db.rawQuery('SELECT COUNT(*) as count FROM wiki_links');
    final totalLinks = totalLinksResult.first['count'] as int;
    
    // Links nach Typ
    final linksByTypeResult = await db.rawQuery('''
      SELECT link_type, COUNT(*) as count 
      FROM wiki_links 
      GROUP BY link_type 
      ORDER BY count DESC
    ''');
    
    // Meiste verknüpfte Einträge
    final mostLinkedResult = await db.rawQuery('''
      SELECT 
        we.id,
        we.title,
        COUNT(*) as link_count
      FROM wiki_entries we
      INNER JOIN wiki_links wl ON we.id = wl.target_entry_id
      GROUP BY we.id, we.title
      ORDER BY link_count DESC
      LIMIT 10
    ''');
    
    return {
      'totalLinks': totalLinks,
      'linksByType': linksByTypeResult,
      'mostLinked': mostLinkedResult,
    };
  }

  /// Bereinigt ungültige Links (verweist auf nicht existierende Einträge)
  static Future<int> cleanupInvalidLinks() async {
    final db = await _db.database;
    
    return await db.transaction((txn) async {
      // Lösche Links mit ungültiger Source
      await txn.rawQuery('''
        DELETE FROM wiki_links 
        WHERE source_entry_id NOT IN (SELECT id FROM wiki_entries)
      ''');
      
      // Lösche Links mit ungültigem Target
      final result = await txn.rawQuery('''
        DELETE FROM wiki_links 
        WHERE target_entry_id NOT IN (SELECT id FROM wiki_entries)
      ''');
      
      return result.first.values.first as int;
    });
  }

  /// Dupliziert Links für einen kopierten Eintrag
  static Future<void> duplicateLinksForEntry({
    required String originalEntryId,
    required String newEntryId,
    String? createdBy,
  }) async {
    final db = await _db.database;
    final originalLinks = await getLinksForEntry(originalEntryId);
    
    await db.transaction((txn) async {
      for (final link in originalLinks) {
        final newLink = WikiLink(
          id: _uuid.v4(),
          sourceEntryId: newEntryId,
          targetEntryId: link.targetEntryId,
          linkType: link.linkType,
          createdAt: DateTime.now(),
          createdBy: createdBy,
        );
        
        await txn.insert('wiki_links', newLink.toMap());
      }
    });
  }

  /// Importiert Links aus einer Liste
  static Future<WikiLinkImportResult> importLinks(List<Map<String, dynamic>> linkData) async {
    final db = await _db.database;
    int importedCount = 0;
    int skippedCount = 0;
    final List<String> errors = [];
    
    await db.transaction((txn) async {
      for (final data in linkData) {
        try {
          final link = WikiLink.fromMap(data);
          
          // Prüfen ob Link bereits existiert
          final existing = await txn.query(
            'wiki_links',
            where: 'source_entry_id = ? AND target_entry_id = ? AND link_type = ?',
            whereArgs: [link.sourceEntryId, link.targetEntryId, link.linkType.toString()],
          );
          
          if (existing.isEmpty) {
            await txn.insert('wiki_links', link.toMap());
            importedCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          errors.add('Fehler bei Link: $e');
          skippedCount++;
        }
      }
    });
    
    return WikiLinkImportResult(
      success: true,
      importedCount: importedCount,
      skippedCount: skippedCount,
      errors: errors,
    );
  }

  /// Manuellen Link erstellen (Alias für createLink)
  static Future<String> createManualLink({
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
  static Future<List<WikiLink>> getOutgoingLinks(String entryId) async {
    return await getLinksForEntry(entryId);
  }

  /// Holt eingehende Links mit Details
  static Future<List<Map<String, dynamic>>> getBacklinksWithDetails(String entryId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT 
        wl.*,
        we.title as source_title,
        we.entry_type as source_type
      FROM wiki_links wl
      INNER JOIN wiki_entries we ON wl.source_entry_id = we.id
      WHERE wl.target_entry_id = ?
      ORDER BY wl.created_at DESC
    ''', [entryId]);
    
    return maps;
  }

  /// Holt ausgehende Links mit Details
  static Future<List<Map<String, dynamic>>> getLinkedEntriesWithDetails(String entryId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT 
        wl.*,
        we.title as target_title,
        we.entry_type as target_type
      FROM wiki_links wl
      INNER JOIN wiki_entries we ON wl.target_entry_id = we.id
      WHERE wl.source_entry_id = ?
      ORDER BY wl.created_at DESC
    ''', [entryId]);
    
    return maps;
  }

  /// Baut Wiki-Hierarchie auf
  static Future<List<Map<String, dynamic>>> buildHierarchy(String rootEntryId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      WITH RECURSIVE wiki_tree AS (
        SELECT 
          id,
          title,
          entry_type,
          parent_id,
          0 as level
        FROM wiki_entries
        WHERE id = ?
        
        UNION ALL
        
        SELECT 
          we.id,
          we.title,
          we.entry_type,
          we.parent_id,
          wt.level + 1
        FROM wiki_entries we
        INNER JOIN wiki_tree wt ON we.parent_id = wt.id
        WHERE we.parent_id IS NOT NULL
      )
      SELECT * FROM wiki_tree ORDER BY level, title
    ''', [rootEntryId]);
    
    return maps;
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
