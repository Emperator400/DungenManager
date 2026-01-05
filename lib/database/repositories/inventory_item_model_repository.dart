import '../core/database_connection.dart';
import '../../models/inventory_item.dart';
import 'model_repository.dart';

/// Repository für InventoryItem Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem InventoryItem Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.

class InventoryItemModelRepository extends ModelRepository<InventoryItem> {
  InventoryItemModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'inventory_items';

  @override
  Map<String, dynamic> toDatabaseMap(InventoryItem item) {
    return item.toDatabaseMap();
  }

  @override
  InventoryItem fromDatabaseMap(Map<String, dynamic> map) {
    return InventoryItem.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Items nach Owner ID (Character oder Creature)
  Future<List<InventoryItem>> getByOwnerId(String ownerId) async {
    return await findWhere(
      where: 'character_id = ?',
      whereArgs: [ownerId],
      orderBy: 'name ASC',
    );
  }

  /// Findet Items nach Character ID
  Future<List<InventoryItem>> findByCharacter(String characterId) async {
    return await getByOwnerId(characterId);
  }

  /// Findet ausgerüstete Items eines Characters
  Future<List<InventoryItem>> findEquippedByCharacter(String characterId) async {
    return await findWhere(
      where: 'character_id = ? AND is_equipped = ?',
      whereArgs: [characterId, 1],
      orderBy: 'name ASC',
    );
  }

  /// Findet Items nach EquipSlot
  Future<List<InventoryItem>> findByEquipSlot(String characterId, String slotName) async {
    return await findWhere(
      where: 'character_id = ? AND equip_slot LIKE ?',
      whereArgs: [characterId, '%"$slotName"%'],
      orderBy: 'name ASC',
    );
  }

  /// Sucht Items mit komplexen Filtern
  Future<List<InventoryItem>> searchItems({
    String? characterId,
    String? searchTerm,
    bool? isEquipped,
    String? itemType,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (characterId != null) {
      whereConditions.add('character_id = ?');
      whereArgs.add(characterId);
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR description LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%']);
    }

    if (isEquipped != null) {
      whereConditions.add('is_equipped = ?');
      whereArgs.add(isEquipped ? 1 : 0);
    }

    if (itemType != null) {
      whereConditions.add('item_type = ?');
      whereArgs.add(itemType);
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== ITEM-OPERATIONEN =====

  /// Toggle Equipment Status eines Items
  Future<void> toggleEquipment(String itemId) async {
    final item = await findById(itemId);
    if (item != null) {
      final updatedItem = item.copyWith(isEquipped: !item.isEquipped);
      await update(updatedItem);
    }
  }

  /// Setzt Equipment Status eines Items
  Future<void> setEquipment(String itemId, bool isEquipped) async {
    final item = await findById(itemId);
    if (item != null) {
      final updatedItem = item.copyWith(isEquipped: isEquipped);
      await update(updatedItem);
    }
  }

  /// ===== ADVANCED SUCHEN =====

  /// Items nach Namen suchen
  Future<List<InventoryItem>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
  }
}
