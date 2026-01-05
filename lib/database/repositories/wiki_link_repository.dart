import 'dart:async';
import '../core/database_connection.dart';
import '../core/database_entity.dart';
import '../entities/wiki_link_entity.dart';
import '../../models/wiki_link.dart';
import 'base_repository.dart';
import '../../services/exceptions/service_exceptions.dart';

/// Repository für Wiki-Link-Operationen
/// 
/// @deprecated Dieses Repository wird durch WikiLinkModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class WikiLinkRepository extends BaseRepository<WikiLinkEntity> {
  WikiLinkRepository(DatabaseConnection databaseConnection) 
      : super(databaseConnection);

  @override
  String get tableName => 'wiki_links';

  @override
  DatabaseEntity<WikiLinkEntity> get entityFactory => _WikiLinkEntityFactory();

  WikiLinkEntity fromMap(Map<String, dynamic> map) {
    return WikiLinkEntity.fromMap(map);
  }

  Map<String, dynamic> toMap(WikiLinkEntity entity) {
    return {
      'id': entity.id,
      'source_entry_id': entity.sourceEntryId,
      'target_entry_id': entity.targetEntryId,
      'link_type': entity.linkType.name, // Nur der Name, z.B. "reference"
      'created_at': entity.createdAt.toIso8601String(),
      'created_by': entity.createdBy,
    };
  }

  /// Holt alle Wiki-Links
  Future<List<WikiLinkEntity>> getAll() async {
    return await findWhere(orderBy: 'created_at DESC');
  }

  /// Holt alle Links für einen Wiki-Eintrag (ausgehende Links)
  Future<List<WikiLinkEntity>> getLinksForEntry(String entryId) async {
    return await findWhere(
      where: 'source_entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'created_at DESC',
    );
  }

  /// Holt alle Backlinks für einen Wiki-Eintrag (eingehende Links)
  Future<List<WikiLinkEntity>> getBacklinksForEntry(String entryId) async {
    return await findWhere(
      where: 'target_entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'created_at DESC',
    );
  }

  /// Löscht alle Links für einen Wiki-Eintrag
  Future<void> deleteAllLinksForEntry(String entryId) async {
    final db = await connection.database;
    await db.delete(
      tableName,
      where: 'source_entry_id = ? OR target_entry_id = ?',
      whereArgs: [entryId, entryId],
    );
  }

  /// Holt einen Link per ID
  Future<WikiLinkEntity?> getById(String id) async {
    final maps = await findWhere(
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Holt alle Links eines bestimmten Benutzers
  Future<List<WikiLinkEntity>> getLinksByUser(String userId) async {
    return await findWhere(
      where: 'created_by = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  /// Prüft ob ein Link zwischen zwei Einträgen existiert
  Future<bool> linkExists({
    required String sourceEntryId,
    required String targetEntryId,
    WikiLinkType? linkType,
  }) async {
    String whereClause = 'source_entry_id = ? AND target_entry_id = ?';
    List<Object?> whereArgs = [sourceEntryId, targetEntryId];
    
    if (linkType != null) {
      whereClause += ' AND link_type = ?';
      whereArgs.add(linkType!.name);
    }
    
    final maps = await findWhere(
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.isNotEmpty;
  }

  /// Holt Links nach Typ
  Future<List<WikiLinkEntity>> getLinksByType(WikiLinkType linkType) async {
    return await findWhere(
      where: 'link_type = ?',
      whereArgs: [linkType.name], // Nur der Name, z.B. "reference"
      orderBy: 'created_at DESC',
    );
  }

  /// Importiert mehrere Links in einer Transaktion
  Future<List<String>> importLinks(List<WikiLinkEntity> links) async {
    final db = await connection.database;
    final List<String> importedIds = [];
    
    await db.transaction((txn) async {
      for (final link in links) {
        // Prüfen ob Link bereits existiert
        final existing = await txn.query(
          tableName,
          where: 'source_entry_id = ? AND target_entry_id = ? AND link_type = ?',
          whereArgs: [link.sourceEntryId, link.targetEntryId, link.linkType.name],
        );
        
        if (existing.isEmpty) {
          await txn.insert(tableName, toMap(link));
          importedIds.add(link.id);
        }
      }
    });
    
    return importedIds;
  }

  /// Holt Links für einen Eintrag (für Service-Kompatibilität)
  Future<ServiceResult<List<WikiLink>>> getLinksByEntryId(String entryId) async {
    final links = await getLinksForEntry(entryId);
    final wikiLinks = links.map((entity) => entity.toModel()).toList();
    return ServiceResult.success(wikiLinks, operation: 'getLinksByEntryId');
  }

  /// Holt Links für mehrere Einträge (für Service-Kompatibilität)
  Future<ServiceResult<List<WikiLink>>> getLinksByEntryIds(List<String> entryIds) async {
    if (entryIds.isEmpty) {
      return ServiceResult.success(<WikiLink>[], operation: 'getLinksByEntryIds');
    }
    
    final db = await connection.database;
    final placeholders = List.filled(entryIds.length, '?').join(',');
    final List<Map<String, Object?>> maps = await db.query(
      tableName,
      where: 'source_entry_id IN ($placeholders) OR target_entry_id IN ($placeholders)',
      whereArgs: [...entryIds, ...entryIds],
      orderBy: 'created_at DESC',
    );
    
    final links = maps.map((map) => fromMap(map)).toList();
    final wikiLinks = links.map((entity) => entity.toModel()).toList();
    return ServiceResult.success(wikiLinks, operation: 'getLinksByEntryIds');
  }

  /// Holt Links für eine Kampagne (für Service-Kompatibilität)
  Future<ServiceResult<List<WikiLink>>> getLinksByCampaignId(String campaignId) async {
    // WikiLinks sind nicht direkt an Kampagnen gebunden,
    // daher werden alle Links zurückgegeben (wenn notwendig)
    final maps = await findWhere(orderBy: 'created_at DESC');
    final links = maps.map((entity) => entity.toModel()).toList();
    return ServiceResult.success(links, operation: 'getLinksByCampaignId');
  }

  /// Holt verknüpfte Einträge mit JOIN
  Future<List<Map<String, dynamic>>> getLinkedEntriesWithJoin(String entryId) async {
    final db = await connection.database;
    return await db.rawQuery('''
      SELECT DISTINCT 
        we.*,
        wl.link_type,
        wl.created_at as link_created_at
      FROM wiki_links wl
      INNER JOIN wiki_entries we ON (wl.target_entry_id = we.id)
      WHERE wl.source_entry_id = ?
      ORDER BY wl.created_at DESC
    ''', [entryId]);
  }

  /// Sucht nach Links mit Details
  Future<List<Map<String, dynamic>>> searchLinksWithDetails(String query) async {
    final db = await connection.database;
    return await db.rawQuery('''
      SELECT wl.*, se.title as source_title, te.title as target_title
      FROM wiki_links wl
      LEFT JOIN wiki_entries se ON wl.source_entry_id = se.id
      LEFT JOIN wiki_entries te ON wl.target_entry_id = te.id
      WHERE se.title LIKE ? OR te.title LIKE ?
      ORDER BY wl.created_at DESC
    ''', ['%$query%', '%$query%']);
  }

  /// Holt Link-Statistiken
  Future<Map<String, dynamic>> getLinkStatistics() async {
    final db = await connection.database;
    final byType = await db.rawQuery('''
      SELECT link_type, COUNT(*) as count
      FROM wiki_links
      GROUP BY link_type
    ''');
    
    final total = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM wiki_links
    ''');

    return {
      'total': total.first['total'],
      'byType': byType,
    };
  }

  /// Bereinigt ungültige Links
  Future<int> cleanupInvalidLinks() async {
    final db = await connection.database;
    // Erst alle ungültigen IDs finden
    final invalidSource = await db.rawQuery('''
      SELECT DISTINCT wl.id
      FROM wiki_links wl
      WHERE wl.source_entry_id NOT IN (SELECT id FROM wiki_entries)
    ''');
    
    final invalidTarget = await db.rawQuery('''
      SELECT DISTINCT wl.id
      FROM wiki_links wl
      WHERE wl.target_entry_id NOT IN (SELECT id FROM wiki_entries)
    ''');
    
    // IDs zusammenführen
    final invalidIds = <String>{
      ...invalidSource.map((m) => m['id'] as String),
      ...invalidTarget.map((m) => m['id'] as String),
    };
    
    if (invalidIds.isEmpty) return 0;
    
    // Löschen
    final placeholders = List.filled(invalidIds.length, '?').join(',');
    await db.execute('''
      DELETE FROM wiki_links WHERE id IN ($placeholders)
    ''', invalidIds.toList());
    
    return invalidIds.length;
  }

  /// Holt Backlinks mit Details
  Future<List<Map<String, dynamic>>> getBacklinksWithDetails(String entryId) async {
    final db = await connection.database;
    return await db.rawQuery('''
      SELECT DISTINCT 
        we.*,
        wl.link_type,
        wl.created_at as link_created_at
      FROM wiki_links wl
      INNER JOIN wiki_entries we ON (wl.source_entry_id = we.id)
      WHERE wl.target_entry_id = ?
      ORDER BY wl.created_at DESC
    ''', [entryId]);
  }

  /// Holt verknüpfte Einträge mit Details
  Future<List<Map<String, dynamic>>> getLinkedEntriesWithDetails(String entryId) async {
    final db = await connection.database;
    return await db.rawQuery('''
      SELECT DISTINCT 
        we.*,
        wl.link_type,
        wl.created_at as link_created_at
      FROM wiki_links wl
      INNER JOIN wiki_entries we ON (wl.target_entry_id = we.id)
      WHERE wl.source_entry_id = ?
      ORDER BY wl.created_at DESC
    ''', [entryId]);
  }

  /// Baut Wiki-Hierarchie auf
  Future<List<Map<String, dynamic>>> buildHierarchy(String rootEntryId) async {
    final result = <Map<String, dynamic>>[];
    final visited = <String>{};
    final queue = <String>[rootEntryId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current)) continue;
      visited.add(current);

      final links = await getLinksForEntry(current);
      for (final link in links) {
        if (!visited.contains(link.targetEntryId)) {
          result.add({
            'parent': current,
            'child': link.targetEntryId,
            'linkType': link.linkType.name,
          });
          queue.add(link.targetEntryId);
        }
      }
    }

    return result;
  }
}

/// Entity Factory für WikiLinkEntity
class _WikiLinkEntityFactory extends DatabaseEntity<WikiLinkEntity> {
  _WikiLinkEntityFactory();
  
  @override
  WikiLinkEntity fromDatabaseMap(Map<String, dynamic> map) {
    return WikiLinkEntity.fromMap(map);
  }

  @override
  Map<String, dynamic> toDatabaseMap() {
    return {};
  }
  
  @override
  String get tableName => 'wiki_links';
  
  @override
  List<String> get databaseFields => [
    'id', 'source_entry_id', 'target_entry_id', 'link_type',
    'created_at', 'created_by'
  ];
  
  @override
  bool get isValid => true;
  
  @override
  List<String> get validationErrors => [];
  
  @override
  List<String> get createTableSql => [
    'CREATE TABLE IF NOT EXISTS wiki_links ('
      'id TEXT PRIMARY KEY,'
      'source_entry_id TEXT NOT NULL,'
      'target_entry_id TEXT NOT NULL,'
      'link_type TEXT NOT NULL,'
      'created_at TEXT NOT NULL,'
      'created_by TEXT'
    ')'
  ];
}
