import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/player_character.dart';
import '../models/creature.dart';
import '../models/inventory_item.dart';
import '../models/item.dart';
import '../models/equip_slot.dart';
import '../models/attack.dart';
import '../services/character_editor_service.dart';
import '../services/inventory_service.dart';
import '../services/uuid_service.dart';
import '../database/database_helper.dart';

/// ViewModel für den Character Editor
/// Zentralisiert State Management und Business-Logik
class CharacterEditorViewModel extends ChangeNotifier {
  final CharacterEditorService _characterService;
  final InventoryService _inventoryService;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // Character Daten
  PlayerCharacter? _playerCharacter;
  Creature? _creature;
  bool _isPlayerCharacter = true;
  bool _isLoading = false;
  String? _error;

  // Inventar Daten
  List<InventoryItem> _inventory = [];
  Map<String, Item> _itemDetails = {};
  List<InventoryItem> _displayInventory = [];
  double _totalWeight = 0;

  // Angriffsdaten
  List<Attack> _attacks = [];

  // ============================================================================
  // GETTERS
  // ============================================================================

  PlayerCharacter? get playerCharacter => _playerCharacter;
  Creature? get creature => _creature;
  bool get isPlayerCharacter => _isPlayerCharacter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<InventoryItem> get inventory => _inventory;
  Map<String, Item> get itemDetails => _itemDetails;
  List<InventoryItem> get displayInventory => _displayInventory;
  double get totalWeight => _totalWeight;
  
  List<Attack> get attacks => _attacks;

  // Helper Getters
  String get characterName => _isPlayerCharacter ? _playerCharacter?.name ?? '' : _creature?.name ?? '';
  int get currentHp => _isPlayerCharacter ? _playerCharacter?.maxHp ?? 0 : _creature?.currentHp ?? 0;
  int get maxHp => _isPlayerCharacter ? _playerCharacter?.maxHp ?? 0 : _creature?.maxHp ?? 0;
  int get armorClass => _isPlayerCharacter ? _playerCharacter?.armorClass ?? 10 : _creature?.armorClass ?? 10;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  CharacterEditorViewModel({
    CharacterEditorService? characterService,
    InventoryService? inventoryService,
  }) : _characterService = characterService ?? CharacterEditorService(),
       _inventoryService = inventoryService ?? InventoryService();

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialisiert den ViewModel mit einem Player Character
  Future<void> initWithPlayerCharacter(String characterId) async {
    await _executeWithErrorHandling(() async {
      _isPlayerCharacter = true;
      final db = DatabaseHelper.instance;
      _playerCharacter = await db.getPlayerCharacterById(characterId);
      await _loadCharacterData();
    });
  }

  /// Initialisiert den ViewModel mit einer Kreatur
  Future<void> initWithCreature(String creatureId) async {
    await _executeWithErrorHandling(() async {
      _isPlayerCharacter = false;
      final db = DatabaseHelper.instance;
      _creature = await db.getCreatureById(creatureId);
      await _loadCharacterData();
    });
  }

  /// Lädt alle Character-Daten (Inventar, Angriffe, etc.)
  Future<void> _loadCharacterData() async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    // Inventar laden
    try {
      _displayInventory = await _inventoryService.loadInventory(characterId);
      _inventory = List.from(_displayInventory);
    } catch (e) {
      debugPrint('Fehler beim Laden des Inventars: $e');
      _displayInventory = [];
      _inventory = [];
    }
    
    // Item-Daten laden für schnelleren Zugriff
    _itemDetails = {};
    for (final inventoryItem in _displayInventory) {
      final item = await _getItemDetails(inventoryItem.itemId);
      if (item != null) {
        _itemDetails[inventoryItem.itemId] = item;
      }
    }
    
    // Gesamtgewicht berechnen
    try {
      final items = _displayInventory.map((invItem) => _itemDetails[invItem.itemId]).where((item) => item != null).cast<Item>().toList();
      _totalWeight = _inventoryService.calculateTotalWeight(_displayInventory, items);
    } catch (e) {
      debugPrint('Fehler beim Berechnen des Gewichts: $e');
      _totalWeight = 0;
    }
    
    // Angriffe laden
    _attacks = _isPlayerCharacter 
        ? _playerCharacter?.attackList ?? []
        : _creature?.attackList ?? [];
    
    notifyListeners();
  }

  /// Holt Item-Details aus der Datenbank
  Future<Item?> _getItemDetails(String itemId) async {
    try {
      final db = DatabaseHelper.instance;
      final itemMaps = await db.database.then((db) => 
        db.query('items', where: 'id = ?', whereArgs: [itemId]));
      if (itemMaps.isNotEmpty) {
        return Item.fromMap(itemMaps.first);
      }
    } catch (e) {
      debugPrint('Fehler beim Laden von Item $itemId: $e');
    }
    return null;
  }

  // ============================================================================
  // CHARACTER MANAGEMENT
  // ============================================================================

  /// Aktualisiert den Character
  Future<void> updateCharacter() async {
    if (_isPlayerCharacter && _playerCharacter != null) {
      await _executeWithErrorHandling(() async {
        await _characterService.updatePlayerCharacter(_playerCharacter!);
      });
    } else if (!_isPlayerCharacter && _creature != null) {
      await _executeWithErrorHandling(() async {
        await _characterService.updateCreature(_creature!);
      });
    }
  }

  /// Speichert alle Änderungen
  Future<void> saveAll() async {
    await _executeWithErrorHandling(() async {
      if (_isPlayerCharacter && _playerCharacter != null) {
        // Inventar zum Character hinzufügen
        final updatedCharacter = _playerCharacter!.copyWith(
          inventory: _inventory,
          attackList: _attacks,
        );
        await _characterService.updatePlayerCharacter(updatedCharacter);
        _playerCharacter = updatedCharacter;
      } else if (!_isPlayerCharacter && _creature != null) {
        // Inventar zur Kreatur hinzufügen
        final updatedCreature = _creature!.copyWith(
          attackList: _attacks,
        );
        await _characterService.updateCreature(updatedCreature);
        _creature = updatedCreature;
      }
    });
  }

  // ============================================================================
  // INVENTORY MANAGEMENT
  // ============================================================================

  /// Fügt ein Item zum Inventar hinzu
  Future<void> addItem({
    required String itemId,
    required int quantity,
    EquipSlot? equipSlot,
  }) async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    await _executeWithErrorHandling(() async {
      await _inventoryService.addItemToInventory(
        ownerId: characterId,
        itemId: itemId,
        quantity: quantity,
        equipSlot: equipSlot,
      );
      await _loadCharacterData(); // Daten neu laden
    });
  }

  /// Entfernt ein Item aus dem Inventar
  Future<void> removeItem(String inventoryItemId) async {
    await _executeWithErrorHandling(() async {
      await _inventoryService.removeItem(inventoryItemId);
      await _loadCharacterData(); // Daten neu laden
    });
  }

  /// Aktualisiert die Menge eines Items
  Future<void> updateItemQuantity(String inventoryItemId, int newQuantity) async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    await _executeWithErrorHandling(() async {
      await _inventoryService.updateItemQuantity(
        inventoryItemId: inventoryItemId,
        ownerId: characterId,
        newQuantity: newQuantity,
      );
      await _loadCharacterData(); // Daten neu laden
    });
  }

  /// Rüstet ein Item aus
  Future<void> equipItem(String inventoryItemId, EquipSlot equipSlot) async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    await _executeWithErrorHandling(() async {
      await _inventoryService.equipItem(
        inventoryItemId: inventoryItemId,
        ownerId: characterId,
        equipSlot: equipSlot,
      );
      await _loadCharacterData(); // Daten neu laden
    });
  }

  /// Legt ein Item ab
  Future<void> unequipItem(String inventoryItemId) async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    await _executeWithErrorHandling(() async {
      await _inventoryService.unequipItem(inventoryItemId, characterId);
      await _loadCharacterData(); // Daten neu laden
    });
  }

  // ============================================================================
  // ATTACK MANAGEMENT
  // ============================================================================

  /// Fügt einen Angriff hinzu
  void addAttack(Attack attack) {
    _attacks.add(attack);
    notifyListeners();
  }

  /// Entfernt einen Angriff
  void removeAttack(Attack attack) {
    _attacks.remove(attack);
    notifyListeners();
  }

  /// Aktualisiert einen Angriff
  void updateAttack(Attack oldAttack, Attack newAttack) {
    final index = _attacks.indexOf(oldAttack);
    if (index != -1) {
      _attacks[index] = newAttack;
      notifyListeners();
    }
  }

  // ============================================================================
  // CHARACTER UPDATES (direct state updates)
  // ============================================================================

  /// Aktualisiert den Character-Namen
  void updateName(String name) {
    if (_isPlayerCharacter && _playerCharacter != null) {
      _playerCharacter = _playerCharacter!.copyWith(name: name);
    } else if (!_isPlayerCharacter && _creature != null) {
      _creature = _creature!.copyWith(name: name);
    }
    notifyListeners();
  }

  /// Aktualisiert die aktuellen HP
  void updateCurrentHp(int hp) {
    if (!_isPlayerCharacter && _creature != null) {
      _creature = _creature!.copyWith(currentHp: hp);
      notifyListeners();
    }
  }

  /// Aktualisiert die maximale HP
  void updateMaxHp(int hp) {
    if (_isPlayerCharacter && _playerCharacter != null) {
      _playerCharacter = _playerCharacter!.copyWith(maxHp: hp);
    } else if (!_isPlayerCharacter && _creature != null) {
      _creature = _creature!.copyWith(maxHp: hp, currentHp: hp); // Reset current HP
    }
    notifyListeners();
  }

  /// Aktualisiert die Armor Class
  void updateArmorClass(int ac) {
    if (_isPlayerCharacter && _playerCharacter != null) {
      _playerCharacter = _playerCharacter!.copyWith(armorClass: ac);
    } else if (!_isPlayerCharacter && _creature != null) {
      _creature = _creature!.copyWith(armorClass: ac);
    }
    notifyListeners();
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Trennt ausgerüstete von nicht ausgerüsteten Items
  ({List<InventoryItem> equipped, List<InventoryItem> unequipped}) 
      get equippedAndUnequippedItems {
    final equipped = <InventoryItem>[];
    final unequipped = <InventoryItem>[];
    
    for (final item in _displayInventory) {
      if (item.isEquipped) {
        equipped.add(item);
      } else {
        unequipped.add(item);
      }
    }
    
    return (equipped: equipped, unequipped: unequipped);
  }

  /// Holt Item-Details für eine Item ID
  Item? getItemDetails(String itemId) {
    return _itemDetails[itemId];
  }

  /// Prüft, ob ein Item ausgerüstet werden kann
  Future<bool> canEquipItem(Item item, EquipSlot slot) async {
    return await _inventoryService.canEquipItem(item, slot);
  }

  /// Holt verfügbare Equip-Slots für ein Item
  List<EquipSlot> getAvailableEquipSlots(Item item) {
    return _inventoryService.getAvailableEquipSlots(item);
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Führt eine Operation mit Error Handling durch
  Future<void> _executeWithErrorHandling(Future<void> Function() operation) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await operation();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Löscht den Fehler-Zustand
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================================
  // FORM SAVE METHODS (for EnhancedCharacterEditorController)
  // ============================================================================

  /// Speichert einen Player Character mit Formulardaten
  Future<void> savePlayerCharacter(Map<String, dynamic> characterData, String campaignId) async {
    await _executeWithErrorHandling(() async {
      // Player Character aus Formulardaten erstellen
      final playerCharacter = PlayerCharacter(
        id: _playerCharacter?.id ?? UuidService().generateId(),
        campaignId: campaignId,
        name: (characterData['name'] as String?) ?? 'Unbenannt',
        playerName: (characterData['playerName'] as String?) ?? 'Unbekannt',
        className: (characterData['className'] as String?) ?? '',
        raceName: (characterData['raceName'] as String?) ?? '',
        level: (characterData['level'] as int?) ?? 1,
        maxHp: (characterData['maxHp'] as int?) ?? 10,
        armorClass: (characterData['armorClass'] as int?) ?? 10,
        initiativeBonus: (characterData['initiativeBonus'] as int?) ?? 0,
        imagePath: characterData['imagePath'] as String?,
        strength: (characterData['strength'] as int?) ?? 10,
        dexterity: (characterData['dexterity'] as int?) ?? 10,
        constitution: (characterData['constitution'] as int?) ?? 10,
        intelligence: (characterData['intelligence'] as int?) ?? 10,
        wisdom: (characterData['wisdom'] as int?) ?? 10,
        charisma: (characterData['charisma'] as int?) ?? 10,
        proficientSkills: List<String>.from(characterData['proficientSkills'] as Iterable? ?? []),
        size: characterData['size'] as String? ?? 'Medium',
        type: characterData['type'] as String? ?? 'Humanoid',
        subtype: characterData['subtype'] as String?,
        alignment: characterData['alignment'] as String? ?? 'Neutral',
        description: (characterData['description'] as String?) ?? '',
        specialAbilities: (characterData['specialAbilities'] as List<dynamic>?)?.map((e) => e.toString()).join(', ') ?? null,
        attacks: (characterData['attacks'] as String?) ?? '',
        attackList: List<Attack>.from(characterData['attackList'] as Iterable? ?? []),
        inventory: [], // TODO: Convert to DisplayInventoryItem when needed
        gold: (characterData['gold'] as double?) ?? 0.0,
        silver: (characterData['silver'] as double?) ?? 0.0,
        copper: (characterData['copper'] as double?) ?? 0.0,
        sourceType: 'custom',
        sourceId: null,
        isFavorite: false,
        version: '1.0',
      );
      
      await _characterService.updatePlayerCharacter(playerCharacter);
      _playerCharacter = playerCharacter;
      await _loadCharacterData();
    });
  }

  /// Speichert eine Creature mit Formulardaten
  Future<void> saveCreature(Map<String, dynamic> characterData) async {
    await _executeWithErrorHandling(() async {
      // Creature aus Formulardaten erstellen
      final creature = Creature(
        id: _creature?.id ?? UuidService().generateId(),
        name: (characterData['name'] as String?) ?? 'Unbenannt',
        maxHp: (characterData['maxHp'] as int?) ?? 10,
        currentHp: (characterData['maxHp'] as int?) ?? 10,
        armorClass: (characterData['armorClass'] as int?) ?? 10,
        speed: (characterData['speed'] as String?) ?? '30ft',
        attacks: (characterData['attacks'] as String?) ?? '',
        initiativeBonus: (characterData['initiativeBonus'] as int?) ?? 0,
        strength: (characterData['strength'] as int?) ?? 10,
        dexterity: (characterData['dexterity'] as int?) ?? 10,
        constitution: (characterData['constitution'] as int?) ?? 10,
        intelligence: (characterData['intelligence'] as int?) ?? 10,
        wisdom: (characterData['wisdom'] as int?) ?? 10,
        charisma: (characterData['charisma'] as int?) ?? 10,
        size: characterData['size'] as String? ?? 'Medium',
        type: characterData['type'] as String? ?? 'Humanoid',
        subtype: characterData['subtype'] as String?,
        alignment: characterData['alignment'] as String? ?? 'Neutral',
        challengeRating: ((characterData['challengeRating'] as double?) ?? 0.25).round(),
        specialAbilities: (characterData['specialAbilities'] as List<dynamic>?)?.map((e) => e.toString()).join(', ') ?? null,
        legendaryActions: (characterData['legendaryActions'] as List<dynamic>?)?.map((e) => e.toString()).join(', ') ?? null,
        description: (characterData['description'] as String?) ?? '',
        isCustom: true,
        sourceType: 'custom',
        attackList: List<Attack>.from(characterData['attackList'] as Iterable? ?? []),
        inventory: [], // TODO: Convert to DisplayInventoryItem when needed
        gold: (characterData['gold'] as double?) ?? 0.0,
        silver: (characterData['silver'] as double?) ?? 0.0,
        copper: (characterData['copper'] as double?) ?? 0.0,
      );
      
      await _characterService.updateCreature(creature);
      _creature = creature;
      await _loadCharacterData();
    });
  }

  // ============================================================================
  // PLAYER CHARACTER LIST MANAGEMENT
  // ============================================================================

  /// Lädt alle Player Characters für eine Kampagne
  Future<void> loadPlayerCharacters(String campaignId) async {
    await _executeWithErrorHandling(() async {
      final db = DatabaseHelper.instance;
      final characterMaps = await db.database.then((db) => 
        db.query('player_characters', where: 'campaign_id = ?', whereArgs: [campaignId]));
      
      _playerCharactersList = characterMaps.map((map) => PlayerCharacter.fromMap(map)).toList();
      notifyListeners();
    });
  }

  /// Schaltet den Favoriten-Status eines Players um
  Future<void> toggleFavorite(PlayerCharacter pc) async {
    await _executeWithErrorHandling(() async {
      final updatedPc = pc.copyWith(isFavorite: !pc.isFavorite);
      final db = DatabaseHelper.instance;
      await db.updatePlayerCharacter(updatedPc);
      
      // Lokale Liste aktualisieren
      final index = _playerCharactersList.indexWhere((p) => p.id == pc.id);
      if (index != -1) {
        _playerCharactersList[index] = updatedPc;
      }
      
      notifyListeners();
    });
  }

  /// Löscht einen Player Character
  Future<void> deletePlayerCharacter(String characterId) async {
    await _executeWithErrorHandling(() async {
      final db = DatabaseHelper.instance;
      await db.deletePlayerCharacter(characterId);
      
      // Aus lokaler Liste entfernen
      _playerCharactersList.removeWhere((pc) => pc.id == characterId);
      notifyListeners();
    });
  }

  // ============================================================================
  // ADDITIONAL STATE VARIABLES FOR LIST MANAGEMENT
  // ============================================================================

  List<PlayerCharacter> _playerCharactersList = [];

  /// Getter für die Player Characters Liste
  List<PlayerCharacter> get playerCharacters => _playerCharactersList;

  // ============================================================================
  // DISPOSE
  // ============================================================================

  @override
  void dispose() {
    super.dispose();
  }
}
