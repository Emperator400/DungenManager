import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/creature.dart';
import '../database/database_helper.dart';
import '../game_data/dnd_data_importer.dart';

/// ViewModel für das Bestiarum
/// Zentralisiert State Management und Business-Logik für Kreaturen
class BestiaryViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
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

  BestiaryViewModel({
    DatabaseHelper? dbHelper,
    DndDataImporter? dataImporter,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _dataImporter = dataImporter ?? DndDataImporter();

  // ============================================================================
  // DATA LOADING
  // ============================================================================

  /// Lädt alle Kreaturen aus der Datenbank
  Future<void> loadCreatures() async {
    await _executeWithErrorHandling(() async {
      final creatures = await _dbHelper.getAllCreatures();
      _allCreatures = creatures;
      _customCreatures = creatures.where((c) => c.sourceType == 'custom').toList();
      _officialCreatures = creatures.where((c) => c.sourceType == 'official').toList();
    });
  }

  /// Lädt D&D-Daten (Monster und Zauber)
  Future<void> loadDndData() async {
    await _executeWithErrorHandling(() async {
      _isLoadingDndData = true;
      notifyListeners();
      
      try {
        // Lade verfügbare offizielle Monster
        final monsters = await _dbHelper.getAllOfficialMonsters();
        _availableMonsters = monsters.map((monster) => {
          'id': monster.id,
          'name': monster.name,
          'size': monster.size,
          'type': monster.type,
          'subtype': monster.subtype,
          'alignment': monster.alignment,
          'armor_class': monster.armorClass,
          'hit_points': monster.hitPoints,
          'speed': monster.speed,
          'strength': monster.strength,
          'dexterity': monster.dexterity,
          'constitution': monster.constitution,
          'intelligence': monster.intelligence,
          'wisdom': monster.wisdom,
          'charisma': monster.charisma,
          'challenge_rating': monster.challengeRating,
          'description': monster.description,
        }).toList();
        
        // Lade verfügbare offizielle Zauber - temporär leer bis implementiert
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

  /// Erstellt eine neue Kreatur
  Future<void> createCreature(Creature creature) async {
    await _executeWithErrorHandling(() async {
      await _dbHelper.insertCreature(creature);
      _allCreatures.add(creature);
      
      // Aktualisiere die gefilterten Listen
      if (creature.sourceType == 'custom') {
        _customCreatures.add(creature);
      } else if (creature.sourceType == 'official') {
        _officialCreatures.add(creature);
      }
    });
  }

  /// Aktualisiert eine Kreatur
  Future<void> updateCreature(Creature creature) async {
    await _executeWithErrorHandling(() async {
      await _dbHelper.updateCreature(creature);
      
      // Update in allen Listen
      _updateCreatureInList(_allCreatures, creature);
      _updateCreatureInList(_customCreatures, creature);
      _updateCreatureInList(_officialCreatures, creature);
    });
  }

  /// Löscht eine Kreatur
  Future<void> deleteCreature(String creatureId) async {
    await _executeWithErrorHandling(() async {
      await _dbHelper.deleteCreature(creatureId);
      
      _allCreatures.removeWhere((c) => c.id == creatureId);
      _customCreatures.removeWhere((c) => c.id == creatureId);
      _officialCreatures.removeWhere((c) => c.id == creatureId);
    });
  }

  /// Schaltet den Favoriten-Status einer Kreatur um
  Future<void> toggleFavorite(Creature creature) async {
    final updatedCreature = creature.copyWith(isFavorite: !creature.isFavorite);
    await updateCreature(updatedCreature);
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

  /// Importiert alle verfügbaren Monster
  Future<void> importAllMonsters() async {
    await _executeWithErrorHandling(() async {
      if (_availableMonsters.isEmpty) {
        throw Exception('Keine Monster zum Importieren verfügbar');
      }

      // Lade bestehende Kreaturen
      final existingCreatures = await _dbHelper.getAllCreatures();
      final existingMonsterIds = existingCreatures
          .where((c) => c.officialMonsterId != null)
          .map((c) => c.officialMonsterId!)
          .toSet();

      int importedCount = 0;

      for (final monster in _availableMonsters) {
        final monsterId = monster['id']?.toString();
        
        // Überspringen, wenn bereits vorhanden
      if (monsterId != null && existingMonsterIds.contains(monsterId)) {
        continue;
      }

        final creature = Creature(
          id: '',
          name: monster['name']?.toString() ?? 'Unbekannt',
          maxHp: int.tryParse(monster['hit_points']?.toString() ?? '0') ?? 0,
          currentHp: int.tryParse(monster['hit_points']?.toString() ?? '0') ?? 0,
          armorClass: int.tryParse(monster['armor_class']?.toString() ?? '10') ?? 10,
          speed: monster['speed']?.toString() ?? '',
          strength: int.tryParse(monster['strength']?.toString() ?? '10') ?? 10,
          dexterity: int.tryParse(monster['dexterity']?.toString() ?? '10') ?? 10,
          constitution: int.tryParse(monster['constitution']?.toString() ?? '10') ?? 10,
          intelligence: int.tryParse(monster['intelligence']?.toString() ?? '10') ?? 10,
          wisdom: int.tryParse(monster['wisdom']?.toString() ?? '10') ?? 10,
          charisma: int.tryParse(monster['charisma']?.toString() ?? '10') ?? 10,
          size: monster['size']?.toString(),
          type: monster['type']?.toString(),
          subtype: monster['subtype']?.toString(),
          alignment: monster['alignment']?.toString(),
          challengeRating: (monster['challenge_rating'] as num?)?.toDouble()?.round(),
          sourceType: 'official',
          officialMonsterId: monsterId,
          description: monster['description']?.toString(),
        );

        await _dbHelper.insertCreature(creature);
        _allCreatures.add(creature);
        _officialCreatures.add(creature);
        importedCount++;
      }

      // Gib Informationen über den Import zurück
      notifyListeners();
      return importedCount;
    });
  }

  /// Fügt ein einzelnes Monster zum Bestiarum hinzu
  Future<void> addMonsterToBestiary(Map<String, dynamic> monsterData) async {
    await _executeWithErrorHandling(() async {
      // Prüfen, ob das Monster bereits im Bestiarum vorhanden ist
      final monsterId = monsterData['id']?.toString();
      final alreadyExists = _allCreatures.any((creature) => 
        creature.officialMonsterId == monsterId || 
        (creature.sourceType == 'official' && creature.name == monsterData['name']?.toString())
      );

      if (alreadyExists) {
        throw Exception('Dieses Monster ist bereits im Bestiarum vorhanden');
      }

      final creature = Creature(
        id: '',
        name: monsterData['name']?.toString() ?? 'Unbekannt',
        maxHp: int.tryParse(monsterData['hit_points']?.toString() ?? '0') ?? 0,
        currentHp: int.tryParse(monsterData['hit_points']?.toString() ?? '0') ?? 0,
        armorClass: int.tryParse(monsterData['armor_class']?.toString() ?? '10') ?? 10,
        speed: monsterData['speed']?.toString() ?? '',
        strength: int.tryParse(monsterData['strength']?.toString() ?? '10') ?? 10,
        dexterity: int.tryParse(monsterData['dexterity']?.toString() ?? '10') ?? 10,
        constitution: int.tryParse(monsterData['constitution']?.toString() ?? '10') ?? 10,
        intelligence: int.tryParse(monsterData['intelligence']?.toString() ?? '10') ?? 10,
        wisdom: int.tryParse(monsterData['wisdom']?.toString() ?? '10') ?? 10,
        charisma: int.tryParse(monsterData['charisma']?.toString() ?? '10') ?? 10,
        size: monsterData['size']?.toString(),
        type: monsterData['type']?.toString(),
        subtype: monsterData['subtype']?.toString(),
        alignment: monsterData['alignment']?.toString(),
        challengeRating: (monsterData['challenge_rating'] as num?)?.toDouble()?.round(),
        sourceType: 'official',
        officialMonsterId: monsterId,
        description: monsterData['description']?.toString(),
      );

      await _dbHelper.insertCreature(creature);
      _allCreatures.add(creature);
      _officialCreatures.add(creature);
    });
  }

  // ============================================================================
  // MIGRATION OPERATIONS
  // ============================================================================

  /// Führt Migration auf Unified Schema durch
  Future<void> migrateToUnifiedSchema() async {
    await _executeWithErrorHandling(() async {
      await _dataImporter.migrateCreaturesToUnifiedSchema();
      await loadCreatures(); // Neu laden nach Migration
    });
  }

  /// Synchronisiert offizielle Monster
  Future<void> syncOfficialMonsters() async {
    await _executeWithErrorHandling(() async {
      await _dataImporter.syncOfficialMonstersToCreatures();
      await loadCreatures(); // Neu laden nach Synchronisation
    });
  }

  /// Setzt das Bestiarum zurück (löscht alle Kreaturen)
  Future<void> resetBestiary() async {
    await _executeWithErrorHandling(() async {
      final creatures = await _dbHelper.getAllCreatures();
      for (final creature in creatures) {
        await _dbHelper.deleteCreature(creature.id.toString());
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
