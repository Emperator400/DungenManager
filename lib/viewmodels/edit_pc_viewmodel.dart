import 'package:flutter/foundation.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/inventory_item_model_repository.dart';
import '../database/repositories/item_model_repository.dart';
import '../database/core/database_connection.dart';
import '../game_data/dnd_logic.dart';
import '../game_data/dnd_models.dart';
import '../game_data/game_data.dart';
import '../models/inventory_item.dart';
import '../models/item.dart';
import '../models/player_character.dart';
import '../models/equipment.dart';
import '../models/equip_slot.dart';
import '../services/inventory_service.dart';

/// ViewModel für die Bearbeitung von Player Characters
/// 
/// HINWEIS: Verwendet jetzt die neuen ModelRepositories
/// Zentralisiert State Management und Business-Logik für PC-Erstellung und -Bearbeitung
class EditPCViewModel extends ChangeNotifier {
  final PlayerCharacterModelRepository _pcRepository;
  final InventoryItemModelRepository _inventoryRepository;
  final ItemModelRepository _itemRepository;
  final InventoryService _inventoryService;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // Character Daten
  PlayerCharacter? _pcToEdit;
  String _campaignId = '';
  String _name = '';
  String _playerName = '';
  int _level = 1;
  int _maxHp = 10;
  int _armorClass = 10;
  int _strength = 10;
  int _dexterity = 10;
  int _constitution = 10;
  int _intelligence = 10;
  int _wisdom = 10;
  int _charisma = 10;
  DndClass? _selectedClass;
  DndRace? _selectedRace;
  Set<String> _proficientSkills = {};
  String? _imagePath;

  // Loading States
  final bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Inventory
  List<DisplayInventoryItem> _inventory = [];
  
  // Equipment
  Equipment _equipment = Equipment.empty();

  // D&D Details State
  String _size = 'Medium';
  String _type = 'Humanoid';
  String? _subtype;
  String _alignment = 'Neutral';
  String _description = '';
  String? _specialAbilities;
  String _attacks = '';
  double _gold = 0.0;
  double _silver = 0.0;
  double _copper = 0.0;

  // ============================================================================
  // GETTERS
  // ============================================================================

  PlayerCharacter? get pcToEdit => _pcToEdit;
  String get campaignId => _campaignId;
  String get name => _name;
  String get playerName => _playerName;
  int get level => _level;
  int get maxHp => _maxHp;
  int get armorClass => _armorClass;
  int get strength => _strength;
  int get dexterity => _dexterity;
  int get constitution => _constitution;
  int get intelligence => _intelligence;
  int get wisdom => _wisdom;
  int get charisma => _charisma;
  DndClass? get selectedClass => _selectedClass;
  DndRace? get selectedRace => _selectedRace;
  Set<String> get proficientSkills => _proficientSkills;
  String? get imagePath => _imagePath;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<DisplayInventoryItem> get inventory => _inventory;
  Equipment get equipment => _equipment;
  
  /// Gibt Equipment als Map für das Widget zurück
  Map<EquipmentSlot, DisplayInventoryItem?> get equipmentMap {
    final map = <EquipmentSlot, DisplayInventoryItem?>{};
    for (final slot in EquipmentSlot.values) {
      final equippedItem = _equipment.getItem(slot);
      map[slot] = equippedItem?.item;
    }
    return map;
  }
  
  /// Gibt die IDs aller ausgerüsteten Items zurück (für BackpackWidget)
  Set<String> get equippedItemIds {
    return _equipment.getEquippedItems()
        .map((equipped) => equipped.inventoryItemId)
        .where((id) => id != null)
        .cast<String>()
        .toSet();
  }

  // D&D Details Getters
  String get size => _size;
  String get type => _type;
  String? get subtype => _subtype;
  String get alignment => _alignment;
  String get description => _description;
  String? get specialAbilities => _specialAbilities;
  String get attacks => _attacks;
  double get gold => _gold;
  double get silver => _silver;
  double get copper => _copper;

  // Computed Properties
  int get initiativeBonus => getModifier(_dexterity);
  int get proficiencyBonus => getProficiencyBonus(_level);
  bool get isEdit => _pcToEdit != null;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  /// 
  /// HINWEIS: Verwendet jetzt die neuen ModelRepositories
  /// 
  EditPCViewModel({
    PlayerCharacterModelRepository? pcRepository,
    InventoryItemModelRepository? inventoryRepository,
    ItemModelRepository? itemRepository,
    InventoryService? inventoryService,
  }) : _pcRepository = pcRepository ?? PlayerCharacterModelRepository(DatabaseConnection.instance),
       _inventoryRepository = inventoryRepository ?? InventoryItemModelRepository(DatabaseConnection.instance),
       _itemRepository = itemRepository ?? ItemModelRepository(DatabaseConnection.instance),
       _inventoryService = inventoryService ?? InventoryService();

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialisiert den ViewModel mit PC-Daten
  Future<void> initialize(String campaignId, PlayerCharacter? pc) async {
    try {
      _error = null;
      notifyListeners();
      
      _campaignId = campaignId;
      _pcToEdit = pc;

      if (pc != null) {
        // Edit mode - lade bestehende Daten
        _name = pc.name;
        _playerName = pc.playerName;
        _level = pc.level;
        _maxHp = pc.maxHp;
        _armorClass = pc.armorClass;
        _strength = pc.strength;
        _dexterity = pc.dexterity;
        _constitution = pc.constitution;
        _intelligence = pc.intelligence;
        _wisdom = pc.wisdom;
        _charisma = pc.charisma;
        _proficientSkills = pc.proficientSkills.toSet();
        _imagePath = pc.imagePath;

        // Lade D&D Details
        _size = pc.size ?? 'Medium';
        _type = pc.type ?? 'Humanoid';
        _subtype = pc.subtype;
        _alignment = pc.alignment ?? 'Neutral';
        _description = pc.description ?? '';
        _specialAbilities = pc.specialAbilities;
        _attacks = pc.attacks ?? '';
        _gold = pc.gold ?? 0.0;
        _silver = pc.silver ?? 0.0;
        _copper = pc.copper ?? 0.0;

        // Finde Klasse und Rasse
        _selectedClass = allDndClasses.firstWhere(
          (c) => c.name == pc.className,
          orElse: () => allDndClasses.first,
        );
        _selectedRace = allDndRaces.firstWhere(
          (r) => r.name == pc.raceName,
          orElse: () => allDndRaces.first,
        );

        // Lade Inventar
        await _loadInventory(pc.id);
      } else {
        // Create mode - setze Standardwerte
        _name = '';
        _playerName = '';
        _level = 1;
        _maxHp = 10;
        _armorClass = 10;
        _strength = 10;
        _dexterity = 10;
        _constitution = 10;
        _intelligence = 10;
        _wisdom = 10;
        _charisma = 10;
        _proficientSkills = {};
        _imagePath = null;

        // Setze Standard-D&D Details
        _size = 'Medium';
        _type = 'Humanoid';
        _subtype = null;
        _alignment = 'Neutral';
        _description = '';
        _specialAbilities = null;
        _attacks = '';
        _gold = 0.0;
        _silver = 0.0;
        _copper = 0.0;

        // Setze Standard-Klasse und Rasse
        _selectedClass = allDndClasses.first;
        _selectedRace = allDndRaces.first;

        _inventory = [];
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ============================================================================
  // DATA UPDATERS
  // ============================================================================

  /// Aktualisiert den Namen des Charakters
  void updateName(String name) {
    _name = name;
    notifyListeners();
  }

  /// Aktualisiert den Namen des Spielers
  void updatePlayerName(String playerName) {
    _playerName = playerName;
    notifyListeners();
  }

  /// Aktualisiert die Stufe
  void updateLevel(int level) {
    _level = level;
    notifyListeners();
  }

  /// Aktualisiert die maximalen HP
  void updateMaxHp(int maxHp) {
    _maxHp = maxHp;
    notifyListeners();
  }

  /// Aktualisiert die Rüstungsklasse
  void updateArmorClass(int armorClass) {
    _armorClass = armorClass;
    notifyListeners();
  }

  /// Aktualisiert die Stärke
  void updateStrength(int strength) {
    _strength = strength;
    notifyListeners();
  }

  /// Aktualisiert die Geschicklichkeit
  void updateDexterity(int dexterity) {
    _dexterity = dexterity;
    notifyListeners();
  }

  /// Aktualisiert die Konstitution
  void updateConstitution(int constitution) {
    _constitution = constitution;
    notifyListeners();
  }

  /// Aktualisiert die Intelligenz
  void updateIntelligence(int intelligence) {
    _intelligence = intelligence;
    notifyListeners();
  }

  /// Aktualisiert die Weisheit
  void updateWisdom(int wisdom) {
    _wisdom = wisdom;
    notifyListeners();
  }

  /// Aktualisiert den Charisma
  void updateCharisma(int charisma) {
    _charisma = charisma;
    notifyListeners();
  }

  /// Aktualisiert die Klasse
  void updateClass(DndClass? selectedClass) {
    _selectedClass = selectedClass;
    notifyListeners();
  }

  /// Aktualisiert die Rasse
  void updateRace(DndRace? selectedRace) {
    _selectedRace = selectedRace;
    notifyListeners();
  }

  /// Aktualisiert den Bildpfad
  void updateImagePath(String? imagePath) {
    _imagePath = imagePath;
    notifyListeners();
  }

  /// Schaltet die Fertigkeits-Profilienz um
  void toggleSkillProficiency(String skillName) {
    if (_proficientSkills.contains(skillName)) {
      _proficientSkills.remove(skillName);
    } else {
      _proficientSkills.add(skillName);
    }
    notifyListeners();
  }

  // D&D Details Updaters
  void updateSize(String size) {
    _size = size;
    notifyListeners();
  }

  void updateType(String type) {
    _type = type;
    notifyListeners();
  }

  void updateSubtype(String? subtype) {
    _subtype = subtype;
    notifyListeners();
  }

  void updateAlignment(String alignment) {
    _alignment = alignment;
    notifyListeners();
  }

  void updateDescription(String description) {
    _description = description;
    notifyListeners();
  }

  void updateSpecialAbilities(String? specialAbilities) {
    _specialAbilities = specialAbilities;
    notifyListeners();
  }

  void updateAttacks(String attacks) {
    _attacks = attacks;
    notifyListeners();
  }

  void updateGold(double gold) {
    _gold = gold;
    notifyListeners();
  }

  void updateSilver(double silver) {
    _silver = silver;
    notifyListeners();
  }

  void updateCopper(double copper) {
    _copper = copper;
    notifyListeners();
  }

  // ============================================================================
  // SKILL CALCULATIONS
  // ============================================================================

  /// Berechnet den Modifikator für eine Fähigkeit
  int getAbilityModifier(Ability ability) {
    switch (ability) {
      case Ability.strength:
        return getModifier(_strength);
      case Ability.dexterity:
        return getModifier(_dexterity);
      case Ability.constitution:
        return getModifier(_constitution);
      case Ability.intelligence:
        return getModifier(_intelligence);
      case Ability.wisdom:
        return getModifier(_wisdom);
      case Ability.charisma:
        return getModifier(_charisma);
    }
  }

  /// Berechnet den Gesamt-Bonus für eine Fertigkeit
  int getSkillBonus(DndSkill skill) {
    final abilityModifier = getAbilityModifier(skill.ability);
    final isProficient = _proficientSkills.contains(skill.name);
    return abilityModifier + (isProficient ? proficiencyBonus : 0);
  }

  /// Gibt den Bonus-String für eine Fertigkeit zurück
  String getSkillBonusString(DndSkill skill) {
    final bonus = getSkillBonus(skill);
    return bonus >= 0 ? '+$bonus' : bonus.toString();
  }

  // ============================================================================
  // CHARACTER OPERATIONS
  // ============================================================================

  /// Speichert den Character (Create oder Update)
  Future<void> saveCharacter() async {
    try {
      _isSaving = true;
      _error = null;
      notifyListeners();
      
      print('=== SAVE CHARACTER START ===');
      print('Campaign ID: $_campaignId');
      print('Name: $_name');
      print('Player Name: $_playerName');
      
      if (_selectedClass == null || _selectedRace == null) {
        final errorMsg = 'Klasse und Rasse müssen ausgewählt werden';
        print('FEHLER: $errorMsg');
        throw Exception(errorMsg);
      }

      if (_name.isEmpty || _playerName.isEmpty) {
        final errorMsg = 'Name und Spielername müssen ausgefüllt werden';
        print('FEHLER: $errorMsg');
        throw Exception(errorMsg);
      }

      print('Erstelle PlayerCharacter...');
      final pc = PlayerCharacter.create(
        campaignId: _campaignId,
        name: _name,
        playerName: _playerName,
        className: _selectedClass!.name,
        raceName: _selectedRace!.name,
        level: _level,
        maxHp: _maxHp,
        armorClass: _armorClass,
        initiativeBonus: initiativeBonus,
        imagePath: _imagePath,
        strength: _strength,
        dexterity: _dexterity,
        constitution: _constitution,
        intelligence: _intelligence,
        wisdom: _wisdom,
        charisma: _charisma,
        proficientSkills: _proficientSkills.toList(),
        
        // D&D-Erweiterungsfelder
        size: _size,
        type: _type,
        subtype: _subtype,
        alignment: _alignment,
        description: _description,
        specialAbilities: _specialAbilities,
        attacks: _attacks,
        
        // Strukturierte Daten
        attackList: [],
        inventory: _inventory.map((item) => item.inventoryItem).toList(),
        
        // Equipment
        equipment: _equipment.toMap(),
        
        // Währung
        gold: _gold,
        silver: _silver,
        copper: _copper,
        
        // Metadaten
        sourceType: 'custom',
        sourceId: null,
        isFavorite: false,
        version: '1.0',
      );
      
      print('PlayerCharacter erstellt mit ID: ${pc.id}');

      if (_pcToEdit != null) {
        // Update existing character
        print('Update existing character: ${_pcToEdit!.id}');
        final updatePc = pc.copyWith(id: _pcToEdit!.id);
        print('Update PC ID: ${updatePc.id}');
        final savedPc = await _pcRepository.update(updatePc);
        print('Character erfolgreich aktualisiert: ${savedPc.id}');
        if (savedPc != null) {
          _pcToEdit = savedPc;
        }
      } else {
        // Create new character
        print('Create new character...');
        print('PC Repository: $_pcRepository');
        final savedPc = await _pcRepository.create(pc);
        print('Character erfolgreich erstellt mit ID: ${savedPc.id}');
        if (savedPc != null) {
          _pcToEdit = savedPc;
          print('PC nach Speichern gesetzt: ${_pcToEdit?.id}');
        } else {
          print('WARNUNG: savedPc ist null!');
        }
      }
      
      print('=== SAVE CHARACTER SUCCESS ===');
    } catch (e, stackTrace) {
      _error = e.toString();
      print('=== SAVE CHARACTER FEHLER ===');
      print('Fehler: $e');
      print('Stack Trace: $stackTrace');
      print('============================');
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // INVENTORY OPERATIONS
  // ============================================================================

  /// Lädt das Inventar eines Charakters über neues Repository mit echten Item-Daten
  Future<void> _loadInventory(String characterId) async {
    try {
      print('=== LOAD INVENTORY START ===');
      print('Character ID: $characterId');
      
      final inventoryItems = await _inventoryRepository.findByCharacter(characterId);
      print('${inventoryItems.length} Inventory-Items gefunden');
      
      final displayItems = <DisplayInventoryItem>[];
      
      for (final invItem in inventoryItems) {
        try {
          // Lade echtes Item aus der Datenbank
          final item = await _itemRepository.findById(invItem.itemId);
          
          print('  Item geladen: ${item?.name ?? invItem.name} (ID: ${invItem.itemId})');
          
          displayItems.add(DisplayInventoryItem(
            inventoryItem: invItem,
            item: item ?? _createFallbackItem(invItem),
          ));
        } catch (e) {
          print('  FEHLER beim Laden von Item ${invItem.itemId}: $e');
          // Fallback auf InventoryItem-Daten
          displayItems.add(DisplayInventoryItem(
            inventoryItem: invItem,
            item: _createFallbackItem(invItem),
          ));
        }
      }
      
      _inventory = displayItems;
      print('${_inventory.length} Display-Items erstellt');
      
      // Lade Equipment basierend auf Inventory-Items
      _loadEquipment();
      
      notifyListeners();
    } catch (e) {
      print('=== LOAD INVENTORY ERROR ===');
      print('Fehler: $e');
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Lädt Equipment basierend auf den InventoryItems
  /// WICHTIG: Baut Equipment direkt aus InventoryItems.isEquipped auf
  /// anstatt aus der veralteten equipment Map
  void _loadEquipment() {
    print('=== LOAD EQUIPMENT START ===');
    _equipment = Equipment.empty();
    
    // Durchlaufe alle InventoryItems und finde ausgerüstete Items
    for (final displayItem in _inventory) {
      final invItem = displayItem.inventoryItem;
      
      if (invItem.isEquipped && invItem.equipSlot != null) {
        // Konvertiere EquipSlot zu EquipmentSlot
        final equipmentSlot = _convertToEquipmentSlot(invItem.equipSlot!);
        
        if (equipmentSlot != null) {
          // Rüste das Item aus
          _equipment = _equipment.equip(equipmentSlot, displayItem);
          print('  Item ausgerüstet: ${displayItem.item.name} in ${equipmentSlot.name} (Slot: ${invItem.equipSlot})');
        } else {
          print('  ⚠️ Kein passender EquipmentSlot für ${invItem.equipSlot}');
        }
      }
    }
    
    print('Equipment erfolgreich geladen: ${_equipment.getEquippedItems().length} Items ausgerüstet');
    print('=== LOAD EQUIPMENT END ===');
  }
  
  /// Konvertiert EquipSlot zu EquipmentSlot
  /// Mapping zwischen den zwei verschiedenen Slot-Systemen
  EquipmentSlot? _convertToEquipmentSlot(EquipSlot equipSlot) {
    // Mapping-Table: EquipSlot -> EquipmentSlot
    switch (equipSlot) {
      case EquipSlot.head:
        return EquipmentSlot.helmet;
      case EquipSlot.chest:
        return EquipmentSlot.armor;
      case EquipSlot.offHand:
        return EquipmentSlot.shield; // oder weaponSecondary
      case EquipSlot.mainHand:
        return EquipmentSlot.weaponPrimary;
      case EquipSlot.hands:
        return EquipmentSlot.gloves;
      case EquipSlot.feet:
        return EquipmentSlot.boots;
      case EquipSlot.ring1:
        return EquipmentSlot.ring1;
      case EquipSlot.ring2:
        return EquipmentSlot.ring2;
      case EquipSlot.amulet:
        return EquipmentSlot.amulet;
      case EquipSlot.cloak:
        return EquipmentSlot.cloak;
      case EquipSlot.ranged:
      case EquipSlot.spellActive:
      case EquipSlot.cantripReady:
      case EquipSlot.spellPrepared1:
      case EquipSlot.spellPrepared2:
      case EquipSlot.spellPrepared3:
      case EquipSlot.spellPrepared4:
      case EquipSlot.belt:
        return null; // Diese Slots haben kein Äquivalent in EquipmentSlot
    }
  }

  /// Erstellt ein Fallback-Item wenn die Details nicht gefunden wurden
  Item _createFallbackItem(InventoryItem invItem) {
    return Item(
      id: invItem.itemId,
      name: invItem.name.isNotEmpty ? invItem.name : 'Unbekannter Gegenstand',
      itemType: ItemType.AdventuringGear,
      weight: 1.0,
      description: invItem.description ?? '',
    );
  }

  /// Fügt ein Item zum Inventar hinzu über neues Repository
  Future<void> addItemToInventory(String itemId, {int quantity = 1}) async {
    if (_pcToEdit == null) {
      throw Exception('Charakter muss zuerst gespeichert werden');
    }

    try {
      final inventoryItem = InventoryItem(
        id: '',
        characterId: _pcToEdit!.id,
        itemId: itemId,
        quantity: quantity,
      );
      await _inventoryRepository.create(inventoryItem);
      await _loadInventory(_pcToEdit!.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Aktualisiert die Menge eines Inventar-Items über neues Repository
  Future<void> updateInventoryItemQuantity(String inventoryItemId, int quantity) async {
    try {
      final existingItem = await _inventoryRepository.findById(inventoryItemId);
      if (existingItem != null) {
        final updatedItem = existingItem.copyWith(quantity: quantity);
        await _inventoryRepository.update(updatedItem);
        await _loadInventory(_pcToEdit!.id);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Entfernt ein Item aus dem Inventar über neues Repository
  Future<void> removeInventoryItem(String inventoryItemId) async {
    try {
      await _inventoryRepository.delete(inventoryItemId);
      if (_pcToEdit != null) {
        await _loadInventory(_pcToEdit!.id);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ============================================================================
  // EQUIPMENT OPERATIONS
  // ============================================================================

  /// Rüstet ein Item in einem Slot aus
  Future<void> equipItem(EquipmentSlot slot, DisplayInventoryItem item) async {
    print('🎯 [EditPCViewModel] equipItem aufgerufen: slot=$slot, item=${item.item.name}');
    
    try {
      // Prüfe ob der Item-Typ für den Slot geeignet ist
      if (!Equipment.canEquip(slot)) {
        throw Exception('${item.item.name} kann nicht im ${Equipment.getSlotName(slot)}-Slot ausgerüstet werden');
      }

      // Prüfe ob das Item bereits ausgerüstet ist
      if (_equipment.isItemEquipped(item.inventoryItem.id)) {
        throw Exception('Dieser Gegenstand ist bereits ausgerüstet');
      }

      // Aktualisiere lokales Equipment
      _equipment = _equipment.equip(slot, item);
      
      // WICHTIG: Aktualisiere auch das InventoryItem in der Datenbank!
      final equipSlot = _convertToEquipSlot(slot);
      await _updateInventoryItemEquipment(item.inventoryItem.id, equipSlot);
      
      notifyListeners();
      print('✅ [EditPCViewModel] Item ${item.item.name} erfolgreich in $slot ausgerüstet');
    } catch (e) {
      print('❌ [EditPCViewModel] Fehler beim Ausrüsten: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Legt ein Item ab (entfernt es aus dem Slot)
  Future<void> unequipItem(EquipmentSlot slot) async {
    print('🎯 [EditPCViewModel] unequipItem aufgerufen: slot=$slot');
    
    try {
      final equippedItem = _equipment.getItem(slot);
      
      // Aktualisiere lokales Equipment
      _equipment = _equipment.unequip(slot);
      
      // WICHTIG: Entferne Equipment-Flag vom InventoryItem in der Datenbank!
      if (equippedItem != null && equippedItem.inventoryItemId != null) {
        await _updateInventoryItemEquipment(equippedItem.inventoryItemId!, null);
        print('✅ [EditPCViewModel] Item ${equippedItem.itemName} erfolgreich aus $slot abgelegt');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ [EditPCViewModel] Fehler beim Ablegen: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Aktualisiert das Equipment-Flag eines InventoryItems in der Datenbank
  Future<void> _updateInventoryItemEquipment(String inventoryItemId, EquipSlot? equipSlot) async {
    try {
      final existingItem = await _inventoryRepository.findById(inventoryItemId);
      if (existingItem != null) {
        final updatedItem = existingItem.copyWith(
          isEquipped: equipSlot != null,
          equipSlot: equipSlot,
        );
        await _inventoryRepository.update(updatedItem);
        print('💾 [EditPCViewModel] InventoryItem $inventoryItemId in Datenbank aktualisiert: equipSlot=$equipSlot');
      }
    } catch (e) {
      print('❌ [EditPCViewModel] Fehler beim Aktualisieren des InventoryItems: $e');
      throw Exception('Fehler beim Aktualisieren des InventoryItems: $e');
    }
  }

  /// Konvertiert EquipmentSlot zu EquipSlot
  /// Mapping zwischen den zwei verschiedenen Slot-Systemen
  EquipSlot? _convertToEquipSlot(EquipmentSlot equipmentSlot) {
    // Mapping-Table: EquipmentSlot -> EquipSlot
    switch (equipmentSlot) {
      case EquipmentSlot.helmet:
        return EquipSlot.head;
      case EquipmentSlot.armor:
        return EquipSlot.chest;
      case EquipmentSlot.shield:
        return EquipSlot.offHand;
      case EquipmentSlot.weaponPrimary:
        return EquipSlot.mainHand;
      case EquipmentSlot.weaponSecondary:
        return EquipSlot.offHand;
      case EquipmentSlot.gloves:
        return EquipSlot.hands;
      case EquipmentSlot.boots:
        return EquipSlot.feet;
      case EquipmentSlot.ring1:
        return EquipSlot.ring1;
      case EquipmentSlot.ring2:
        return EquipSlot.ring2;
      case EquipmentSlot.amulet:
        return EquipSlot.amulet;
      case EquipmentSlot.cloak:
        return EquipSlot.cloak;
    }
  }

  /// Tauscht ein Item gegen ein anderes
  Future<void> swapItem(EquipmentSlot slot, DisplayInventoryItem newItem) async {
    try {
      _equipment = _equipment.swap(slot, newItem);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Validiert die Formulardaten
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name ist ein Pflichtfeld';
    }
    return null;
  }

  /// Validiert den Spielernamen
  String? validatePlayerName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Spielername ist ein Pflichtfeld';
    }
    return null;
  }

  /// Validiert die Klasse
  String? validateClass(DndClass? value) {
    if (value == null) {
      return 'Klasse ist ein Pflichtfeld';
    }
    return null;
  }

  /// Validiert die Rasse
  String? validateRace(DndRace? value) {
    if (value == null) {
      return 'Rasse ist ein Pflichtfeld';
    }
    return null;
  }

  /// Validiert eine Zahl
  String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Dies ist ein Pflichtfeld';
    }
    final number = int.tryParse(value);
    if (number == null || number < 1) {
      return 'Bitte eine gültige positive Zahl eingeben';
    }
    return null;
  }

  /// Validiert eine Fähigkeitspunktzahl (1-20)
  String? validateAbilityScore(String? value) {
    if (value == null || value.isEmpty) {
      return 'Dies ist ein Pflichtfeld';
    }
    final score = int.tryParse(value);
    if (score == null || score < 1 || score > 20) {
      return 'Fähigkeitspunkte müssen zwischen 1 und 20 liegen';
    }
    return null;
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Löscht den Fehler-Zustand
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
