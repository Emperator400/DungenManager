import 'dart:async';
import '../core/database_entity.dart';
import '../entities/base_entity.dart';
import '../core/database_connection.dart';

/// Basis-Repository für alle Datenbankoperationen
/// Bietet typsichere CRUD-Operationen und erweiterte Funktionen
/// 
/// @deprecated Diese Klasse wird durch ModelRepository<T> ersetzt.
/// Bitte zu den neuen ModelRepositories migrieren:
/// - PlayerCharacterModelRepository
/// - CampaignModelRepository
/// - ItemModelRepository
/// - QuestModelRepository
/// - CreatureModelRepository
/// - SessionModelRepository
/// - SoundModelRepository
/// - WikiEntryModelRepository
/// - WikiLinkModelRepository
/// - InventoryItemModelRepository
/// 
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
abstract class BaseRepository<T extends BaseEntity> {
  final DatabaseConnection _connection;
  
  BaseRepository(DatabaseConnection connection) : _connection = connection;
  
  /// Geschützter Zugriff auf die Datenbankverbindung für abgeleitete Klassen
  DatabaseConnection get connection => _connection;
  
  /// Tabellenname aus der Entity
  String get tableName;
  
  /// Entity-Factory für die Konvertierung
  DatabaseEntity<T> get entityFactory;
  
  /// ===== CRUD OPERATIONEN =====
  
  /// Erstellt eine neue Entität in der Datenbank
  Future<T> create(T entity) async {
    final db = await _connection.database;
    final entityMap = entityFactory.toDatabaseMap();
    
    final id = await db.insert(tableName, entityMap);
    
    // Erstelle eine Kopie mit der neuen ID
    final copy = entity.copyWith();
    copy.id = id as String;
    
    return copy as T;
  }
  
  /// Findet eine Entität anhand ihrer ID
  Future<T?> findById(String id) async {
    final db = await _connection.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return entityFactory.fromDatabaseMap(maps.first);
  }
  
  /// Holt alle Entitäten der Tabelle
  Future<List<T>> findAll({
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _connection.database;
    final maps = await db.query(
      tableName,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => entityFactory.fromDatabaseMap(map)).toList();
  }
  
  /// Aktualisiert eine Entität
  Future<T> update(T entity) async {
    final db = await _connection.database;
    final entityMap = entityFactory.toDatabaseMap();
    
    await db.update(
      tableName,
      entityMap,
      where: 'id = ?',
      whereArgs: [entity.id],
    );
    
    return entity;
  }
  
  /// Löscht eine Entität anhand ihrer ID
  Future<void> delete(String id) async {
    final db = await _connection.database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Löscht mehrere Entitäten
  Future<void> deleteAll(Iterable<String> ids) async {
    final db = await _connection.database;
    
    if (ids.isEmpty) return;
    
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids.toList(),
    );
  }
  
  /// ===== ERWEITERTE SUCHFUNKTIONEN =====
  
  /// Sucht Entitäten mit benutzerdefinierten Bedingungen
  Future<List<T>> findWhere({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
    String? groupBy,
    String? having,
  }) async {
    final db = await _connection.database;
    final maps = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
      groupBy: groupBy,
      having: having,
    );
    
    return maps.map((map) => entityFactory.fromDatabaseMap(map)).toList();
  }
  
  /// Findet Entitäten mit LIKE-Suche
  Future<List<T>> search(String searchTerm, {List<String>? fields}) async {
    if (searchTerm.isEmpty) return findAll();
    
    final searchFields = fields ?? ['name', 'description', 'title'];
    final whereConditions = searchFields.map((field) => '$field LIKE ?').join(' OR ');
    final searchArgs = List.filled(searchFields.length, '%$searchTerm%');
    
    return findWhere(
      where: whereConditions,
      whereArgs: searchArgs,
    );
  }
  
  /// Paginierte Suche mit Sortierung
  Future<List<T>> findWithPagination({
    int page = 0,
    int limit = 20,
    String? orderBy,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final offset = page * limit;
    return findWhere(
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy ?? 'id ASC',
      limit: limit,
      offset: offset,
    );
  }
  
  /// ===== AGGREGATFUNKTIONEN =====
  
  /// Zählt die Anzahl der Einträge
  Future<int> count({String? where, List<dynamic>? whereArgs}) async {
    final db = await _connection.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    
    return result.first['count'] as int;
  }
  
  /// Prüft ob eine Entität existiert
  Future<bool> exists(String id) async {
    final count = await this.count(where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }
  
  /// Holt die maximale ID (für Migrationen)
  Future<int?> getMaxId() async {
    final db = await _connection.database;
    final result = await db.rawQuery(
      'SELECT MAX(CAST(id AS INTEGER)) as max_id FROM $tableName',
    );
    
    final maxId = result.first['max_id'];
    return maxId != null ? maxId as int : null;
  }
  
  /// ===== BATCH OPERATIONEN =====
  
  /// Fügt mehrere Entitäten auf einmal ein
  Future<List<T>> createAll(List<T> entities) async {
    final db = await _connection.database;
    
    return await db.transaction((txn) async {
      final createdEntities = <T>[];
      
      for (final entity in entities) {
        final entityMap = entityFactory.toDatabaseMap();
        final id = await txn.insert(tableName, entityMap);
        
        // Erstelle Kopie mit neuer ID
        final copy = entity.copyWith();
        copy.id = id as String;
        createdEntities.add(copy as T);
      }
      
      return createdEntities;
    });
  }
  
  /// Aktualisiert mehrere Entitäten auf einmal
  Future<void> updateAll(List<T> entities) async {
    final db = await _connection.database;
    
    await db.transaction((txn) async {
      for (final entity in entities) {
        final entityMap = entityFactory.toDatabaseMap();
        await txn.update(
          tableName,
          entityMap,
          where: 'id = ?',
          whereArgs: [entity.id],
        );
      }
    });
  }
  
  /// ===== UTILITY METHODEN =====
  
  /// Leert die gesamte Tabelle
  Future<void> clear() async {
    final db = await _connection.database;
    await db.delete(tableName);
  }
  
  /// Holt Rohdaten für Custom Queries
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await _connection.database;
    return await db.rawQuery(sql, arguments);
  }
  
  /// Führt eine Custom Query aus
  Future<void> executeRaw(String sql, [List<dynamic>? arguments]) async {
    final db = await _connection.database;
    await db.execute(sql);
  }
}
