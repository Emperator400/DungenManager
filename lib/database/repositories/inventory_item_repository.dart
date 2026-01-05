import 'package:sqflite/sqflite.dart';
import '../core/database_connection.dart';
import '../core/database_entity.dart';
import '../entities/inventory_item_entity.dart';
import 'base_repository.dart';
import '../../models/equip_slot.dart';

/// Repository für InventoryItem-Entitäten
/// Erweitert BaseRepository mit spezialisierten Methoden für Inventar-Operationen
/// 
/// @deprecated Dieses Repository wird durch InventoryItemModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class InventoryItemRepository extends BaseRepository<InventoryItemEntity> {
  InventoryItemRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => InventoryItemEntity.tableName;

  @override
  DatabaseEntity<InventoryItemEntity> get entityFactory => InventoryItemEntityFactory();

  /// Findet Inventar-Items nach Character
  Future<List<InventoryItemEntity>> getByCharacterId(String characterId) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'is_equipped DESC, item_id ASC',
    );
    
    return List.generate(maps.length, (i) => entityFactory.fromDatabaseMap(maps[i]));
  }

  /// Findet ausgerüstete Items eines Characters
  Future<List<InventoryItemEntity>> getEquippedItems(String characterId) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'character_id = ? AND is_equipped = ?',
      whereArgs: [characterId, 1],
      orderBy: 'item_id ASC',
    );
    
    return List.generate(maps.length, (i) => entityFactory.fromDatabaseMap(maps[i]));
  }

  /// Findet nicht ausgerüstete Items eines Characters
  Future<List<InventoryItemEntity>> getUnequippedItems(String characterId) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'character_id = ? AND is_equipped = ?',
      whereArgs: [characterId, 0],
      orderBy: 'item_id ASC',
    );
    
    return List.generate(maps.length, (i) => entityFactory.fromDatabaseMap(maps[i]));
  }

  /// Findet favorisierte Items eines Characters
  Future<List<InventoryItemEntity>> getFavoriteItems(String characterId) async {
    final db = await connection.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'character_id = ? AND is_favorite = ?',
      whereArgs: [characterId, 1],
      orderBy: 'item_id ASC',
    );
    
    return List.generate(maps.length, (i) => entityFactory.fromDatabaseMap(maps[i]));
  }

  /// Sucht Inventar-Items mit komplexen Filtern
  Future<List<InventoryItemEntity>> searchInventoryItems({
    String? searchTerm,
    String? characterId,
    String? itemId,
    bool? isEquipped,
    bool? isFavorite,
    String? sourceType,
    int? limit,
    int? offset,
  }) async {
    final db = await connection.database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (characterId != null) {
      whereConditions.add('character_id = ?');
      whereArgs.add(characterId);
    }

    if (itemId != null) {
      whereConditions.add('item_id = ?');
      whereArgs.add(itemId);
    }

    if (isEquipped != null) {
      whereConditions.add('is_equipped = ?');
      whereArgs.add(isEquipped ? 1 : 0);
    }

    if (isFavorite != null) {
      whereConditions.add('is_favorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }

    if (sourceType != null) {
      whereConditions.add('source_type = ?');
      whereArgs.add(sourceType);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;
    final orderBy = 'is_equipped DESC, is_favorite DESC, item_id ASC';

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => entityFactory.fromDatabaseMap(maps[i]));
  }

  /// Rüstet ein Item aus (alle anderen Items im gleichen Slot ausrüsten)
  Future<void> equipItem(String inventoryItemId) async {
    final db = await connection.database;
    
    // Zuerst das aktuelle Inventar-Item laden
    final currentItem = await findById(inventoryItemId);
    if (currentItem == null) {
      throw Exception('Inventory item not found: $inventoryItemId');
    }
    
    // Alle Items des gleichen Characters im gleichen Slot ausrüsten
    final equipSlot = currentItem.equipSlot;
    if (equipSlot != null) {
      await db.update(
        tableName,
        {'is_equipped': 0},
        where: 'character_id = ? AND equip_slot = ? AND id != ?',
        whereArgs: [currentItem.characterId, equipSlot.toJson(), inventoryItemId],
      );
    }
    
    // Das gewünschte Item ausrüsten
    await db.update(
      tableName,
      {'is_equipped': 1},
      where: 'id = ?',
      whereArgs: [inventoryItemId],
    );
  }

  /// Legt ein Item ab
  Future<void> unequipItem(String inventoryItemId) async {
    final db = await connection.database;
    
    await db.update(
      tableName,
      {'is_equipped': 0},
      where: 'id = ?',
      whereArgs: [inventoryItemId],
    );
  }

  /// Alle Items eines Characters ausrüsten
  Future<void> unequipAllItems(String characterId) async {
    final db = await connection.database;
    
    await db.update(
      tableName,
      {'is_equipped': 0},
      where: 'character_id = ?',
      whereArgs: [characterId],
    );
  }

  /// Aktualisiert die Menge eines Inventar-Items
  Future<void> updateQuantity(String inventoryItemId, int newQuantity) async {
    final db = await connection.database;
    
    if (newQuantity <= 0) {
      // Wenn Menge 0 ist, Item löschen
      await delete(inventoryItemId);
    } else {
      await db.update(
        tableName,
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [inventoryItemId],
      );
    }
  }

  /// Aktualisiert die Haltbarkeit eines Inventar-Items
  Future<void> updateDurability(String inventoryItemId, int newDurability) async {
    final db = await connection.database;
    
    await db.update(
      tableName,
      {'current_durability': newDurability},
      where: 'id = ?',
      whereArgs: [inventoryItemId],
    );
  }

  /// Schaltet den Favoriten-Status um
  Future<void> toggleFavorite(String inventoryItemId) async {
    final db = await connection.database;
    
    final item = await findById(inventoryItemId);
    if (item == null) return;
    
    await db.update(
      tableName,
      {'is_favorite': !item.isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [inventoryItemId],
    );
  }

  /// Aktualisiert die Notizen eines Inventar-Items
  Future<void> updateNotes(String inventoryItemId, String notes) async {
    final db = await connection.database;
    
    await db.update(
      tableName,
      {'custom_notes': notes},
      where: 'id = ?',
      whereArgs: [inventoryItemId],
    );
  }

  /// Statistiken für Inventar eines Characters
  Future<Map<String, dynamic>> getInventoryStatistics(String characterId) async {
    final db = await connection.database;
    
    // Gesamtzahl der Items
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(quantity) as total_quantity FROM $tableName WHERE character_id = ?',
      [characterId]
    );
    final totalCount = totalResult.first['count'] as int;
    final totalQuantity = totalResult.first['total_quantity'] as int? ?? 0;
    
    // Ausgerüstete Items
    final equippedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE character_id = ? AND is_equipped = 1',
      [characterId]
    );
    final equippedCount = equippedResult.first['count'] as int;
    
    // Favorisierte Items
    final favoriteResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE character_id = ? AND is_favorite = 1',
      [characterId]
    );
    final favoriteCount = favoriteResult.first['count'] as int;
    
    // Items nach Source-Type
    final sourceTypeResult = await db.rawQuery(
      'SELECT source_type, COUNT(*) as count FROM $tableName WHERE character_id = ? GROUP BY source_type ORDER BY count DESC',
      [characterId]
    );
    final sourceTypeDistribution = sourceTypeResult;
    
    return {
      'totalItems': totalCount,
      'totalQuantity': totalQuantity,
      'equippedItems': equippedCount,
      'unequippedItems': totalCount - equippedCount,
      'favoriteItems': favoriteCount,
      'sourceTypeDistribution': sourceTypeDistribution,
    };
  }

  /// Batch-Operationen für Inventar-Items
  Future<List<InventoryItemEntity>> createAll(List<InventoryItemEntity> items) async {
    final results = <InventoryItemEntity>[];
    final db = await connection.database;
    
    final batch = db.batch();
    
    for (final item in items) {
      batch.insert(
        tableName, 
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    final resultsList = await batch.commit();
    
    for (int i = 0; i < items.length; i++) {
      if (resultsList[i] != null) {
        final id = resultsList[i] as int;
        final item = items[i].copyWith(id: id.toString());
        results.add(item);
      }
    }
    
    return results;
  }

  /// Löscht alle Inventar-Items eines Characters
  Future<void> deleteByCharacterId(String characterId) async {
    final db = await connection.database;
    
    await db.delete(
      tableName,
      where: 'character_id = ?',
      whereArgs: [characterId],
    );
  }
}

/// Entity Factory für InventoryItemEntity
class InventoryItemEntityFactory extends DatabaseEntity<InventoryItemEntity> {
  InventoryItemEntityFactory();

  @override
  InventoryItemEntity fromDatabaseMap(Map<String, dynamic> map) {
    return InventoryItemEntity.fromMap(map);
  }

  @override
  Map<String, dynamic> toDatabaseMap() {
    // Placeholder - wird in der Praxis nicht verwendet
    return {};
  }

  @override
  String get tableName => InventoryItemEntity.tableName;

  @override
  List<String> get databaseFields => [
    'id', 'character_id', 'item_id', 'quantity', 'is_equipped', 'equip_slot',
    'current_durability', 'custom_notes', 'is_favorite', 'acquired_at', 'source_type'
  ];

  @override
  bool get isValid => true;

  @override
  List<String> get validationErrors => [];

  @override
  List<String> get createTableSql => [InventoryItemEntity.createTableSql()];
}
