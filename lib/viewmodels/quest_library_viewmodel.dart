import 'package:flutter/foundation.dart';
import '../models/quest.dart';
import '../services/quest_service_locator.dart';

/// ViewModel für die Quest-Bibliothek mit reactive State Management
class QuestLibraryViewModel extends ChangeNotifier {
  final _questService = QuestServiceLocator.instance.questLibraryService;
  
  // State
  List<Quest> _allQuests = [];
  List<Quest> _filteredQuests = [];
  bool _isLoading = false;
  String? _error;
  
  // Filter-Zustände
  QuestType? _selectedType;
  QuestDifficulty? _selectedDifficulty;
  Set<String> _selectedTags = {};
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  
  // Sortierung
  SortOption _sortOption = SortOption.alphabetical;
  bool _sortAscending = true;
  
  // Tab-Management
  int _currentTabIndex = 0;

  QuestLibraryViewModel();

  // Getters
  List<Quest> get allQuests => List.unmodifiable(_allQuests);
  List<Quest> get filteredQuests => List.unmodifiable(_filteredQuests);
  bool get isLoading => _isLoading;
  String? get error => _error;
  QuestType? get selectedType => _selectedType;
  QuestDifficulty? get selectedDifficulty => _selectedDifficulty;
  Set<String> get selectedTags => Set.unmodifiable(_selectedTags);
  bool get showFavoritesOnly => _showFavoritesOnly;
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  bool get sortAscending => _sortAscending;
  int get currentTabIndex => _currentTabIndex;

  /// Prüft ob Filter aktiv sind
  bool get hasActiveFilters => 
      _selectedType != null || 
      _selectedDifficulty != null || 
      _selectedTags.isNotEmpty || 
      _showFavoritesOnly ||
      _searchQuery.isNotEmpty;

  /// Prüft ob Suchergebnisse vorhanden sind
  bool get hasSearchResults => _filteredQuests.isNotEmpty;

  /// Gibt verfügbare Tags zurück
  Set<String> get availableTags {
    final allTags = <String>{};
    for (final quest in _allQuests) {
      allTags.addAll(quest.tags);
    }
    return allTags;
  }

  /// Lädt alle Quests aus der Datenbank
  Future<void> loadQuests() async {
    await _performAsyncOperation(() async {
      final result = await _questService.getAllQuests();
      if (result.isSuccess && result.data != null) {
        _allQuests = result.data!;
      }
      _applyFiltersAndSort();
    });
  }

  /// Setzt den aktuellen Tab
  void setCurrentTab(int index) {
    if (_currentTabIndex == index) return;
    
    _currentTabIndex = index;
    
    // Tab-spezifische Filter anwenden
    switch (index) {
      case 0: // Alle Quests
        clearAllFilters();
        break;
      case 1: // Hauptquests
        _clearFiltersExceptType();
        _selectedType = QuestType.main;
        _applyFiltersAndSort();
        break;
      case 2: // Favoriten
        _clearFiltersExceptFavorites();
        _showFavoritesOnly = true;
        _applyFiltersAndSort();
        break;
    }
    
    notifyListeners();
  }

  /// Sucht nach Quests
  void searchQuests(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Quest-Typ Filter
  void setTypeFilter(QuestType? type) {
    _selectedType = type;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Schwierigkeits-Filter
  void setDifficultyFilter(QuestDifficulty? difficulty) {
    _selectedDifficulty = difficulty;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Toggle eines Tags
  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Favoriten-Filter
  void setFavoritesFilter(bool showOnly) {
    _showFavoritesOnly = showOnly;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt die Sortieroption
  void setSortOption(SortOption option) {
    if (_sortOption == option) {
      _sortAscending = !_sortAscending;
    } else {
      _sortOption = option;
      _sortAscending = true;
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt die Sortierrichtung
  void setSortAscending(bool ascending) {
    _sortAscending = ascending;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Löscht alle Filter
  void clearAllFilters() {
    _selectedType = null;
    _selectedDifficulty = null;
    _selectedTags.clear();
    _showFavoritesOnly = false;
    _searchQuery = '';
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Löscht alle Filter außer Typ
  void _clearFiltersExceptType() {
    _selectedDifficulty = null;
    _selectedTags.clear();
    _showFavoritesOnly = false;
    _searchQuery = '';
  }

  /// Löscht alle Filter außer Favoriten
  void _clearFiltersExceptFavorites() {
    _selectedType = null;
    _selectedDifficulty = null;
    _selectedTags.clear();
    _searchQuery = '';
  }

  /// Wendet Filter und Sortierung an
  void _applyFiltersAndSort() {
    _filteredQuests = _allQuests.where((quest) {
      // Suchtext filtern
      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        final titleMatch = quest.title.toLowerCase().contains(queryLower);
        final descriptionMatch = quest.description.toLowerCase().contains(queryLower);
        final tagMatch = quest.tags.any((tag) => 
            tag.toLowerCase().contains(queryLower));
        final locationMatch = quest.location != null && 
            quest.location!.toLowerCase().contains(queryLower);
        final npcMatch = quest.involvedNpcs.isNotEmpty && 
            quest.involvedNpcs.any((npc) => npc.toLowerCase().contains(queryLower));
        final rewardMatch = quest.rewards.isNotEmpty && 
            quest.rewards.any((reward) => reward.name.toLowerCase().contains(queryLower));
        
        if (!(titleMatch || descriptionMatch || 
              tagMatch || locationMatch || npcMatch || rewardMatch)) {
          return false;
        }
      }

      // Typ filtern
      if (_selectedType != null && quest.questType != _selectedType) {
        return false;
      }

      // Schwierigkeit filtern
      if (_selectedDifficulty != null && quest.difficulty != _selectedDifficulty) {
        return false;
      }

      // Tags filtern
      if (_selectedTags.isNotEmpty) {
        final hasAllRequiredTags = _selectedTags.every((requiredTag) => 
            quest.tags.contains(requiredTag));
        if (!hasAllRequiredTags) return false;
      }

      // Favoriten filtern
      if (_showFavoritesOnly && !quest.isFavorite) {
        return false;
      }

      return true;
    }).toList();

    _sortQuests();
  }

  /// Sortiert die Quests
  void _sortQuests() {
    switch (_sortOption) {
      case SortOption.alphabetical:
        _filteredQuests.sort((a, b) => 
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.type:
        _filteredQuests.sort((a, b) => 
            a.questType.index.compareTo(b.questType.index));
        break;
      case SortOption.difficulty:
        _filteredQuests.sort((a, b) => 
            a.difficulty.index.compareTo(b.difficulty.index));
        break;
      case SortOption.level:
        _filteredQuests.sort((a, b) {
          if (a.recommendedLevel == null && b.recommendedLevel == null) return 0;
          if (a.recommendedLevel == null) return 1;
          if (b.recommendedLevel == null) return -1;
          return a.recommendedLevel!.compareTo(b.recommendedLevel!);
        });
        break;
      case SortOption.duration:
        _filteredQuests.sort((a, b) {
          if (a.estimatedDurationHours == null && b.estimatedDurationHours == null) return 0;
          if (a.estimatedDurationHours == null) return 1;
          if (b.estimatedDurationHours == null) return -1;
          return a.estimatedDurationHours!.compareTo(b.estimatedDurationHours!);
        });
        break;
      case SortOption.created:
        _filteredQuests.sort((a, b) => 
            a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.updated:
        _filteredQuests.sort((a, b) => 
            a.updatedAt.compareTo(b.updatedAt));
        break;
    }

    if (!_sortAscending) {
      _filteredQuests = _filteredQuests.reversed.toList();
    }
  }

  /// Toggle Favoriten-Status einer Quest
  Future<void> toggleFavorite(Quest quest) async {
    await _performAsyncOperation(() async {
      final result = await _questService.updateQuest(quest.copyWith(
        isFavorite: !quest.isFavorite,
        updatedAt: DateTime.now(),
      ));
      
      if (result.isSuccess && result.data != null) {
        final updatedQuest = result.data!;
        
        // Lokalen State aktualisieren
        final index = _allQuests.indexWhere((q) => q.id == quest.id);
        if (index != -1) {
          _allQuests[index] = updatedQuest;
        }
        
        _applyFiltersAndSort();
      } else {
        throw Exception(result.userMessage ?? 'Fehler beim Aktualisieren des Favoritenstatus');
      }
    });
  }

  /// Löscht eine Quest
  Future<void> deleteQuest(Quest quest) async {
    await _performAsyncOperation(() async {
      final result = await _questService.deleteQuest(quest.id.toString());
      
      if (result.isSuccess) {
        // Lokalen State aktualisieren
        _allQuests.removeWhere((q) => q.id == quest.id);
        _applyFiltersAndSort();
      } else {
        throw Exception(result.userMessage ?? 'Fehler beim Löschen der Quest');
      }
    });
  }

  /// Führt eine async Operation mit Loading- und Error-Handling aus
  Future<void> _performAsyncOperation(Future<void> Function() operation) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await operation();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error in QuestLibraryViewModel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Löscht den Error-State
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refreshed die Daten
  Future<void> refresh() async {
    await loadQuests();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Sortieroptionen für Quests
enum SortOption {
  alphabetical,
  type,
  difficulty,
  level,
  duration,
  created,
  updated,
}
