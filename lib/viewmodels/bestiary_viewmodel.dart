import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/creature.dart';
import '../database/repositories/creature_model_repository.dart';
import '../database/core/database_connection.dart';
import '../game_data/dnd_data_importer.dart';

/// ViewModel für das Bestiarum mit neuer Repository-Architektur
/// Zentralisiert State Management und Business-Logik für Kreaturen
class BestiaryViewModel extends ChangeNotifier {
  final CreatureModelRepository? _creatureRepository;
  final DndDataImporter _dataImporter;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // Creature Daten
  List<Creature> _allCreatures = [];
  List<Creature> _customCreatures = [];
  List<Creature> _officialCreatures = [];
  List<Map<String, dynamic>> _availableMonsters = [];
  List<Map<String, dynamic>> _availableSpells = [];
  
  // Loading States
  bool _isLoading = false;
  bool _isLoadingDndData = false;
  String? _error;

  // Filter States
  String _searchQuery = '';
  String _selectedSourceType = 'all';
  String _selectedType = 'all';
  String _selectedSize = 'all';
  bool _showFavoritesOnly = false;
  bool _sortByChallengeRating = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  List<Creature> get allCreatures => _allCreatures;
  List<Creature> get customCreatures => _customCreatures;
  List<Creature> get officialCreatures => _officialCreatures;
  List<Map<String, dynamic>> get availableMonsters => _availableMonsters;
  List<Map<String, dynamic>> get availableSpells => _availableSpells;
  bool get isLoading => _isLoading;
  bool get isLoadingDndData => _isLoadingDndData;
  String? get error => _error;
  
  String get searchQuery => _searchQuery;
  String get selectedSourceType => _selectedSourceType;
  String get selectedType => _selectedType;
  String get selectedSize => _selectedSize;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get sortByChallengeRating => _sortByChallengeRating;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  /// 
  BestiaryViewModel({
    CreatureModelRepository? creatureRepository,
    DndDataImporter? dataImporter,
  }) : _creatureRepository = creatureRepository ?? CreatureModelRepository(DatabaseConnection.instance),
       _dataImporter = dataImporter ?? DndDataImporter();

  // ============================================================================
  // DATA LOADING
  // ============================================================================

  /// Lädt alle Kreaturen aus der Datenbank über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> loadCreatures() async {
    await _executeWithErrorHandling(() async {
      if (_creatureRepository != null) {
        _allCreatures = await _creatureRepository!.findAll();
        _customCreatures = _allCreatures.where((c) => c.sourceType == 'custom').toList();
        _officialCreatures = _allCreatures.where((c) => c.sourceType == 'official').toList();
      } else {
        _allCreatures = [];
        _customCreatures = [];
        _officialCreatures = [];
      }
    });
  }

  /// Lädt D&D-Daten (Monster und Zauber) - Legacy Methode für Übergangszeit
  Future<void> loadDndData() async {
    await _executeWithErrorHandling(() async {
      _isLoadingDndData = true;
      notifyListeners();
      
      try {
        // TODO: Migriere zu OfficialMonsterRepository wenn verfügbar
        // Für jetzt: Dummy-Implementierung
        _availableMonsters = [];
        _availableSpells = [];
      } finally {
        _isLoadingDndData = false;
        notifyListeners();
      }
    });
  }

  // ============================================================================
  // FILTERING AND SORTING
  // ============================================================================

  /// Filtert Kreaturen basierend auf aktuellen Filter-Kriterien
  List<Creature> filterCreatures(List<Creature> creatures) {
    return creatures.where((creature) {
      // Suchfilter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesName = creature.name.toLowerCase().contains(searchLower);
        final matchesType = creature.type?.toLowerCase().contains(searchLower) ?? false;
        final matchesSubtype = creature.subtype?.toLowerCase().contains(searchLower) ?? false;
        if (!matchesName && !matchesType && !matchesSubtype) return false;
      }

      // Source Type Filter
      if (_selectedSourceType != 'all' && creature.sourceType != _selectedSourceType) {
        return false;
      }

      // Type Filter
      if (_selectedType != 'all' && creature.type != _selectedType) {
        return false;
      }

      // Size Filter
      if (_selectedSize != 'all' && creature.size != _selectedSize) {
        return false;
      }

      // Favorites Filter
      if (_showFavoritesOnly && !creature.isFavorite) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Sortiert Kreaturen basierend auf aktuellen Sortier-Kriterien
  List<Creature> sortCreatures(List<Creature> creatures) {
    final sorted = List<Creature>.from(creatures);
    
    if (_sortByChallengeRating) {
      sorted.sort((a, b) {
        final aCr = a.challengeRating ?? 0;
        final bCr = b.challengeRating ?? 0;
        return aCr.compareTo(bCr);
      });
    } else {
      sorted.sort((a, b) => a.name.compareTo(b.name));
    }
    
    return sorted;
  }

  // ============================================================================
  // CREATURE MANAGEMENT
  // ============================================================================

  // ============================================================================
  // CREATURE MANAGEMENT MIT NEUER REPOSITORY-ARCHITEKTUR
  // ============================================================================

  /// Erstellt eine neue Kreatur über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> createCreature(Creature creature) async {
    await _executeWithErrorHandling(() async {
      Creature? savedCreature;
      
      if (_creatureRepository != null) {
        savedCreature = await _creatureRepository!.create(creature);
      }
      
      if (savedCreature != null) {
        _allCreatures.add(savedCreature);
        
        // Aktualisiere die gefilterten Listen
        if (savedCreature.sourceType == 'custom') {
          _customCreatures.add(savedCreature);
        } else if (savedCreature.sourceType == 'official') {
          _officialCreatures.add(savedCreature);
        }
      }
    });
  }

  /// Aktualisiert eine Kreatur über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> updateCreature(Creature creature) async {
    await _executeWithErrorHandling(() async {
      Creature? updatedCreature;
      
      if (_creatureRepository != null) {
        updatedCreature = await _creatureRepository!.update(creature);
      }
      
      if (updatedCreature != null) {
        // Update in allen Listen
        _updateCreatureInList(_allCreatures, updatedCreature);
        _updateCreatureInList(_customCreatures, updatedCreature);
        _updateCreatureInList(_officialCreatures, updatedCreature);
      }
    });
  }

  /// Löscht eine Kreatur über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> deleteCreature(String creatureId) async {
    await _executeWithErrorHandling(() async {
      if (_creatureRepository != null) {
        await _creatureRepository!.delete(creatureId);
      }
      
      _allCreatures.removeWhere((c) => c.id == creatureId);
      _customCreatures.removeWhere((c) => c.id == creatureId);
      _officialCreatures.removeWhere((c) => c.id == creatureId);
    });
  }

  /// Schaltet den Favoriten-Status einer Kreatur um über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> toggleFavorite(Creature creature) async {
    final updatedCreature = creature.copyWith(isFavorite: !creature.isFavorite);
    await updateCreature(updatedCreature);
  }

  /// Batch-Operation: Löscht mehrere Kreaturen auf einmal
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> deleteCreatures(List<String> creatureIds) async {
    await _executeWithErrorHandling(() async {
      if (_creatureRepository != null) {
        await _creatureRepository!.deleteAll(creatureIds);
      }
      
      _allCreatures.removeWhere((c) => creatureIds.contains(c.id));
      _customCreatures.removeWhere((c) => creatureIds.contains(c.id));
      _officialCreatures.removeWhere((c) => creatureIds.contains(c.id));
    });
  }

  /// Batch-Operation: Aktualisiert mehrere Kreaturen auf einmal
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> updateCreatures(List<Creature> creatures) async {
    await _executeWithErrorHandling(() async {
      if (_creatureRepository != null) {
        await _creatureRepository!.updateAll(creatures);
      }
      
      // Lokalen State aktualisieren
      for (final creature in creatures) {
        _updateCreatureInList(_allCreatures, creature);
        _updateCreatureInList(_customCreatures, creature);
        _updateCreatureInList(_officialCreatures, creature);
      }
    });
  }

  /// Sucht Kreaturen über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> searchCreatures(String query) async {
    await _executeWithErrorHandling(() async {
      if (_creatureRepository != null) {
        _allCreatures = await _creatureRepository!.search(query);
        _customCreatures = _allCreatures.where((c) => c.sourceType == 'custom').toList();
        _officialCreatures = _allCreatures.where((c) => c.sourceType == 'official').toList();
        _searchQuery = query;
      }
    });
  }

  // ============================================================================
  // IMPORT OPERATIONS
  // ============================================================================

  /// Importiert Monster von 5e.tools
  Future<int> importMonstersFrom5eTools() async {
    return await _executeWithErrorHandling(() async {
      return await _dataImporter.importMonsters();
    });
  }

  /// Importiert alle verfügbaren Monster (Methode in Entwicklung)
  Future<void> importAllMonsters() async {
    // TODO: Implementiere mit neuem CreatureRepository
    throw UnimplementedError('Muss mit neuem Repository implementiert werden');
  }

  /// Fügt ein einzelnes Monster zum Bestiarum hinzu (Methode in Entwicklung)
  Future<void> addMonsterToBestiary(Map<String, dynamic> monsterData) async {
    // TODO: Implementiere mit neuem CreatureRepository
    throw UnimplementedError('Muss mit neuem Repository implementiert werden');
  }

  // ============================================================================
  // MIGRATION OPERATIONS
  // ============================================================================

  /// Führt Migration auf Unified Schema durch
  /// HINWEIS: Die Migration ist eine komplexe Operation, die in Zukunft separat implementiert werden sollte
  /// Da die alte DatabaseHelper-Migration nicht mehr existiert, ist dies vorerst deaktiviert
  Future<void> migrateToUnifiedSchema() async {
    await _executeWithErrorHandling(() async {
      // TODO: Implementiere Migration mit neuer Repository-Architektur
      // Die alte migrateCreaturesToUnifiedSchema Methode existiert nicht mehr
      print('Migration ist vorübergehend deaktiviert - muss mit neuer Architektur implementiert werden');
    });
  }

  /// Synchronisiert offizielle Monster
  /// HINWEIS: Die Synchronisation ist eine komplexe Operation, die in Zukunft separat implementiert werden sollte
  /// Da die alte DatabaseHelper-Methode nicht mehr existiert, ist dies vorerst deaktiviert
  Future<void> syncOfficialMonsters() async {
    await _executeWithErrorHandling(() async {
      // TODO: Implementiere Synchronisation mit neuer Repository-Architektur
      // Die alte syncOfficialMonstersToCreatures Methode existiert nicht mehr
      print('Synchronisation ist vorübergehend deaktiviert - muss mit neuer Architektur implementiert werden');
    });
  }

  /// Setzt das Bestiarum zurück (löscht alle Kreaturen)
  /// 
  /// HINWEIS: Verwendet jetzt das neue CreatureModelRepository
  Future<void> resetBestiary() async {
    await _executeWithErrorHandling(() async {
      final allCreatures = List<Creature>.from(_allCreatures);
      for (final creature in allCreatures) {
        if (_creatureRepository != null && creature.id != null) {
          await _creatureRepository!.delete(creature.id!);
        }
      }
      
      _allCreatures.clear();
      _customCreatures.clear();
      _officialCreatures.clear();
    });
  }

  // ============================================================================
  // FILTER STATE MANAGEMENT
  // ============================================================================

  /// Aktualisiert Suchquery
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Aktualisiert Source Type Filter
  void updateSourceTypeFilter(String sourceType) {
    _selectedSourceType = sourceType;
    notifyListeners();
  }

  /// Aktualisiert Type Filter
  void updateTypeFilter(String type) {
    _selectedType = type;
    notifyListeners();
  }

  /// Aktualisiert Size Filter
  void updateSizeFilter(String size) {
    _selectedSize = size;
    notifyListeners();
  }

  /// Aktualisiert Favorites Filter
  void updateFavoritesFilter(bool showFavoritesOnly) {
    _showFavoritesOnly = showFavoritesOnly;
    notifyListeners();
  }

  /// Aktualisiert Sortierung
  void updateSortOrder(bool sortByChallengeRating) {
    _sortByChallengeRating = sortByChallengeRating;
    notifyListeners();
  }

  /// Setzt alle Filter zurück
  void resetFilters() {
    _searchQuery = '';
    _selectedSourceType = 'all';
    _selectedType = 'all';
    _selectedSize = 'all';
    _showFavoritesOnly = false;
    _sortByChallengeRating = false;
    notifyListeners();
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Hilfsmethode zum Aktualisieren einer Kreatur in einer Liste
  void _updateCreatureInList(List<Creature> list, Creature updatedCreature) {
    final index = list.indexWhere((c) => c.id == updatedCreature.id);
    if (index != -1) {
      list[index] = updatedCreature;
    }
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Führt eine Operation mit Error Handling durch
  Future<T> _executeWithErrorHandling<T>(Future<T> Function() operation) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      return await operation();
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
