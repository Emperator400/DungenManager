import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/player_character.dart';
import '../models/inventory_item.dart';
import '../models/item.dart';
import '../database/database_helper.dart';
import '../game_data/game_data.dart';
import '../game_data/dnd_logic.dart';
import '../game_data/dnd_models.dart';
import '../services/inventory_service.dart';

/// ViewModel für die Bearbeitung von Player Characters
/// Zentralisiert State Management und Business-Logik für PC-Erstellung und -Bearbeitung
class EditPCViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
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
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Inventory
  List<DisplayInventoryItem> _inventory = [];

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

  // Computed Properties
  int get initiativeBonus => getModifier(_dexterity);
  int get proficiencyBonus => getProficiencyBonus(_level);
  bool get isEdit => _pcToEdit != null;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  EditPCViewModel({
    DatabaseHelper? dbHelper,
    InventoryService? inventoryService,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _inventoryService = inventoryService ?? InventoryService();

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialisiert den ViewModel mit PC-Daten
  Future<void> initialize(String campaignId, PlayerCharacter? pc) async {
    await _executeWithErrorHandling(() async {
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

        // Setze Standard-Klasse und Rasse
        _selectedClass = allDndClasses.first;
        _selectedRace = allDndRaces.first;

        _inventory = [];
      }
    });
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
    await _executeWithErrorHandling(() async {
      if (_selectedClass == null || _selectedRace == null) {
        throw Exception('Klasse und Rasse müssen ausgewählt werden');
      }

      if (_name.isEmpty || _playerName.isEmpty) {
        throw Exception('Name und Spielername müssen ausgefüllt werden');
      }

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
      );

      if (_pcToEdit != null) {
        // Update existing character
        final updatedPc = pc.copyWith(id: _pcToEdit!.id);
        await _dbHelper.updatePlayerCharacter(updatedPc);
      } else {
        // Create new character
        await _dbHelper.insertPlayerCharacter(pc);
      }
    });
  }

  // ============================================================================
  // INVENTORY OPERATIONS
  // ============================================================================

  /// Lädt das Inventar eines Charakters
  Future<void> _loadInventory(String characterId) async {
    final inventoryItems = await _dbHelper.getInventoryForOwner(characterId);
    _inventory = inventoryItems.map((item) => DisplayInventoryItem(
      inventoryItem: item,
      item: Item(
        id: item.itemId, 
        name: 'Item', 
        description: 'Beschreibung',
        itemType: ItemType.Weapon,
      ),
    )).toList();
    notifyListeners();
  }

  /// Fügt ein Item zum Inventar hinzu
  Future<void> addItemToInventory(String itemId, {int quantity = 1}) async {
    if (_pcToEdit == null) {
      throw Exception('Charakter muss zuerst gespeichert werden');
    }

    await _executeWithErrorHandling(() async {
      final inventoryItem = InventoryItem(
        id: '',
        ownerId: _pcToEdit!.id,
        itemId: itemId,
        quantity: quantity,
      );
      await _dbHelper.insertInventoryItem(inventoryItem);
      await _loadInventory(_pcToEdit!.id);
    });
  }

  /// Aktualisiert die Menge eines Inventar-Items
  Future<void> updateInventoryItemQuantity(String inventoryItemId, int quantity) async {
    await _executeWithErrorHandling(() async {
      await _dbHelper.updateInventoryItem(InventoryItem(
        id: inventoryItemId,
        ownerId: '',
        itemId: '',
        quantity: quantity,
      ));
      await _loadInventory(_pcToEdit!.id);
    });
  }

  /// Entfernt ein Item aus dem Inventar
  Future<void> removeInventoryItem(String inventoryItemId) async {
    await _executeWithErrorHandling(() async {
      await _dbHelper.deleteInventoryItem(inventoryItemId);
      await _loadInventory(_pcToEdit!.id);
    });
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

  /// Führt eine Operation mit Error Handling durch
  Future<T> _executeWithErrorHandling<T>(Future<T> Function() operation) async {
    try {
      _error = null;
      notifyListeners();
      
      return await operation();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Löscht den Fehler-Zustand
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================================
  // DISPOSE
  // ============================================================================

  @override
  void dispose() {
    super.dispose();
  }
}
