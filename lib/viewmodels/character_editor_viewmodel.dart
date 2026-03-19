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
import '../services/armor_calculation_service.dart';
import '../services/uuid_service.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/creature_model_repository.dart';
import '../database/repositories/inventory_item_model_repository.dart';
import '../database/repositories/item_model_repository.dart';

/// ViewModel für den Character Editor
/// 
/// HINWEIS: Dies ist eine teilweise Migration zu den neuen ModelRepositories.
/// Einige Legacy-Methoden werden noch verwendet, bis alle Services migriert sind.
/// 
/// Die neuen Repositories bieten:
/// - Direkte Arbeit mit Modelle (keine Entity-Konvertierung)
/// - Spezialisierte Suchmethoden
/// - Konsistente Serialisierung
class CharacterEditorViewModel extends ChangeNotifier {
  final CharacterEditorService _characterService;
  final InventoryService _inventoryService;
  final PlayerCharacterModelRepository? _playerCharacterRepository;
  final CreatureModelRepository? _creatureRepository;
  final InventoryItemModelRepository? _inventoryItemRepository;
  final ItemModelRepository? _itemRepository;

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

  // Player Character Liste
  List<PlayerCharacter> _playerCharactersList = [];

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
  List<PlayerCharacter> get playerCharacters => _playerCharactersList;

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
    PlayerCharacterModelRepository? playerCharacterRepository,
    CreatureModelRepository? creatureRepository,
    InventoryItemModelRepository? inventoryItemRepository,
    ItemModelRepository? itemRepository,
  }) : _characterService = characterService ?? CharacterEditorService(),
       _inventoryService = inventoryService ?? InventoryService(),
       _playerCharacterRepository = playerCharacterRepository,
       _creatureRepository = creatureRepository,
       _inventoryItemRepository = inventoryItemRepository,
       _itemRepository = itemRepository;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialisiert den ViewModel mit einem Player Character
  /// 
  /// Verwendet jetzt das neue PlayerCharacterModelRepository
  Future<void> initWithPlayerCharacter(String characterId) async {
    await _executeWithErrorHandling(() async {
      _isPlayerCharacter = true;
      
      // Load player character mit neuem Repository
      try {
        if (_playerCharacterRepository != null) {
          _playerCharacter = await _playerCharacterRepository!.findById(characterId);
        } else {
          // Fallback zu Legacy-Service
          _playerCharacter = await _playerCharacterRepository!.findById(characterId);
        }
        await _loadCharacterData();
      } catch (e) {
        debugPrint('Fehler beim Laden des Player Characters: $e');
        _error = e.toString();
        rethrow;
      }
    });
  }

  /// Initialisiert den ViewModel mit einer Kreatur
  /// 
  /// Verwendet jetzt das neue CreatureModelRepository
  Future<void> initWithCreature(String creatureId) async {
    await _executeWithErrorHandling(() async {
      _isPlayerCharacter = false;
      
      // Load creature mit neuem Repository
      try {
        if (_creatureRepository != null) {
          _creature = await _creatureRepository!.findById(creatureId);
        } else {
          // Fallback zu Legacy-Service
          _creature = await _creatureRepository!.findById(creatureId);
        }
        await _loadCharacterData();
      } catch (e) {
        debugPrint('Fehler beim Laden der Kreatur: $e');
        _error = e.toString();
        rethrow;
      }
    });
  }

  /// Lädt alle Character-Daten (Inventar, Angriffe, etc.)
  /// 
  /// Verwendet jetzt das neue InventoryItemModelRepository
  Future<void> _loadCharacterData() async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    print('🔄 [CharacterEditorViewModel] _loadCharacterData aufgerufen für Character: $characterId');
    
    // Inventar laden mit neuem Repository
    try {
      if (_inventoryItemRepository != null) {
        print('🔄 [CharacterEditorViewModel] Lade Inventar von Repository...');
        _inventory = await _inventoryItemRepository!.findByCharacter(characterId);
        print('🔄 [CharacterEditorViewModel] ${_inventory.length} Items geladen');
        
        // Debug: Zeige Equipment-Status
        for (final item in _inventory) {
          print('  - ${item.name} (ID: ${item.id}): isEquipped=${item.isEquipped}, equipSlot=${item.equipSlot}');
        }
      } else {
        // Kein Repository verfügbar - leeres Inventar
        print('⚠️ [CharacterEditorViewModel] Kein InventoryItemRepository verfügbar');
        _inventory = [];
      }
      _displayInventory = List.from(_inventory);
    } catch (e) {
      debugPrint('Fehler beim Laden des Inventars: $e');
      _displayInventory = [];
      _inventory = [];
    }
    
    // Item-Daten laden für schnelleren Zugriff
    print('🔄 [CharacterEditorViewModel] Lade Item-Details...');
    _itemDetails = {};
    for (final inventoryItem in _displayInventory) {
      try {
        if (_itemRepository != null) {
          final item = await _itemRepository!.findById(inventoryItem.itemId);
          if (item != null) {
            _itemDetails[inventoryItem.itemId] = item;
          }
        } else {
          // Fallback: Kein Repository verfügbar
          debugPrint('ItemRepository nicht verfügbar für Item ${inventoryItem.itemId}');
        }
      } catch (e) {
        debugPrint('Fehler beim Laden von Item ${inventoryItem.itemId}: $e');
      }
    }
    print('🔄 [CharacterEditorViewModel] ${_itemDetails.length} Item-Details geladen');
    
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
    
    print('🔄 [CharacterEditorViewModel] notifyListeners aufgerufen - UI sollte aktualisieren');
    notifyListeners();
  }

  // ============================================================================
  // CHARACTER MANAGEMENT
  // ============================================================================

  /// Aktualisiert den Character
  Future<void> updateCharacter() async {
      if (_isPlayerCharacter && _playerCharacter != null) {
        await _executeWithErrorHandling(() async {
          if (_playerCharacterRepository != null) {
            await _playerCharacterRepository!.update(_playerCharacter!);
          } else {
            await _characterService.updatePlayerCharacter(_playerCharacter!);
          }
      });
      } else if (!_isPlayerCharacter && _creature != null) {
        await _executeWithErrorHandling(() async {
          if (_creatureRepository != null) {
            await _creatureRepository!.update(_creature!);
          } else {
            await _characterService.updateCreature(_creature!);
          }
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
        
        if (_playerCharacterRepository != null) {
          await _playerCharacterRepository!.update(updatedCharacter);
        } else {
          await _characterService.updatePlayerCharacter(updatedCharacter);
        }
        _playerCharacter = updatedCharacter;
      } else if (!_isPlayerCharacter && _creature != null) {
        // Inventar zur Kreatur hinzufügen
        final updatedCreature = _creature!.copyWith(
          attackList: _attacks,
        );
        
        if (_creatureRepository != null) {
          await _creatureRepository!.update(updatedCreature);
        } else {
          await _characterService.updateCreature(updatedCreature);
        }
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
        characterId: characterId,
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
      if (_inventoryItemRepository != null) {
        await _inventoryItemRepository!.delete(inventoryItemId);
      } else {
        throw Exception('InventoryItemRepository nicht verfügbar');
      }
      await _loadCharacterData(); // Daten neu laden
    });
  }

  /// Aktualisiert die Menge eines Items
  Future<void> updateItemQuantity(String inventoryItemId, int newQuantity) async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    await _executeWithErrorHandling(() async {
      await _inventoryService.updateItemQuantity(
        inventoryItemId: inventoryItemId,
        characterId: characterId,
        newQuantity: newQuantity,
      );
      await _loadCharacterData(); // Daten neu laden
    });
  }

  /// Rüstet ein Item aus
  Future<void> equipItem(String inventoryItemId, EquipSlot equipSlot) async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    print('🎯 [CharacterEditorViewModel] equipItem aufgerufen: inventoryItemId=$inventoryItemId, slot=$equipSlot');
    
    await _executeWithErrorHandling(() async {
      await _inventoryService.equipItem(
        inventoryItemId: inventoryItemId,
        characterId: characterId,
        equipSlot: equipSlot,
      );
      print('🎯 [CharacterEditorViewModel] Lade Character-Daten neu...');
      await _loadCharacterData(); // Daten neu laden
      print('🎯 [CharacterEditorViewModel] Character-Daten neu geladen, notifyListeners aufgerufen');
    });
  }

  /// Legt ein Item ab
  Future<void> unequipItem(String inventoryItemId) async {
    final characterId = _isPlayerCharacter ? _playerCharacter!.id : _creature!.id;
    
    print('🎯 [CharacterEditorViewModel] unequipItem aufgerufen: inventoryItemId=$inventoryItemId');
    
    await _executeWithErrorHandling(() async {
      await _inventoryService.unequipItem(inventoryItemId, characterId);
      print('🎯 [CharacterEditorViewModel] Lade Character-Daten neu...');
      await _loadCharacterData(); // Daten neu laden
      print('🎯 [CharacterEditorViewModel] Character-Daten neu geladen, notifyListeners aufgerufen');
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
  // ARMOR CLASS CALCULATION
  // ============================================================================

  /// Berechnet die effektive Rüstungsklasse basierend auf ausgerüsteter Rüstung und Schild
  /// 
  /// Berücksichtigt:
  /// - Basis-AC (10 oder Character-AC)
  /// - Dexterity Modifier
  /// - Rüstungs-AC (ersetzt Basis-AC)
  /// - Schild-Bonus
  /// 
  /// D&D 5e Regeln:
  /// - Heavy Armor: Kein Dex-Bonus
  /// - Medium Armor: Dex-Bonus max +2
  /// - Light Armor: Voller Dex-Bonus
  Future<ArmorClassResult> calculateEffectiveArmorClass() async {
    final characterId = _isPlayerCharacter ? _playerCharacter?.id : _creature?.id;
    final dexterity = _isPlayerCharacter ? _playerCharacter?.dexterity ?? 10 : _creature?.dexterity ?? 10;
    final baseAc = armorClass; // Verwende die gespeicherte AC als Basis
    
    if (characterId == null) {
      return ArmorClassResult(
        totalAc: baseAc,
        baseAc: baseAc,
        dexModifier: 0,
        armorBonus: 0,
        shieldBonus: 0,
        formula: '$baseAc',
      );
    }
    
    return _inventoryService.calculateEffectiveArmorClass(
      characterId: characterId,
      dexterity: dexterity,
      baseArmorClass: baseAc,
    );
  }

  /// Berechnet die effektive AC synchron (ohne Datenbankzugriff)
  /// 
  /// Verwendet die bereits geladenen Item-Daten für die Berechnung
  int get effectiveArmorClassSync {
    final dexterity = _isPlayerCharacter ? _playerCharacter?.dexterity ?? 10 : _creature?.dexterity ?? 10;
    final baseAc = 10; // Standard Basis-AC
    
    // Baue Liste der ausgerüsteten Items mit ihren Slots
    final equippedItems = <(EquipSlot, Item?)>[];
    
    for (final invItem in _inventory) {
      if (invItem.isEquipped && invItem.equipSlot != null) {
        final item = _itemDetails[invItem.itemId];
        equippedItems.add((invItem.equipSlot!, item));
      }
    }
    
    return _inventoryService.calculateArmorClassSync(
      dexterity: dexterity,
      equippedItems: equippedItems,
      baseArmorClass: baseAc,
    );
  }

  /// Gibt die Dexterity zurück
  int get dexterity => _isPlayerCharacter ? _playerCharacter?.dexterity ?? 10 : _creature?.dexterity ?? 10;

  /// Gibt den Dexterity Modifier zurück
  int get dexterityModifier => ((dexterity - 10) ~/ 2);

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
  /// 
  /// HINWEIS: Verwendet neues PlayerCharacterModelRepository
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
        // KORRIGIERTE FELDER:
        specialAbilities: (characterData['specialAbilities'] as String?) ?? null,
        attacks: (characterData['attacks'] as String?) ?? '',
        attackList: List<Attack>.from(characterData['attackList'] as Iterable? ?? []),
        // INVENTAR FIX:
        inventory: _inventory, // Tatsächliche Inventardaten verwenden
        gold: (characterData['gold'] as double?) ?? 0.0,
        silver: (characterData['silver'] as double?) ?? 0.0,
        copper: (characterData['copper'] as double?) ?? 0.0,
        sourceType: 'custom',
        sourceId: null,
        isFavorite: false,
        version: '1.0',
      );
      
      if (_playerCharacterRepository != null) {
        await _playerCharacterRepository!.create(playerCharacter);
      } else {
        await _characterService.updatePlayerCharacter(playerCharacter);
      }
      _playerCharacter = playerCharacter;
      await _loadCharacterData();
    });
  }

  /// Speichert eine Creature mit Formulardaten
  /// 
  /// HINWEIS: Verwendet neues CreatureModelRepository
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
        specialAbilities: (characterData['specialAbilities'] as String?) ?? null,
        legendaryActions: (characterData['legendaryActions'] as String?) ?? null,
        description: (characterData['description'] as String?) ?? '',
        isCustom: true,
        sourceType: 'custom',
        attackList: List<Attack>.from(characterData['attackList'] as Iterable? ?? []),
        inventory: [], // TODO: Convert to DisplayInventoryItem when needed
        gold: (characterData['gold'] as double?) ?? 0.0,
        silver: (characterData['silver'] as double?) ?? 0.0,
        copper: (characterData['copper'] as double?) ?? 0.0,
      );
      
      if (_creatureRepository != null) {
        await _creatureRepository!.create(creature);
      } else {
        await _characterService.updateCreature(creature);
      }
      _creature = creature;
      await _loadCharacterData();
    });
  }

  // ============================================================================
  // PLAYER CHARACTER LIST MANAGEMENT
  // ============================================================================

  /// Lädt alle Player Characters für eine Kampagne
  /// 
  /// HINWEIS: Verwendet neues PlayerCharacterModelRepository
  Future<void> loadPlayerCharacters(String campaignId) async {
    print('=== LOAD PLAYER CHARACTERS START ===');
    print('Campaign ID: $campaignId');
    print('Repository verfügbar: ${_playerCharacterRepository != null}');
    
    await _executeWithErrorHandling(() async {
      try {
        if (_playerCharacterRepository != null) {
          print('Lade Characters von Repository...');
          _playerCharactersList = await _playerCharacterRepository!.findByCampaign(campaignId);
          print('${_playerCharactersList.length} Characters geladen');
          for (final pc in _playerCharactersList) {
            print('  - ${pc.name} (${pc.id})');
          }
        } else {
          // Kein Repository verfügbar - leere Liste
          print('WARNUNG: Kein Repository verfügbar!');
          _playerCharactersList = [];
        }
        notifyListeners();
        print('=== LOAD PLAYER CHARACTERS SUCCESS ===');
      } catch (e) {
        debugPrint('Fehler beim Laden der Player Characters: $e');
        print('=== LOAD PLAYER CHARACTERS ERROR ===');
        print('Fehler: $e');
        _playerCharactersList = [];
        notifyListeners();
      }
    });
  }

  /// Schaltet den Favoriten-Status eines Players um
  /// 
  /// HINWEIS: Verwendet neues PlayerCharacterModelRepository
  Future<void> toggleFavorite(PlayerCharacter pc) async {
    await _executeWithErrorHandling(() async {
      final updatedPc = pc.copyWith(isFavorite: !pc.isFavorite);
      
      if (_playerCharacterRepository != null) {
        await _playerCharacterRepository!.update(updatedPc);
      } else {
        await _characterService.updatePlayerCharacter(updatedPc);
      }
      
      // Lokale Liste aktualisieren
      final index = _playerCharactersList.indexWhere((p) => p.id == pc.id);
      if (index != -1) {
        _playerCharactersList[index] = updatedPc;
      }
      
      notifyListeners();
    });
  }

  /// Löscht einen Player Character
  /// 
  /// HINWEIS: Verwendet neues PlayerCharacterModelRepository
  Future<void> deletePlayerCharacter(String characterId) async {
    await _executeWithErrorHandling(() async {
      if (_playerCharacterRepository != null) {
        await _playerCharacterRepository!.delete(characterId);
      } else {
        throw Exception('PlayerCharacterRepository nicht verfügbar');
      }
      
      // Aus lokaler Liste entfernen
      _playerCharactersList.removeWhere((pc) => pc.id == characterId);
      notifyListeners();
    });
  }

  // ============================================================================
  // DISPOSE
  // ============================================================================

  @override
  void dispose() {
    super.dispose();
  }
}
