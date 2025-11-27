// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/inventory_item.dart';
import '../models/item.dart';
import '../models/equip_slot.dart';
import '../models/creature.dart';
import '../models/player_character.dart';
import '../database/database_helper.dart';
import 'exceptions/service_exceptions.dart';
import 'uuid_service.dart';
import 'creature_helper_service.dart';

/// Service für alle Inventory Business-Logik
/// entfernt direkte Datenbankzugriffe aus UI-Components
/// Verwendet spezifische Exceptions und ServiceResult Pattern.
class InventoryService {
  final DatabaseHelper _dbHelper;
  final UuidService _uuidService;

  InventoryService({
    DatabaseHelper? dbHelper,
    UuidService? uuidService,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _uuidService = uuidService ?? UuidService();

  // ============================================================================
  // INVENTORY MANAGEMENT
  // ============================================================================

  /// Lädt das Inventar für einen Character (PC oder Creature)
  Future<List<InventoryItem>> loadInventory(String ownerId) async {
    return performServiceOperation('loadInventory', () async {
      if (ownerId.isEmpty) {
        throw ValidationException(
          'Owner ID ist erforderlich',
          operation: 'loadInventory',
        );
      }

      final db = await _dbHelper.database;
      final maps = await db.query(
        'inventory_items',
        where: 'owner_id = ? OR ownerId = ?',
        whereArgs: [ownerId, ownerId],
        orderBy: 'is_equipped DESC, item_id ASC',
      );
      return maps.map((map) => InventoryItem.fromMap(map)).toList();
    }).then((result) => result.isSuccess ? result.data! : throw DatabaseException(
         result.hasErrors ? result.errors.first : 'Unbekannter Fehler',
         operation: 'loadInventory',
       ));
  }

  /// Fügt ein Item zum Inventar hinzu
  Future<void> addItemToInventory({
    required String ownerId,
    required String itemId,
    required int quantity,
    EquipSlot? equipSlot,
  }) async {
    try {
      final inventoryItem = InventoryItem(
        id: _uuidService.generateId(),
        ownerId: ownerId,
        itemId: itemId,
        quantity: quantity,
        isEquipped: equipSlot != null,
        equipSlot: equipSlot,
      );

      final db = await _dbHelper.database;
      await db.insert('inventory_items', inventoryItem.toMap());
    } catch (e) {
      throw Exception('Fehler beim Hinzufügen des Items: $e');
    }
  }

  /// Aktualisiert die Menge eines Inventar-Items
  Future<void> updateItemQuantity({
    required String inventoryItemId,
    required String ownerId,
    required int newQuantity,
  }) async {
    if (newQuantity <= 0) {
      await removeItem(inventoryItemId);
      return;
    }

    try {
      final inventoryItems = await loadInventory(ownerId);
      final currentItem = inventoryItems.firstWhere((item) => item.id == inventoryItemId);
      
      final updatedItem = currentItem.copyWith(quantity: newQuantity);
      
      final db = await _dbHelper.database;
      await db.update(
        'inventory_items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [inventoryItemId],
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren der Menge: $e');
    }
  }

  /// Entfernt ein Item aus dem Inventar
  Future<void> removeItem(String inventoryItemId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('inventory_items', where: 'id = ?', whereArgs: [inventoryItemId]);
    } catch (e) {
      throw Exception('Fehler beim Entfernen des Items: $e');
    }
  }

  // ============================================================================
  // EQUIPMENT MANAGEMENT
  // ============================================================================

  /// Rüstet ein Item aus
  Future<void> equipItem({
    required String inventoryItemId,
    required String ownerId,
    required EquipSlot equipSlot,
  }) async {
    try {
      // Inventory Item holen
      final inventoryItems = await loadInventory(ownerId);
      final inventoryItem = inventoryItems.firstWhere((item) => item.id == inventoryItemId);
      
      // Item-Daten holen
      final item = await getItemById(inventoryItem.itemId);
      if (item == null) {
        throw Exception('Item-Daten nicht gefunden');
      }

      // Prüfen, ob bereits etwas im Slot ausgerüstet ist
      await _unequipSlot(ownerId, equipSlot);

      // Item ausrüsten
      final updatedItem = inventoryItem.copyWith(
        isEquipped: true,
        equipSlot: equipSlot,
      );

      final db = await _dbHelper.database;
      await db.update(
        'inventory_items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [inventoryItemId],
      );
    } catch (e) {
      throw Exception('Fehler beim Ausrüsten: $e');
    }
  }

  /// Legt ein Item ab (unequip)
  Future<void> unequipItem(String inventoryItemId, String ownerId) async {
    try {
      final inventoryItems = await loadInventory(ownerId);
      final inventoryItem = inventoryItems.firstWhere((item) => item.id == inventoryItemId);

      final updatedItem = inventoryItem.copyWith(
        isEquipped: false,
        equipSlot: null,
      );

      final db = await _dbHelper.database;
      await db.update(
        'inventory_items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [inventoryItemId],
      );
    } catch (e) {
      throw Exception('Fehler beim Ablegen: $e');
    }
  }

  /// Legt alle Items in einem bestimmten Slot ab
  Future<void> _unequipSlot(String ownerId, EquipSlot equipSlot) async {
    try {
      final inventoryItems = await loadInventory(ownerId);
      
      for (final item in inventoryItems) {
        if (item.equipSlot == equipSlot && item.isEquipped) {
          await unequipItem(item.id, ownerId);
        }
      }
    } catch (e) {
      // Wenn Fehler beim Ablegen, fortfahren - nicht kritisch
      print('Warnung: Fehler beim Ablegen von Items in Slot $equipSlot: $e');
    }
  }

  // ============================================================================
  // INVENTORY ANALYSIS
  // ============================================================================

  /// Trennt ausgerüstete von nicht ausgerüsteten Items
  ({List<InventoryItem> equipped, List<InventoryItem> unequipped}) 
      separateEquippedItems(List<InventoryItem> items) {
    final equipped = <InventoryItem>[];
    final unequipped = <InventoryItem>[];

    for (final item in items) {
      if (item.isEquipped) {
        equipped.add(item);
      } else {
        unequipped.add(item);
      }
    }

    return (equipped: equipped, unequipped: unequipped);
  }

  /// Gibt alle verfügbaren Equip-Slots für ein Item zurück
  List<EquipSlot> getAvailableEquipSlots(Item item) {
    return EquipSlot.values.where((slot) => 
        slot.allowedItemTypes.contains(item.itemType.toString())
    ).toList();
  }

  /// Prüft, ob ein Item ausgerüstet werden kann
  Future<bool> canEquipItem(Item item, EquipSlot equipSlot) async {
    try {
      // Vereinfachte Logik - prüfen ob der Slot für den Item-Typ geeignet ist
      return equipSlot.allowedItemTypes.contains(item.itemType.toString());
    } catch (e) {
      return false;
    }
  }

  /// Berechnet das Gesamtgewicht des Inventars
  double calculateTotalWeight(List<InventoryItem> items, List<Item> allItems) {
    return items.fold(0.0, (total, inventoryItem) {
      final item = allItems.firstWhere((item) => item.id == inventoryItem.itemId, 
          orElse: () => Item(id: '', name: '', weight: 0.0, itemType: ItemType.Armor));
      final itemWeight = item.weight;
      final quantity = inventoryItem.quantity;
      return total + (itemWeight * quantity);
    });
  }

  /// Zählt Items nach Typ
  Map<String, int> countItemsByType(List<InventoryItem> items, List<Item> allItems) {
    final counts = <String, int>{};
    
    for (final inventoryItem in items) {
      final item = allItems.firstWhere((item) => item.id == inventoryItem.itemId, 
          orElse: () => Item(id: '', name: '', weight: 0.0, itemType: ItemType.Armor));
      final type = item.itemType.toString();
      counts[type] = (counts[type] ?? 0) + inventoryItem.quantity;
    }
    
    return counts;
  }

  // ============================================================================
  // ITEM DATA ACCESS
  // ============================================================================

  /// Holt ein Item anhand seiner ID
  Future<Item?> getItemById(String itemId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('items', where: 'id = ?', whereArgs: [itemId]);
      if (maps.isNotEmpty) {
        return Item.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Holt alle Items
  Future<List<Item>> getAllItems() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('items', orderBy: 'name ASC');
      return maps.map((map) => Item.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // GOLD MANAGEMENT (für NPCs/Monster)
  // ============================================================================

  /// Aktualisiert das Gold einer Kreatur
  Future<void> updateCreatureGold({
    required String creatureId,
    required double gold,
  }) async {
    try {
      final creature = await getCreatureById(creatureId);
      if (creature == null) {
        throw Exception('Kreatur nicht gefunden');
      }

      // Verwende die CreatureHelperService.copyWith Methode
      final updatedCreature = CreatureHelperService.copyWith(creature, gold: gold);
      
      final db = await _dbHelper.database;
      await db.update(
        'creatures',
        updatedCreature.toMap(),
        where: 'id = ?',
        whereArgs: [creatureId],
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Goldes: $e');
    }
  }

  /// Aktualisiert das Gold eines Player Characters
  Future<void> updatePlayerGold({
    required String playerId,
    required double gold,
  }) async {
    try {
      final player = await getPlayerCharacterById(playerId);
      if (player == null) {
        throw Exception('Player Character nicht gefunden');
      }

      final updatedPlayer = player.copyWith(
        gold: gold,
        silver: player.silver,
        copper: player.copper,
      );
      
      final db = await _dbHelper.database;
      await db.update(
        'player_characters',
        updatedPlayer.toMap(),
        where: 'id = ?',
        whereArgs: [playerId],
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Goldes: $e');
    }
  }

  // ============================================================================
  // CREATURE/PLAYER DATA ACCESS
  // ============================================================================

  /// Holt eine Kreatur anhand ihrer ID
  Future<Creature?> getCreatureById(String creatureId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('creatures', where: 'id = ?', whereArgs: [creatureId]);
      if (maps.isNotEmpty) {
        return Creature.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Holt einen Player Character anhand seiner ID
  Future<PlayerCharacter?> getPlayerCharacterById(String playerId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('player_characters', where: 'id = ?', whereArgs: [playerId]);
      if (maps.isNotEmpty) {
        return PlayerCharacter.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================

  /// Validiert Inventar-Operationen
  void _validateInventoryOperation(String ownerId, String itemId) {
    if (ownerId.isEmpty) {
      throw ArgumentError('Owner ID ist erforderlich');
    }
    
    if (itemId.isEmpty) {
      throw ArgumentError('Item ID ist erforderlich');
    }
  }

  /// Validiert Menge
  void _validateQuantity(int quantity) {
    if (quantity < 0) {
      throw ArgumentError('Menge darf nicht negativ sein');
    }
    
    if (quantity > 9999) {
      throw ArgumentError('Menge darf 9999 nicht überschreiten');
    }
  }
}
