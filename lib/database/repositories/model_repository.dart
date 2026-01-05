import 'dart:async';
import '../core/database_connection.dart';

/// Basis-Repository für Modelle mit nativer Serialisierung
/// 
/// Dieses Repository arbeitet direkt mit Modelle, die ihre eigenen
/// toDatabaseMap() und fromDatabaseMap() Methoden implementieren.
/// Es ersetzt das Entity-basierte System und vereinfacht die Architektur.
abstract class ModelRepository<T> {
  final DatabaseConnection _connection;
  
  ModelRepository(DatabaseConnection connection) : _connection = connection;
  
  /// Geschützter Zugriff auf die Datenbankverbindung
  DatabaseConnection get connection => _connection;
  
  /// Tabellenname (muss von abgeleiteten Klassen überschrieben werden)
  String get tableName;
  
  /// Serialisiert ein Modelle in ein Datenbank-Map
  Map<String, dynamic> toDatabaseMap(T model);
  
  /// Deserialisiert ein Datenbank-Map in ein Modelle
  T fromDatabaseMap(Map<String, dynamic> map);
  
  /// ===== CRUD OPERATIONEN =====
  
  /// Erstellt eine neue Entität in der Datenbank
  Future<T> create(T model) async {
    print('💾 [ModelRepository] CREATE aufgerufen für Tabelle: $tableName');
    
    final db = await _connection.database;
    final modelMap = toDatabaseMap(model);
    print('💾 [ModelRepository] Model zu speichern: $modelMap');
    
    final id = await db.insert(tableName, modelMap);
    print('💾 [ModelRepository] Insert ID: $id');
    
    // Prüfe, ob das Model bereits eine ID hat (UUID)
    // Falls ja, gib das unveränderte Model zurück
    if (model is dynamic) {
      try {
        final existingId = model.id as String?;
        print('💾 [ModelRepository] Existing ID: $existingId');
        
        // Wenn bereits eine ID vorhanden ist (UUID), gib das Model zurück
        // Die ID wurde bereits in toDatabaseMap() gesetzt
        if (existingId != null && existingId.isNotEmpty) {
          // Hole das Model aus der Datenbank zurück, um sicherzustellen, dass alles gespeichert wurde
          final maps = await db.query(
            tableName,
            where: 'id = ?',
            whereArgs: [existingId],
            limit: 1,
          );
          print('💾 [ModelRepository] ${maps.length} Einträge aus DB zurückgeladen');
          if (maps.isNotEmpty) {
            print('💾 [ModelRepository] Erstelltes Model aus DB zurückgegeben');
            return fromDatabaseMap(maps.first);
          }
          print('💾 [ModelRepository] Kein Eintrag in DB gefunden, gib Original zurück');
          return model;
        }
        // Falls keine ID vorhanden ist, verwende die generierte rowid
        print('💾 [ModelRepository] Keine ID vorhanden, verwende rowid');
        return model.copyWith(id: id.toString()) as T;
      } catch (e) {
        // Fallback: Modelle ohne copyWith
        print('💾 [ModelRepository] Fehler bei ID-Prüfung: $e, gib Original zurück');
        return model;
      }
    }
    
    return model;
  }
  
  /// Findet eine Entität anhand ihrer ID
  Future<T?> findById(String id) async {
    print('💾 [ModelRepository] FIND BY ID aufgerufen: $id');
    
    final db = await _connection.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    print('💾 [ModelRepository] ${maps.length} Einträge gefunden');
    if (maps.isEmpty) return null;
    return fromDatabaseMap(maps.first);
  }
  
  /// Holt alle Entitäten der Tabelle
  Future<List<T>> findAll({
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    print('💾 [ModelRepository] FIND ALL aufgerufen für Tabelle: $tableName');
    
    final db = await _connection.database;
    final maps = await db.query(
      tableName,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    
    print('💾 [ModelRepository] ${maps.length} Einträge gefunden');
    return maps.map((map) => fromDatabaseMap(map)).toList();
  }
  
  /// Aktualisiert eine Entität und gibt das aktualisierte Model aus der Datenbank zurück
  Future<T> update(T model) async {
    final db = await _connection.database;
    final modelMap = toDatabaseMap(model);
    
    // Hole ID vom Modelle
    String id = '';
    if (model is dynamic) {
      id = model.id as String;
    }
    
    await db.update(
      tableName,
      modelMap,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Hole das aktualisierte Model aus der Datenbank zurück
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return model; // Fallback, falls etwas schief geht
    }
    
    return fromDatabaseMap(maps.first);
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
    
    return maps.map((map) => fromDatabaseMap(map)).toList();
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
    final countResult = await count(where: 'id = ?', whereArgs: [id]);
    return countResult > 0;
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
  Future<List<T>> createAll(List<T> models) async {
    final db = await _connection.database;
    
    return await db.transaction((txn) async {
      final createdModels = <T>[];
      
      for (final model in models) {
        final modelMap = toDatabaseMap(model);
        final id = await txn.insert(tableName, modelMap);
        
        // Prüfe, ob das Model bereits eine ID hat (UUID)
        if (model is dynamic) {
          try {
            final existingId = model.id as String?;
            // Wenn bereits eine ID vorhanden ist (UUID), gib das Model zurück
            if (existingId != null && existingId.isNotEmpty) {
              // Hole das Model aus der Datenbank zurück
              final maps = await txn.query(
                tableName,
                where: 'id = ?',
                whereArgs: [existingId],
                limit: 1,
              );
              if (maps.isNotEmpty) {
                createdModels.add(fromDatabaseMap(maps.first));
              } else {
                createdModels.add(model);
              }
            } else {
              // Falls keine ID vorhanden ist, verwende die generierte rowid
              final copy = model.copyWith(id: id.toString()) as T;
              createdModels.add(copy);
            }
          } catch (e) {
            createdModels.add(model);
          }
        } else {
          createdModels.add(model);
        }
      }
      
      return createdModels;
    });
  }
  
  /// Aktualisiert mehrere Entitäten auf einmal
  Future<void> updateAll(List<T> models) async {
    final db = await _connection.database;
    
    await db.transaction((txn) async {
      for (final model in models) {
        final modelMap = toDatabaseMap(model);
        
        String id = '';
        if (model is dynamic) {
          id = model.id as String;
        }
        
        await txn.update(
          tableName,
          modelMap,
          where: 'id = ?',
          whereArgs: [id],
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
  
  /// Prüft ob ein oder mehrere Modelle existieren
  Future<bool> any({String? where, List<dynamic>? whereArgs}) async {
    final countResult = await count(where: where, whereArgs: whereArgs);
    return countResult > 0;
  }
  
  /// Holt das erste Modelle basierend auf Bedingungen
  Future<T?> first({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final results = await findWhere(
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }
  
  /// Holt das letzte Modelle basierend auf Bedingungen
  Future<T?> last({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final results = await findWhere(
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy ?? 'id DESC',
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }
}
