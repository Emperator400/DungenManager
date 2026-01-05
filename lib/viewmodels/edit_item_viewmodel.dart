import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/uuid_service.dart';
import '../database/repositories/item_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für das Editieren von Items mit neuer Repository-Architektur
/// 
/// HINWEIS: Verwendet jetzt das neue ItemModelRepository
class EditItemViewModel extends ChangeNotifier {
  final UuidService _uuidService = UuidService();
  final ItemModelRepository _itemRepository;

  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  /// 
  EditItemViewModel({ItemModelRepository? itemRepository})
      : _itemRepository = itemRepository ?? ItemModelRepository(DatabaseConnection.instance);
  
  // State variables
  Item? _item;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Getters
  Item? get item => _item;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isValid => _item?.name.trim().isNotEmpty == true && _item!.name.trim().length >= 2;

  /// Initialisiert das ViewModel mit einem existierenden Item oder erstellt ein neues
  void initialize(Item? item) {
    _item = item ?? Item(
      id: 'new_${_uuidService.generateId()}',
      name: '',
      itemType: ItemType.Weapon,
    );
    _hasUnsavedChanges = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Aktualisiert den Namen des Items
  /// HINWEIS: Items haben keine copyWith-Methode, daher wird hier neu erstellt
  void updateName(String name) {
    if (_item != null && _item!.name != name) {
      _item = Item(
        id: _item!.id,
        name: name,
        itemType: _item!.itemType,
        rarity: _item!.rarity,
        cost: _item!.cost,
        weight: _item!.weight,
        description: _item!.description,
        properties: _item!.properties,
        damage: _item!.damage,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert die Beschreibung des Items
  /// HINWEIS: Items haben keine copyWith-Methode, daher wird hier neu erstellt
  void updateDescription(String description) {
    if (_item != null && _item!.description != description) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        rarity: _item!.rarity,
        cost: _item!.cost,
        weight: _item!.weight,
        description: description,
        properties: _item!.properties,
        damage: _item!.damage,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert den Typ des Items
  /// HINWEIS: Items haben keine copyWith-Methode, daher wird hier neu erstellt
  void updateType(ItemType type) {
    if (_item != null && _item!.itemType != type) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: type,
        rarity: _item!.rarity,
        cost: _item!.cost,
        weight: _item!.weight,
        description: _item!.description,
        properties: _item!.properties,
        damage: _item!.damage,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert die Seltenheit des Items
  /// HINWEIS: Items haben keine copyWith-Methode, daher wird hier neu erstellt
  void updateRarity(String? rarity) {
    if (_item != null && _item!.rarity != rarity) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        rarity: rarity,
        cost: _item!.cost,
        weight: _item!.weight,
        description: _item!.description,
        properties: _item!.properties,
        damage: _item!.damage,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert den Wert des Items
  /// HINWEIS: Items haben keine copyWith-Methode, daher wird hier neu erstellt
  void updateValue(double value) {
    if (_item != null && _item!.cost != value) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        rarity: _item!.rarity,
        cost: value,
        weight: _item!.weight,
        description: _item!.description,
        properties: _item!.properties,
        damage: _item!.damage,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert das Gewicht des Items
  /// HINWEIS: Items haben keine copyWith-Methode, daher wird hier neu erstellt
  void updateWeight(double weight) {
    if (_item != null && _item!.weight != weight) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        rarity: _item!.rarity,
        cost: _item!.cost,
        weight: weight,
        description: _item!.description,
        properties: _item!.properties,
        damage: _item!.damage,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert den Schaden des Items (für Waffen)
  /// HINWEIS: Items haben keine copyWith-Methode, daher wird hier neu erstellt
  void updateDamage(String? damage) {
    if (_item != null && _item!.damage != damage) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        rarity: _item!.rarity,
        cost: _item!.cost,
        weight: _item!.weight,
        description: _item!.description,
        properties: _item!.properties,
        damage: damage,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert die Eigenschaften des Items
  /// HINWEIS: Items haben keine copyWith-Methode, daher wird hier neu erstellt
  void updateProperties(String properties) {
    if (_item != null && _item!.properties != properties) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        rarity: _item!.rarity,
        cost: _item!.cost,
        weight: _item!.weight,
        description: _item!.description,
        properties: properties,
        damage: _item!.damage,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert die Rüstungsklasse (AC) für Rüstungen
  void updateAcFormula(String? acFormula) {
    if (_item != null && _item!.acFormula != acFormula) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        description: _item!.description,
        acFormula: acFormula,
        damage: _item!.damage,
        properties: _item!.properties,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert die Stärkenanforderung für Rüstungen
  void updateStrengthRequirement(int? strength) {
    if (_item != null && _item!.strengthRequirement != strength) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        description: _item!.description,
        strengthRequirement: strength,
        damage: _item!.damage,
        properties: _item!.properties,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert Nachteil auf Verstecken (Stealth Disadvantage)
  void updateStealthDisadvantage(bool? value) {
    if (_item != null && _item!.stealthDisadvantage != value) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        description: _item!.description,
        stealthDisadvantage: value,
        damage: _item!.damage,
        properties: _item!.properties,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert Attunement-Anforderung
  void updateRequiresAttunement(bool? value) {
    if (_item != null && _item!.requiresAttunement != value) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        description: _item!.description,
        requiresAttunement: value,
        damage: _item!.damage,
        properties: _item!.properties,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert Haltbarkeit
  void updateHasDurability(bool? value) {
    if (_item != null && _item!.hasDurability != value) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        description: _item!.description,
        hasDurability: value,
        damage: _item!.damage,
        properties: _item!.properties,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert maximale Haltbarkeit
  void updateMaxDurability(int? value) {
    if (_item != null && _item!.maxDurability != value) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        description: _item!.description,
        maxDurability: value,
        damage: _item!.damage,
        properties: _item!.properties,
      );
      _markAsChanged();
    }
  }

  /// Aktualisiert Reparierbarkeit
  void updateIsRepairable(bool? value) {
    if (_item != null && _item!.isRepairable != value) {
      _item = Item(
        id: _item!.id,
        name: _item!.name,
        itemType: _item!.itemType,
        description: _item!.description,
        isRepairable: value,
        damage: _item!.damage,
        properties: _item!.properties,
      );
      _markAsChanged();
    }
  }

  /// Speichert das Item über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<bool> saveItem() async {
    print('📝 [EditItemViewModel] saveItem() aufgerufen');
    print('📝 [EditItemViewModel] Item: ${_item?.name}, ID: ${_item?.id}');
    print('📝 [EditItemViewModel] Item gültig: $isValid');
    
    if (!isValid) {
      _errorMessage = 'Bitte füllen Sie alle Pflichtfelder aus';
      print('❌ [EditItemViewModel] Ungültig: $_errorMessage');
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      if (_item!.id.isEmpty || _item!.id.startsWith('new_')) {
        // Create new item
        print('🆕 [EditItemViewModel] Erstelle neues Item...');
        
        // Entferne das "new_" Präfix VOR dem Speichern, damit die DB die saubere ID bekommt
        String finalId = _item!.id;
        if (_item!.id.startsWith('new_')) {
          finalId = _item!.id.substring(4);
          print('🔄 [EditItemViewModel] "new_" Präfix entfernt vor dem Speichern: $finalId');
          _item = Item(
            id: finalId,
            name: _item!.name,
            itemType: _item!.itemType,
            rarity: _item!.rarity,
            cost: _item!.cost,
            weight: _item!.weight,
            description: _item!.description,
            properties: _item!.properties,
            damage: _item!.damage,
          );
        }
        
        final savedItem = await _itemRepository.create(_item!);
        print('✅ [EditItemViewModel] Item erstellt: ${savedItem?.name}, ID: ${savedItem?.id}');
        if (savedItem != null) {
          _item = savedItem;
        }
      } else {
        // Update existing item
        print('🔄 [EditItemViewModel] Aktualisiere existierendes Item: ${_item!.id}');
        final updatedItem = await _itemRepository.update(_item!);
        print('✅ [EditItemViewModel] Item aktualisiert: ${updatedItem?.name}, ID: ${updatedItem?.id}');
        if (updatedItem != null) {
          _item = updatedItem;
        }
      }
      
      _hasUnsavedChanges = false;
      _setLoading(false);
      print('✅ [EditItemViewModel] Speichern erfolgreich!');
      
      return true;
    } catch (e) {
      _errorMessage = 'Fehler beim Speichern: ${e.toString()}';
      print('❌ [EditItemViewModel] Fehler beim Speichern: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Löscht das Item über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<bool> deleteItem() async {
    if (_item?.id.isEmpty == true || _item?.id.startsWith('new_') == true) {
      _errorMessage = 'Item kann nicht gelöscht werden: Nicht gespeichert';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _itemRepository.delete(_item!.id);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Fehler beim Löschen: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Setzt die Formular-Daten zurück
  void resetForm() {
    _item = Item(
      id: _uuidService.generateId(),
      name: '',
      itemType: ItemType.Weapon,
    );
    _hasUnsavedChanges = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Setzt das Formular auf die ursprünglichen Werte zurück
  void undoChanges() {
    initialize(null); // Reset to original or new item
  }

  /// Markiert das Item als geändert
  void _markAsChanged() {
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Setzt den Ladezustand
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Löscht die Fehlermeldung
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
