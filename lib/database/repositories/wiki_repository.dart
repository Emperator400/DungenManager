import '../core/database_connection.dart';
import '../core/database_entity.dart';
import '../entities/wiki_entity.dart';
import '../../models/wiki_entry.dart';
import 'base_repository.dart';

/// Repository für Wiki Entry-Operationen
/// 
/// @deprecated Dieses Repository wird durch WikiEntryModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class WikiRepository extends BaseRepository<WikiEntity> {
  WikiRepository(DatabaseConnection databaseConnection) 
      : super(databaseConnection);

  @override
  String get tableName => WikiEntity.tableName;

  @override
  DatabaseEntity<WikiEntity> get entityFactory => WikiEntityEntityFactory();

  /// Spezielle Wiki-spezifische Abfragen
  Future<List<WikiEntry>> findByCategory(String category) async {
    final maps = await findWhere(
      where: 'category = ?',
      whereArgs: [category],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<WikiEntry>> findByType(String type) async {
    final maps = await findWhere(
      where: 'type = ?',
      whereArgs: [type],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<WikiEntry>> searchWiki(String query) async {
    final maps = await search(query, fields: ['title', 'content', 'tags']);
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<WikiEntry>> findFavoriteEntries() async {
    final maps = await findWhere(
      where: 'is_favorite = ?',
      whereArgs: [1],
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<WikiEntry>> findByTags(List<String> tags) async {
    if (tags.isEmpty) return [];
    
    final whereConditions = tags.map((tag) => 'tags LIKE ?').join(' OR ');
    final searchArgs = tags.map((tag) => '%$tag%').toList();
    
    final maps = await findWhere(
      where: whereConditions,
      whereArgs: searchArgs,
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<WikiEntry>> findRecentlyModified({int days = 7}) async {
    final sinceDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    
    final maps = await findWhere(
      where: 'updated_at >= ?',
      whereArgs: [sinceDate],
      orderBy: 'updated_at DESC',
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  Future<List<WikiEntry>> findByCampaign(String campaignId) async {
    final maps = await findWhere(
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'title ASC',
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  /// Holt einen Eintrag nach ID (von BaseRepository)
  @override
  Future<WikiEntity?> getById(String id) async {
    final maps = await findWhere(
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Holt einen Eintrag nach Titel und Typ (für Import-Deduplizierung)
  Future<WikiEntry?> getByTitleAndType(String title, WikiEntryType type) async {
    final maps = await findWhere(
      where: 'title = ? AND type = ?',
      whereArgs: [title, type.name],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return maps.first.toModel();
  }

  /// Holt mehrere Einträge nach IDs (für Import)
  Future<List<WikiEntry>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await findWhere(
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    
    return maps.map((entity) => entity.toModel()).toList();
  }

  /// Holt alle Einträge (als WikiEntry Models)
  Future<List<WikiEntry>> getAllAsModels() async {
    final entities = await findAll();
    return entities.map((entity) => entity.toModel()).toList();
  }

  /// Alias für getAllAsModels (für Service-Kompatibilität)
  Future<List<WikiEntry>> getAll() => getAllAsModels();

  /// Holt Einträge nach Kampagne (Alias)
  Future<List<WikiEntry>> getByCampaignId(String campaignId) => findByCampaign(campaignId);
}

/// Entity Factory für WikiEntity
class WikiEntityEntityFactory extends DatabaseEntity<WikiEntity> {
  WikiEntityEntityFactory();
  
  @override
  WikiEntity fromDatabaseMap(Map<String, dynamic> map) {
    return WikiEntity.fromMap(map);
  }

  @override
  Map<String, dynamic> toDatabaseMap() {
    return {};
  }
  
  @override
  String get tableName => WikiEntity.tableName;
  
  @override
  List<String> get databaseFields => [
    'id', 'title', 'content', 'type', 'category', 'tags', 'campaign_id',
    'parent_id', 'is_favorite', 'is_public', 'source_type', 'source_id',
    'version', 'created_at', 'updated_at'
  ];
  
  @override
  bool get isValid => true;
  
  @override
  List<String> get validationErrors => [];
  
  @override
  List<String> get createTableSql => [WikiEntity.createTableSql()];
}
