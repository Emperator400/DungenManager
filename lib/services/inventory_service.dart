// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/inventory_item.dart';
import '../models/item.dart';
import '../models/equip_slot.dart';
import '../models/creature.dart';
import '../models/player_character.dart';
import '../database/repositories/inventory_item_model_repository.dart';
import '../database/repositories/item_model_repository.dart';
import '../database/repositories/creature_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/core/database_connection.dart';
import 'exceptions/service_exceptions.dart';
import 'uuid_service.dart';
import 'creature_helper_service.dart';

/// Service für alle Inventory Business-Logik
/// entfernt direkte Datenbankzugriffe aus UI-Components
/// Verwendet spezifische Exceptions und ServiceResult Pattern.
class InventoryService {
  final InventoryItemModelRepository _inventoryRepository;
  final ItemModelRepository _itemRepository;
  final CreatureModelRepository _creatureRepository;
  final PlayerCharacterModelRepository _playerCharacterRepository;
  final UuidService _uuidService;

  InventoryService({
    InventoryItemModelRepository? inventoryRepository,
    ItemModelRepository? itemRepository,
    CreatureModelRepository? creatureRepository,
    PlayerCharacterModelRepository? playerCharacterRepository,
    UuidService? uuidService,
  }) : _inventoryRepository = inventoryRepository ?? InventoryItemModelRepository(DatabaseConnection.instance),
       _itemRepository = itemRepository ?? ItemModelRepository(DatabaseConnection.instance),
       _creatureRepository = creatureRepository ?? CreatureModelRepository(DatabaseConnection.instance),
       _playerCharacterRepository = playerCharacterRepository ?? PlayerCharacterModelRepository(DatabaseConnection.instance),
       _uuidService = uuidService ?? UuidService();

  // ============================================================================
  // INVENTORY MANAGEMENT
  // ============================================================================

  /// Lädt das Inventar für einen Character (PC oder Creature) über neues Repository
  Future<List<InventoryItem>> loadInventory(String characterId) async {
    try {
      if (characterId.isEmpty) {
        throw ValidationException(
          'Character ID ist erforderlich',
          operation: 'loadInventory',
        );
      }

      return await _inventoryRepository.getByOwnerId(characterId);
    } catch (e) {
      throw Exception('Fehler beim Laden des Inventars: $e');
    }
  }

  /// Fügt ein Item zum Inventar hinzu über neues Repository
  Future<void> addItemToInventory({
    required String characterId,
    required String itemId,
    required int quantity,
    EquipSlot? equipSlot,
  }) async {
    try {
      // Item-Daten laden, um name und description zu erhalten
      final item = await _itemRepository.findById(itemId);
      if (item == null) {
        throw Exception('Item mit ID $itemId nicht gefunden');
      }

      final inventoryItem = InventoryItem(
        id: _uuidService.generateId(),
        characterId: characterId,
        itemId: itemId,
        name: item.name, // Name aus Item übernehmen
        description: item.description, // Beschreibung aus Item übernehmen
        quantity: quantity,
        isEquipped: equipSlot != null,
        equipSlot: equipSlot,
      );

      await _inventoryRepository.create(inventoryItem);
    } catch (e) {
      throw Exception('Fehler beim Hinzufügen des Items: $e');
    }
  }

  /// Aktualisiert die Menge eines Inventar-Items über neues Repository
  Future<void> updateItemQuantity({
    required String inventoryItemId,
    required String characterId,
    required int newQuantity,
  }) async {
    if (newQuantity <= 0) {
      await removeItem(inventoryItemId);
      return;
    }

    try {
      final inventoryItems = await _inventoryRepository.getByOwnerId(characterId);
      final currentItem = inventoryItems.firstWhere((item) => item.id == inventoryItemId);
      
      final updatedItem = currentItem.copyWith(quantity: newQuantity);
      await _inventoryRepository.update(updatedItem);
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren der Menge: $e');
    }
  }

  /// Entfernt ein Item aus dem Inventar über neues Repository
  Future<void> removeItem(String inventoryItemId) async {
    try {
      await _inventoryRepository.delete(inventoryItemId);
    } catch (e) {
      throw Exception('Fehler beim Entfernen des Items: $e');
    }
  }

  // ============================================================================
  // EQUIPMENT MANAGEMENT
  // ============================================================================

  /// Rüstet ein Item aus über neues Repository
  Future<void> equipItem({
    required String inventoryItemId,
    required String characterId,
    required EquipSlot equipSlot,
  }) async {
    try {
      // Inventory Item holen
      final inventoryItems = await loadInventory(characterId);
      final inventoryItem = inventoryItems.firstWhere((item) => item.id == inventoryItemId);
      
      // Item-Daten holen
      final item = await getItemById(inventoryItem.itemId);
      if (item == null) {
        throw Exception('Item-Daten nicht gefunden');
      }

      // Prüfen, ob bereits etwas im Slot ausgerüstet ist
      await _unequipSlot(characterId, equipSlot);

      // Item ausrüsten
      final updatedItem = inventoryItem.copyWith(
        isEquipped: true,
        equipSlot: equipSlot,
      );

      await _inventoryRepository.update(updatedItem);
    } catch (e) {
      throw Exception('Fehler beim Ausrüsten: $e');
    }
  }

  /// Legt ein Item ab (unequip) über neues Repository
  Future<void> unequipItem(String inventoryItemId, String characterId) async {
    try {
      final inventoryItems = await loadInventory(characterId);
      final inventoryItem = inventoryItems.firstWhere((item) => item.id == inventoryItemId);

      final updatedItem = inventoryItem.copyWith(
        isEquipped: false,
        equipSlot: null,
      );

      await _inventoryRepository.update(updatedItem);
    } catch (e) {
      throw Exception('Fehler beim Ablegen: $e');
    }
  }

  /// Legt alle Items in einem bestimmten Slot ab
  Future<void> _unequipSlot(String characterId, EquipSlot equipSlot) async {
    try {
      final inventoryItems = await loadInventory(characterId);
      
      for (final item in inventoryItems) {
        if (item.equipSlot == equipSlot && item.isEquipped) {
          await unequipItem(item.id, characterId);
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

  /// Holt ein Item anhand seiner ID über neues Repository
  Future<Item?> getItemById(String itemId) async {
    try {
      return await _itemRepository.findById(itemId);
    } catch (e) {
      return null;
    }
  }

  /// Holt alle Items über neues Repository
  Future<List<Item>> getAllItems() async {
    try {
      return await _itemRepository.findAll();
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // GOLD MANAGEMENT (für NPCs/Monster)
  // ============================================================================

  /// Aktualisiert das Gold einer Kreatur über neues Repository
  Future<void> updateCreatureGold({
    required String creatureId,
    required double gold,
  }) async {
    try {
      final creature = await _creatureRepository.findById(creatureId);
      if (creature == null) {
        throw Exception('Kreatur nicht gefunden');
      }

      // Verwende die CreatureHelperService.copyWith Methode
      final updatedCreature = CreatureHelperService.copyWith(creature, gold: gold);
      
      await _creatureRepository.update(updatedCreature);
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Goldes: $e');
    }
  }

  /// Aktualisiert das Gold eines Player Characters über neues Repository
  Future<void> updatePlayerGold({
    required String playerId,
    required double gold,
  }) async {
    try {
      final player = await _playerCharacterRepository.findById(playerId);
      if (player == null) {
        throw Exception('Player Character nicht gefunden');
      }

      final updatedPlayer = player.copyWith(
        gold: gold,
        silver: player.silver,
        copper: player.copper,
      );
      
      await _playerCharacterRepository.update(updatedPlayer);
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Goldes: $e');
    }
  }

  // ============================================================================
  // CREATURE/PLAYER DATA ACCESS
  // ============================================================================

  /// Holt eine Kreatur anhand ihrer ID über neues Repository
  Future<Creature?> getCreatureById(String creatureId) async {
    try {
      return await _creatureRepository.findById(creatureId);
    } catch (e) {
      return null;
    }
  }

  /// Holt einen Player Character anhand seiner ID über neues Repository
  Future<PlayerCharacter?> getPlayerCharacterById(String playerId) async {
    try {
      return await _playerCharacterRepository.findById(playerId);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================

  /// Validiert Inventar-Operationen
  void _validateInventoryOperation(String characterId, String itemId) {
    if (characterId.isEmpty) {
      throw ArgumentError('Character ID ist erforderlich');
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
