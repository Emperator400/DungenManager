import '../core/database_connection.dart';
import '../../models/wiki_entry.dart';
import 'model_repository.dart';

/// Repository für WikiEntry Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem WikiEntry Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.
class WikiEntryModelRepository extends ModelRepository<WikiEntry> {
  WikiEntryModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'wiki_entries';

  @override
  Map<String, dynamic> toDatabaseMap(WikiEntry entry) {
    return entry.toDatabaseMap();
  }

  @override
  WikiEntry fromDatabaseMap(Map<String, dynamic> map) {
    return WikiEntry.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Wiki-Einträge nach Typ
  Future<List<WikiEntry>> findByType(WikiEntryType type) async {
    return await findWhere(
      where: 'entry_type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'title ASC',
    );
  }

  /// Findet Wiki-Einträge nach Kampagne
  Future<List<WikiEntry>> findByCampaign(String campaignId) async {
    return await findWhere(
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'title ASC',
    );
  }

  /// Findet Wiki-Einträge nach Parent
  Future<List<WikiEntry>> findByParent(String parentId) async {
    return await findWhere(
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'title ASC',
    );
  }

  /// Sucht Wiki-Einträge mit komplexen Filtern
  Future<List<WikiEntry>> searchEntries({
    String? searchTerm,
    WikiEntryType? type,
    String? campaignId,
    String? parentId,
    List<String>? tags,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(title LIKE ? OR summary LIKE ? OR content LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%', '%$searchTerm%']);
    }

    if (type != null) {
      whereConditions.add('entry_type = ?');
      whereArgs.add(type.toString().split('.').last);
    }

    if (campaignId != null) {
      whereConditions.add('campaign_id = ?');
      whereArgs.add(campaignId);
    }

    if (parentId != null) {
      whereConditions.add('parent_id = ?');
      whereArgs.add(parentId);
    }

    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        whereConditions.add('tags LIKE ?');
        whereArgs.add('%$tag%');
      }
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'title ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== WIKI-STATISTIKEN =====

  /// Holt umfassende Statistiken über Wiki-Einträge
  Future<Map<String, dynamic>> getWikiStatistics() async {
    // Gesamtzahl der Einträge
    final totalCount = await count();
    
    // Typ-Verteilung
    final typeDistributionResult = await rawQuery('''
      SELECT 
        entry_type,
        COUNT(*) as count
      FROM $tableName
      GROUP BY entry_type
      ORDER BY entry_type
    ''');
    
    // Durchschnittliche Länge
    final avgLengthResult = await rawQuery('''
      SELECT 
        AVG(LENGTH(content)) as avg_content_length
      FROM $tableName
      WHERE content IS NOT NULL
    ''');

    return {
      'totalEntries': totalCount,
      'typeDistribution': typeDistributionResult,
      'averageContentLength': (avgLengthResult.first['avg_content_length'] as double?)?.toInt() ?? 0,
    };
  }

  /// ===== ADVANCED SUCHEN =====

  /// Letzte Einträge finden
  Future<List<WikiEntry>> findRecentEntries(int limit) async {
    return await findWhere(
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  /// Holt mehrere Einträge per IDs
  Future<List<WikiEntry>> findByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    final placeholders = List.filled(ids.length, '?').join(',');
    return await findWhere(
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Holt alle Einträge (Alias für findAll)
  Future<List<WikiEntry>> getAll() async {
    return await findAll();
  }

  /// Findet Einträge nach Kampagne-ID
  Future<List<WikiEntry>> findByCampaignId(String campaignId) async {
    return await findWhere(
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Einträge nach Titel und Typ
  Future<List<WikiEntry>> findByTitleAndType(String title, WikiEntryType type) async {
    return await findWhere(
      where: 'title = ? AND entry_type = ?',
      whereArgs: [
        title,
        type.toString().split('.').last,
      ],
    );
  }

  /// Findet Einträge nach Titel (Teilstring-Suche)
  Future<List<WikiEntry>> findByTitle(String title) async {
    return await findWhere(
      where: 'title LIKE ?',
      whereArgs: ['%$title%'],
      orderBy: 'title ASC',
    );
  }

  /// Wurzel-Einträge finden (ohne Parent)
  Future<List<WikiEntry>> findRootEntries() async {
    return await findWhere(
      where: 'parent_id IS NULL OR parent_id = ?',
      whereArgs: [''],
      orderBy: 'title ASC',
    );
  }
}
