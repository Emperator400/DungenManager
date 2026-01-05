import '../core/database_connection.dart';
import '../../models/wiki_link.dart';
import 'model_repository.dart';

/// Repository für WikiLink Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem WikiLink Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.

class WikiLinkModelRepository extends ModelRepository<WikiLink> {
  WikiLinkModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'wiki_links';

  @override
  Map<String, dynamic> toDatabaseMap(WikiLink link) {
    return link.toDatabaseMap();
  }

  @override
  WikiLink fromDatabaseMap(Map<String, dynamic> map) {
    return WikiLink.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Links nach Typ
  Future<List<WikiLink>> findByType(WikiLinkType type) async {
    return await findWhere(
      where: 'link_type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Links nach Quell-Eintrag
  Future<List<WikiLink>> findBySourceEntry(String sourceEntryId) async {
    return await findWhere(
      where: 'source_entry_id = ?',
      whereArgs: [sourceEntryId],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Links nach Ziel-Eintrag
  Future<List<WikiLink>> findByTargetEntry(String targetEntryId) async {
    return await findWhere(
      where: 'target_entry_id = ?',
      whereArgs: [targetEntryId],
      orderBy: 'created_at DESC',
    );
  }

  /// Sucht Links mit komplexen Filtern
  Future<List<WikiLink>> searchLinks({
    WikiLinkType? type,
    String? sourceEntryId,
    String? targetEntryId,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      whereConditions.add('link_type = ?');
      whereArgs.add(type.toString().split('.').last);
    }

    if (sourceEntryId != null) {
      whereConditions.add('source_entry_id = ?');
      whereArgs.add(sourceEntryId);
    }

    if (targetEntryId != null) {
      whereConditions.add('target_entry_id = ?');
      whereArgs.add(targetEntryId);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== ADVANCED SUCHEN =====

  /// Letzte Links finden
  Future<List<WikiLink>> findRecentLinks(int limit) async {
    return await findWhere(
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  /// Löscht alle Links, die mit einer Eintrags-ID verbunden sind
  /// (entweder als Source oder als Target)
  Future<int> deleteLinksByEntryId(String entryId) async {
    final db = await connection.database;
    final count = await db.delete(
      tableName,
      where: 'source_entry_id = ? OR target_entry_id = ?',
      whereArgs: [entryId, entryId],
    );
    return count;
  }

  /// Holt alle Links für eine bestimmte Eintrags-ID
  /// (sowohl als Source als auch als Target)
  Future<List<WikiLink>> getLinksByEntryId(String entryId) async {
    return await findWhere(
      where: 'source_entry_id = ? OR target_entry_id = ?',
      whereArgs: [entryId, entryId],
      orderBy: 'created_at DESC',
    );
  }

  /// Holt alle Links für mehrere Eintrags-IDs
  Future<List<WikiLink>> getLinksByEntryIds(List<String> entryIds) async {
    if (entryIds.isEmpty) return [];
    
    final placeholders = List.filled(entryIds.length, '?').join(',');
    return await findWhere(
      where: 'source_entry_id IN ($placeholders) OR target_entry_id IN ($placeholders)',
      whereArgs: [...entryIds, ...entryIds],
      orderBy: 'created_at DESC',
    );
  }
}
