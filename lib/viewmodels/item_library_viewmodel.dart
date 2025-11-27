import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../database/database_helper.dart';

/// ViewModel für die Item Library
/// Zentralisiert State Management und Business-Logik für Items
class ItemLibraryViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  // ============================================================================
  // GETTERS
  // ============================================================================

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  ItemLibraryViewModel({
    DatabaseHelper? dbHelper,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ============================================================================
  // ITEM MANAGEMENT
  // ============================================================================

  /// Lädt alle Items aus der Datenbank
  Future<void> loadItems() async {
    await _executeWithErrorHandling(() async {
      _items = await _dbHelper.getAllItems();
    });
  }

  /// Löscht ein Item
  Future<void> deleteItem(String itemId) async {
    await _executeWithErrorHandling(() async {
      await _dbHelper.deleteItem(itemId);
      _items.removeWhere((item) => item.id == itemId);
    });
  }

  /// Erstellt ein neues Item
  Future<void> createItem(Item item) async {
    await _executeWithErrorHandling(() async {
      await _dbHelper.insertItem(item);
      _items.add(item);
    });
  }

  /// Aktualisiert ein Item
  Future<void> updateItem(Item item) async {
    await _executeWithErrorHandling(() async {
      await _dbHelper.updateItem(item);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item;
      }
    });
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
