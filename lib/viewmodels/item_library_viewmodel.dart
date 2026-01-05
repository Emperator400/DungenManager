import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../database/repositories/item_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für die Item Library mit neuer Repository-Architektur
/// Zentralisiert State Management und Business-Logik für Items
/// 
/// HINWEIS: Verwendet jetzt das neue ItemModelRepository
class ItemLibraryViewModel extends ChangeNotifier {
  final ItemModelRepository? _itemRepository;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  List<Item> _items = [];
  List<Item> _filteredItems = [];
  bool _isLoading = false;
  String? _error;

  // Filter-Zustände
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedRarity;
  double _minCost = 0.0;
  double _maxCost = 1000.0;
  bool _showFavoritesOnly = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  List<Item> get items => List.unmodifiable(_items);
  List<Item> get filteredItems => List.unmodifiable(_filteredItems);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;
  String? get selectedRarity => _selectedRarity;
  double get minCost => _minCost;
  double get maxCost => _maxCost;
  bool get showFavoritesOnly => _showFavoritesOnly;

  /// Prüft ob Filter aktiv sind
  bool get hasActiveFilters => 
      _searchQuery.isNotEmpty || 
      _selectedType != null || 
      _selectedRarity != null || 
      _showFavoritesOnly ||
      _minCost > 0.0 ||
      _maxCost < 1000.0;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  /// 
  ItemLibraryViewModel({
    ItemModelRepository? itemRepository,
  }) : _itemRepository = itemRepository ?? ItemModelRepository(DatabaseConnection.instance);

  // ============================================================================
  // ITEM MANAGEMENT
  // ============================================================================

  /// Lädt alle Items aus der Datenbank über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> loadItems() async {
    print('📚 [ItemLibraryViewModel] loadItems() aufgerufen');
    await _executeWithErrorHandling(() async {
      if (_itemRepository != null) {
        _items = await _itemRepository!.findAll();
        print('📚 [ItemLibraryViewModel] ${_items.length} Items geladen');
        for (var item in _items) {
          print('  - ${item.name} (ID: ${item.id})');
        }
      } else {
        _items = [];
        print('⚠️ [ItemLibraryViewModel] Repository ist null');
      }
      _applyFiltersAndSort();
      print('✅ [ItemLibraryViewModel] Filter angewendet: ${_filteredItems.length} Items');
    });
  }

  /// Lädt Items nach Typ über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> loadItemsByType(String itemType) async {
    await _executeWithErrorHandling(() async {
      if (_itemRepository != null) {
        _items = await _itemRepository!.findAll();
        // Filtern nach Typ im ViewModel
        _items = _items.where((item) => item.itemType == itemType).toList();
      } else {
        _items = [];
      }
      _applyFiltersAndSort();
    });
  }

  /// Lädt Items nach Seltenheit über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> loadItemsByRarity(String rarity) async {
    await _executeWithErrorHandling(() async {
      if (_itemRepository != null) {
        _items = await _itemRepository!.findAll();
        // Filtern nach Seltenheit im ViewModel
        _items = _items.where((item) => item.rarity == rarity).toList();
      } else {
        _items = [];
      }
      _applyFiltersAndSort();
    });
  }

  /// Lädt Favoriten-Items über neues Repository
  /// 
  /// HINWEIS: Items haben keine isFavorite-Eigenschaft, daher gibt es keine Favoriten
  Future<void> loadFavoriteItems() async {
    // Items haben kein isFavorite-Feld, daher leere Liste
    await _executeWithErrorHandling(() async {
      _items = [];
      _applyFiltersAndSort();
    });
  }

  /// Sucht Items über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> searchItems(String query) async {
    await _executeWithErrorHandling(() async {
      if (_itemRepository != null) {
        _items = await _itemRepository!.search(query);
      } else {
        _items = [];
      }
      _applyFiltersAndSort();
    });
  }

  /// Löscht ein Item über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> deleteItem(String itemId) async {
    await _executeWithErrorHandling(() async {
      if (_itemRepository != null) {
        await _itemRepository!.delete(itemId);
      }
      _items.removeWhere((item) => item.id == itemId);
      _applyFiltersAndSort();
    });
  }

  /// Erstellt ein neues Item über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> createItem(Item item) async {
    await _executeWithErrorHandling(() async {
      Item? savedItem;
      
      if (_itemRepository != null) {
        savedItem = await _itemRepository!.create(item);
      }
      
      if (savedItem != null) {
        _items.add(savedItem);
        _applyFiltersAndSort();
      }
    });
  }

  /// Aktualisiert ein Item über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> updateItem(Item item) async {
    await _executeWithErrorHandling(() async {
      Item? updatedItem;
      
      if (_itemRepository != null) {
        updatedItem = await _itemRepository!.update(item);
      }
      
      if (updatedItem != null) {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = updatedItem;
        }
        _applyFiltersAndSort();
      }
    });
  }

  /// Items haben keine Favoriten-Funktionalität
  /// 
  /// HINWEIS: Items haben keine isFavorite-Eigenschaft
  Future<void> toggleFavorite(Item item) async {
    // Items haben kein isFavorite-Feld, daher keine Funktionalität
    throw UnimplementedError('Items haben keine Favoriten-Funktionalität');
  }

  /// Batch-Operation: Löscht mehrere Items auf einmal
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> deleteItems(List<String> itemIds) async {
    await _executeWithErrorHandling(() async {
      if (_itemRepository != null) {
        await _itemRepository!.deleteAll(itemIds);
      }
      _items.removeWhere((item) => itemIds.contains(item.id));
      _applyFiltersAndSort();
    });
  }

  /// Batch-Operation: Aktualisiert mehrere Items auf einmal
  /// 
  /// HINWEIS: Verwendet jetzt das neue ItemModelRepository
  Future<void> updateItems(List<Item> items) async {
    await _executeWithErrorHandling(() async {
      if (_itemRepository != null) {
        await _itemRepository!.updateAll(items);
      }
      
      // Lokalen State aktualisieren
      for (final item in items) {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item;
        }
      }
      
      _applyFiltersAndSort();
    });
  }

  // ============================================================================
  // FILTER UND SUCHE
  // ============================================================================

  /// Setzt den Suchtext
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Typ-Filter
  void setTypeFilter(String? type) {
    _selectedType = type;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Seltenheit-Filter
  void setRarityFilter(String? rarity) {
    _selectedRarity = rarity;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Kostenbereich
  void setCostRange(double min, double max) {
    _minCost = min;
    _maxCost = max;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Favoriten-Filter
  /// 
  /// HINWEIS: Items haben keine isFavorite-Eigenschaft, daher hat dieser Filter keine Wirkung
  void setFavoritesFilter(bool showOnly) {
    _showFavoritesOnly = showOnly;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Löscht alle Filter
  void clearAllFilters() {
    _searchQuery = '';
    _selectedType = null;
    _selectedRarity = null;
    _minCost = 0.0;
    _maxCost = 1000.0;
    _showFavoritesOnly = false;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Wendet Filter und Sortierung an
  void _applyFiltersAndSort() {
    _filteredItems = _items.where((item) {
      // Suchtext filtern
      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        final nameMatch = item.name.toLowerCase().contains(queryLower);
        final descriptionMatch = item.description.toLowerCase().contains(queryLower);
        final propertiesMatch = item.properties?.toLowerCase().contains(queryLower) ?? false;
        
        if (!(nameMatch || descriptionMatch || propertiesMatch)) {
          return false;
        }
      }

      // Typ filtern
      if (_selectedType != null && item.itemType != _selectedType) {
        return false;
      }

      // Seltenheit filtern
      if (_selectedRarity != null && item.rarity != _selectedRarity) {
        return false;
      }

      // Kosten filtern
      if (item.cost < _minCost || item.cost > _maxCost) {
        return false;
      }

      // Favoriten filtern
      // Items haben kein isFavorite-Feld, daher wird immer true zurückgegeben
      if (_showFavoritesOnly) {
        return false;
      }

      return true;
    }).toList();

    // Standard-Sortierung: Name
    _filteredItems.sort((a, b) => a.name.compareTo(b.name));
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
  // DISPOSE
  // ============================================================================

  @override
  void dispose() {
    super.dispose();
  }
}
