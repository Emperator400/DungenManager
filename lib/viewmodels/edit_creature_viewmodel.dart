import 'package:flutter/foundation.dart';
import '../models/creature.dart';
import '../services/exceptions/service_exceptions.dart';
import '../services/creature_helper_service.dart';
import '../database/repositories/creature_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für die Creature-Bearbeitung mit Provider-Pattern
/// Basierend auf EditPCViewModel - Wiederverwendet viele Konzepte
class EditCreatureViewModel extends ChangeNotifier {
  final CreatureModelRepository _repository;
  
  EditCreatureViewModel({CreatureModelRepository? repository})
      : _repository = repository ?? CreatureModelRepository(DatabaseConnection.instance);
  
  // State Management
  Creature? _creature;
  bool _isSaving = false;
  String? _error;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Getter
  Creature? get creature => _creature;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get errorMessage => _error; // Für Kompatibilität mit Screen
  bool get isEditing => _creature != null;
  bool get canSave => _creature != null && _hasValidCreature();

  // Grunddaten
  String get name => _creature?.name ?? '';
  String? get description => _creature?.description;
  String get speed => _creature?.speed ?? '30ft';

  // Kampfwerte
  int get maxHp => _creature?.maxHp ?? 10;
  int get armorClass => _creature?.armorClass ?? 10;
  int get challengeRating => _creature?.challengeRating ?? 1;
  int get initiativeBonus => _creature?.initiativeBonus ?? 0;

  // Attribute
  int get strength => _creature?.strength ?? 10;
  int get dexterity => _creature?.dexterity ?? 10;
  int get constitution => _creature?.constitution ?? 10;
  int get intelligence => _creature?.intelligence ?? 10;
  int get wisdom => _creature?.wisdom ?? 10;
  int get charisma => _creature?.charisma ?? 10;

  // D&D Details
  String? get size => _creature?.size;
  String? get type => _creature?.type;
  String? get subtype => _creature?.subtype;
  String? get alignment => _creature?.alignment;
  String get attacks => _creature?.attacks ?? '';
  String? get specialAbilities => _creature?.specialAbilities;
  String? get legendaryActions => _creature?.legendaryActions;

  // Währung
  double get gold => _creature?.gold ?? 0.0;
  double get silver => _creature?.silver ?? 0.0;
  double get copper => _creature?.copper ?? 0.0;

  // Inventar
  List<Map<String, dynamic>> get inventory => _creature?.inventory ?? [];

  /// Initialisiert das ViewModel mit einer Creature oder erstellt eine neue
  Future<void> initialize(Creature? creature) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (creature != null) {
        _creature = creature;
      } else {
        _creature = Creature(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '',
          maxHp: 10,
          currentHp: 10,
          armorClass: 10,
          speed: "30ft",
          attacks: "",
          initiativeBonus: 0,
          isPlayer: false,
          strength: 10,
          dexterity: 10,
          constitution: 10,
          intelligence: 10,
          wisdom: 10,
          charisma: 10,
        );
      }
      
      _resetUnsavedChanges();
      notifyListeners();
    } catch (e) {
      _setError('Initialisierung fehlgeschlagen: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Speichert die aktuelle Creature
  Future<bool> saveCreature() async {
    if (_creature == null || !_hasValidCreature()) {
      _setError('Ungültige Creature-Daten');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      // Prüfe ob Creature bereits in DB existiert
      final exists = await _repository.exists(_creature!.id);
      
      if (exists) {
        // Update bestehende Creature
        _creature = await _repository.update(_creature!);
      } else {
        // Erstelle neue Creature
        _creature = await _repository.create(_creature!);
      }
      
      _resetUnsavedChanges();
      return true;
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Speichern fehlgeschlagen: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Löscht die aktuelle Creature
  Future<bool> deleteCreature() async {
    if (_creature == null) {
      _setError('Keine Creature zum Löschen vorhanden');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      // Echte Datenbankoperation über Repository
      await _repository.delete(_creature!.id);
      return true;
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Löschen fehlgeschlagen: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dupliziert die aktuelle Creature
  Future<void> duplicateCreature() async {
    if (_creature == null) return;

    try {
      final duplicatedCreature = CreatureHelperService.copyWith(
        _creature!,
        name: '${_creature!.name} (Kopie)',
        isCustom: true, // Duplikate sind immer custom
        sourceType: 'custom',
        isFavorite: false,
        version: '1.0',
      );
      
      _creature = duplicatedCreature;
      _markAsUnsaved();
      notifyListeners();
    } catch (e) {
      _setError('Duplizieren fehlgeschlagen: ${e.toString()}');
    }
  }

  // Update-Methoden für einzelne Felder
  void updateName(String name) {
    if (_creature?.name != name) {
      _creature = _creature!.copyWith(name: name);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateDescription(String description) {
    if (_creature?.description != description) {
      _creature = _creature!.copyWith(description: description);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateType(String? type) {
    if (_creature?.type != type) {
      _creature = _creature!.copyWith(type: type);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateSubtype(String? subtype) {
    if (_creature?.subtype != subtype) {
      _creature = _creature!.copyWith(subtype: subtype);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateChallengeRating(int? challengeRating) {
    if (_creature?.challengeRating != challengeRating) {
      _creature = _creature!.copyWith(challengeRating: challengeRating);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateMaxHp(int maxHp) {
    if (_creature?.maxHp != maxHp) {
      _creature = _creature!.copyWith(maxHp: maxHp);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateCurrentHp(int currentHp) {
    if (_creature?.currentHp != currentHp) {
      _creature = _creature!.copyWith(currentHp: currentHp);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateArmorClass(int armorClass) {
    if (_creature?.armorClass != armorClass) {
      _creature = _creature!.copyWith(armorClass: armorClass);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateSpeed(String speed) {
    if (_creature?.speed != speed) {
      _creature = _creature!.copyWith(speed: speed);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateSize(String? size) {
    if (_creature?.size != size) {
      _creature = _creature!.copyWith(size: size);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateAlignment(String? alignment) {
    if (_creature?.alignment != alignment) {
      _creature = _creature!.copyWith(alignment: alignment);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateAttacks(String attacks) {
    if (_creature?.attacks != attacks) {
      _creature = _creature!.copyWith(attacks: attacks);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateSpecialAbilities(String? specialAbilities) {
    if (_creature?.specialAbilities != specialAbilities) {
      _creature = _creature!.copyWith(specialAbilities: specialAbilities);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateLegendaryActions(String? legendaryActions) {
    if (_creature?.legendaryActions != legendaryActions) {
      _creature = _creature!.copyWith(legendaryActions: legendaryActions);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  // Update-Methoden für Attribute
  void updateStrength(int strength) {
    if (_creature?.strength != strength) {
      _creature = _creature!.copyWith(strength: strength);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateDexterity(int dexterity) {
    if (_creature?.dexterity != dexterity) {
      _creature = _creature!.copyWith(dexterity: dexterity);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateConstitution(int constitution) {
    if (_creature?.constitution != constitution) {
      _creature = _creature!.copyWith(constitution: constitution);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateIntelligence(int intelligence) {
    if (_creature?.intelligence != intelligence) {
      _creature = _creature!.copyWith(intelligence: intelligence);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateWisdom(int wisdom) {
    if (_creature?.wisdom != wisdom) {
      _creature = _creature!.copyWith(wisdom: wisdom);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateCharisma(int charisma) {
    if (_creature?.charisma != charisma) {
      _creature = _creature!.copyWith(charisma: charisma);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateInitiativeBonus(int initiativeBonus) {
    if (_creature?.initiativeBonus != initiativeBonus) {
      _creature = _creature!.copyWith(initiativeBonus: initiativeBonus);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateIsPlayer(bool isPlayer) {
    if (_creature?.isPlayer != isPlayer) {
      // Da CreatureHelperService.copyWith isPlayer nicht unterstützt, erstellen wir manuell
      _creature = Creature(
        id: _creature!.id,
        name: _creature!.name,
        maxHp: _creature!.maxHp,
        currentHp: _creature!.currentHp,
        armorClass: _creature!.armorClass,
        speed: _creature!.speed,
        attacks: _creature!.attacks,
        initiativeBonus: _creature!.initiativeBonus,
        isPlayer: isPlayer,
        strength: _creature!.strength,
        dexterity: _creature!.dexterity,
        constitution: _creature!.constitution,
        intelligence: _creature!.intelligence,
        wisdom: _creature!.wisdom,
        charisma: _creature!.charisma,
        inventory: _creature!.inventory,
        gold: _creature!.gold,
        silver: _creature!.silver,
        copper: _creature!.copper,
        officialMonsterId: _creature!.officialMonsterId,
        officialSpellIds: _creature!.officialSpellIds,
        officialItemIds: _creature!.officialItemIds,
        size: _creature!.size,
        type: _creature!.type,
        subtype: _creature!.subtype,
        alignment: _creature!.alignment,
        challengeRating: _creature!.challengeRating,
        specialAbilities: _creature!.specialAbilities,
        legendaryActions: _creature!.legendaryActions,
        isCustom: _creature!.isCustom,
        description: _creature!.description,
        attackList: _creature!.attackList,
        sourceType: _creature!.sourceType,
        sourceId: _creature!.sourceId,
        isFavorite: _creature!.isFavorite,
        version: _creature!.version,
        conditions: _creature!.conditions,
        initiative: _creature!.initiative,
      );
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateIsFavorite(bool isFavorite) {
    if (_creature?.isFavorite != isFavorite) {
      _creature = CreatureHelperService.copyWith(_creature!, isFavorite: isFavorite);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateGold(double gold) {
    if (_creature?.gold != gold) {
      _creature = CreatureHelperService.copyWith(_creature!, gold: gold);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateSilver(double silver) {
    if (_creature?.silver != silver) {
      _creature = CreatureHelperService.copyWith(_creature!, silver: silver);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateCopper(double copper) {
    if (_creature?.copper != copper) {
      _creature = CreatureHelperService.copyWith(_creature!, copper: copper);
      _markAsUnsaved();
      notifyListeners();
    }
  }

  // Inventory-Methoden für Map-basiertes Inventar
  void addInventoryItem(Map<String, dynamic> newItem) {
    if (_creature != null) {
      final updatedInventory = List<Map<String, dynamic>>.from(_creature!.inventory);
      updatedInventory.add(newItem);
      
      _creature = Creature(
        id: _creature!.id,
        name: _creature!.name,
        maxHp: _creature!.maxHp,
        currentHp: _creature!.currentHp,
        armorClass: _creature!.armorClass,
        speed: _creature!.speed,
        attacks: _creature!.attacks,
        initiativeBonus: _creature!.initiativeBonus,
        isPlayer: _creature!.isPlayer,
        strength: _creature!.strength,
        dexterity: _creature!.dexterity,
        constitution: _creature!.constitution,
        intelligence: _creature!.intelligence,
        wisdom: _creature!.wisdom,
        charisma: _creature!.charisma,
        inventory: updatedInventory,
        gold: _creature!.gold,
        silver: _creature!.silver,
        copper: _creature!.copper,
        officialMonsterId: _creature!.officialMonsterId,
        officialSpellIds: _creature!.officialSpellIds,
        officialItemIds: _creature!.officialItemIds,
        size: _creature!.size,
        type: _creature!.type,
        subtype: _creature!.subtype,
        alignment: _creature!.alignment,
        challengeRating: _creature!.challengeRating,
        specialAbilities: _creature!.specialAbilities,
        legendaryActions: _creature!.legendaryActions,
        isCustom: _creature!.isCustom,
        description: _creature!.description,
        attackList: _creature!.attackList,
        sourceType: _creature!.sourceType,
        sourceId: _creature!.sourceId,
        isFavorite: _creature!.isFavorite,
        version: _creature!.version,
        conditions: _creature!.conditions,
        initiative: _creature!.initiative,
      );
      
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void removeInventoryItem(int index) {
    if (_creature != null && index >= 0 && index < _creature!.inventory.length) {
      final updatedInventory = List<Map<String, dynamic>>.from(_creature!.inventory);
      updatedInventory.removeAt(index);
      
      _creature = Creature(
        id: _creature!.id,
        name: _creature!.name,
        maxHp: _creature!.maxHp,
        currentHp: _creature!.currentHp,
        armorClass: _creature!.armorClass,
        speed: _creature!.speed,
        attacks: _creature!.attacks,
        initiativeBonus: _creature!.initiativeBonus,
        isPlayer: _creature!.isPlayer,
        strength: _creature!.strength,
        dexterity: _creature!.dexterity,
        constitution: _creature!.constitution,
        intelligence: _creature!.intelligence,
        wisdom: _creature!.wisdom,
        charisma: _creature!.charisma,
        inventory: updatedInventory,
        gold: _creature!.gold,
        silver: _creature!.silver,
        copper: _creature!.copper,
        officialMonsterId: _creature!.officialMonsterId,
        officialSpellIds: _creature!.officialSpellIds,
        officialItemIds: _creature!.officialItemIds,
        size: _creature!.size,
        type: _creature!.type,
        subtype: _creature!.subtype,
        alignment: _creature!.alignment,
        challengeRating: _creature!.challengeRating,
        specialAbilities: _creature!.specialAbilities,
        legendaryActions: _creature!.legendaryActions,
        isCustom: _creature!.isCustom,
        description: _creature!.description,
        attackList: _creature!.attackList,
        sourceType: _creature!.sourceType,
        sourceId: _creature!.sourceId,
        isFavorite: _creature!.isFavorite,
        version: _creature!.version,
        conditions: _creature!.conditions,
        initiative: _creature!.initiative,
      );
      
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateInventoryItem(int index, Map<String, dynamic> updatedItem) {
    if (_creature != null && index >= 0 && index < _creature!.inventory.length) {
      final updatedInventory = List<Map<String, dynamic>>.from(_creature!.inventory);
      updatedInventory[index] = updatedItem;
      
      _creature = Creature(
        id: _creature!.id,
        name: _creature!.name,
        maxHp: _creature!.maxHp,
        currentHp: _creature!.currentHp,
        armorClass: _creature!.armorClass,
        speed: _creature!.speed,
        attacks: _creature!.attacks,
        initiativeBonus: _creature!.initiativeBonus,
        isPlayer: _creature!.isPlayer,
        strength: _creature!.strength,
        dexterity: _creature!.dexterity,
        constitution: _creature!.constitution,
        intelligence: _creature!.intelligence,
        wisdom: _creature!.wisdom,
        charisma: _creature!.charisma,
        inventory: updatedInventory,
        gold: _creature!.gold,
        silver: _creature!.silver,
        copper: _creature!.copper,
        officialMonsterId: _creature!.officialMonsterId,
        officialSpellIds: _creature!.officialSpellIds,
        officialItemIds: _creature!.officialItemIds,
        size: _creature!.size,
        type: _creature!.type,
        subtype: _creature!.subtype,
        alignment: _creature!.alignment,
        challengeRating: _creature!.challengeRating,
        specialAbilities: _creature!.specialAbilities,
        legendaryActions: _creature!.legendaryActions,
        isCustom: _creature!.isCustom,
        description: _creature!.description,
        attackList: _creature!.attackList,
        sourceType: _creature!.sourceType,
        sourceId: _creature!.sourceId,
        isFavorite: _creature!.isFavorite,
        version: _creature!.version,
        conditions: _creature!.conditions,
        initiative: _creature!.initiative,
      );
      
      _markAsUnsaved();
      notifyListeners();
    }
  }

  /// Setzt die Änderungen zurück
  void resetChanges() async {
    if (_creature != null && isEditing) {
      // In einer echten Implementierung würden wir die Original-Daten neu laden
      _clearError();
      _resetUnsavedChanges();
      notifyListeners();
    }
  }

  /// Löscht die Fehlermeldung
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private Helper-Methoden
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _markAsUnsaved() {
    _hasUnsavedChanges = true;
  }

  void _resetUnsavedChanges() {
    _hasUnsavedChanges = false;
  }

  bool _hasValidCreature() {
    if (_creature == null) return false;
    
    // Grundlegende Validierung
    return _creature!.name.trim().isNotEmpty &&
           _creature!.maxHp > 0 &&
           _creature!.armorClass >= 0;
  }
}
