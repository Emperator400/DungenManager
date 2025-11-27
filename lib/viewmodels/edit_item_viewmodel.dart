import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/uuid_service.dart';

/// ViewModel für das Editieren von Items
class EditItemViewModel extends ChangeNotifier {
  final UuidService _uuidService = UuidService();
  
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
      id: _uuidService.generateId(),
      name: '',
      itemType: ItemType.Weapon,
    );
    _hasUnsavedChanges = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Aktualisiert den Namen des Items
  void updateName(String name) {
    if (_item != null && _item!.name != name) {
      _item = _item!.copyWith(name: name);
      _markAsChanged();
    }
  }

  /// Aktualisiert die Beschreibung des Items
  void updateDescription(String description) {
    if (_item != null && _item!.description != description) {
      _item = _item!.copyWith(description: description);
      _markAsChanged();
    }
  }

  /// Aktualisiert den Typ des Items
  void updateType(ItemType type) {
    if (_item != null && _item!.itemType != type) {
      _item = _item!.copyWith(itemType: type);
      _markAsChanged();
    }
  }

  /// Aktualisiert die Seltenheit des Items
  void updateRarity(String? rarity) {
    if (_item != null && _item!.rarity != rarity) {
      _item = _item!.copyWith(rarity: rarity);
      _markAsChanged();
    }
  }

  /// Aktualisiert den Wert des Items
  void updateValue(double value) {
    if (_item != null && _item!.cost != value) {
      _item = _item!.copyWith(cost: value);
      _markAsChanged();
    }
  }

  /// Aktualisiert das Gewicht des Items
  void updateWeight(double weight) {
    if (_item != null && _item!.weight != weight) {
      _item = _item!.copyWith(weight: weight);
      _markAsChanged();
    }
  }

  /// Aktualisiert die Eigenschaften des Items
  void updateProperties(String properties) {
    if (_item != null && _item!.properties != properties) {
      _item = _item!.copyWith(properties: properties);
      _markAsChanged();
    }
  }

  /// Speichert das Item
  Future<bool> saveItem() async {
    if (!isValid) {
      _errorMessage = 'Bitte füllen Sie alle Pflichtfelder aus';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      // Hier würde die tatsächliche Speicherung in der Datenbank erfolgen
      // Für jetzt simulieren wir den Speichervorgang
      await Future.delayed(const Duration(milliseconds: 500));
      
      _hasUnsavedChanges = false;
      _setLoading(false);
      
      // Navigation zurück zur Liste würde hier erfolgen
      return true;
    } catch (e) {
      _errorMessage = 'Fehler beim Speichern: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Löscht das Item
  Future<bool> deleteItem() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Hier würde das tatsächliche Löschen in der Datenbank erfolgen
      await Future.delayed(const Duration(milliseconds: 300));
      
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
