import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wiki_entry.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für Wiki Management mit neuer Repository-Architektur
/// Zentralisiert State Management und Business-Logik für Wiki-Einträge
/// 
/// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
class WikiViewModel extends ChangeNotifier {
  final WikiEntryModelRepository _wikiRepository;
  
  // State
  List<WikiEntry> _entries = [];
  List<WikiEntry> _filteredEntries = [];
  bool _isLoading = false;
  String? _error;
  
  // Filter-Zustände
  String _searchQuery = '';
  WikiEntryType? _selectedType;
  Set<String> _selectedTags = {};
  bool _showGlobalOnly = false;
  bool _showCampaignOnly = false;
  
  // Sortierung
  WikiSortOption _sortOption = WikiSortOption.updatedAt;
  bool _sortAscending = false;

  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  /// 
  WikiViewModel({
    WikiEntryModelRepository? wikiRepository,
  }) : _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance);

  // Getters
  List<WikiEntry> get allEntries => List.unmodifiable(_entries);
  List<WikiEntry> get filteredEntries => List.unmodifiable(_filteredEntries);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  WikiEntryType? get selectedType => _selectedType;
  Set<String> get selectedTags => Set.unmodifiable(_selectedTags);
  bool get showGlobalOnly => _showGlobalOnly;
  bool get showCampaignOnly => _showCampaignOnly;
  WikiSortOption get sortOption => _sortOption;
  bool get sortAscending => _sortAscending;

  /// Prüft ob Filter aktiv sind
  bool get hasActiveFilters => 
      _searchQuery.isNotEmpty || 
      _selectedType != null || 
      _selectedTags.isNotEmpty ||
      _showGlobalOnly ||
      _showCampaignOnly;

  /// Gibt alle verfügbaren Tags zurück
  Set<String> get availableTags {
    final tags = <String>{};
    for (final entry in _entries) {
      tags.addAll(entry.tags);
    }
    return tags;
  }

  /// Gibt die Anzahl der Einträge pro Typ zurück
  Map<WikiEntryType, int> get entryTypeCounts {
    final counts = <WikiEntryType, int>{};
    for (final entry in _entries) {
      counts[entry.entryType] = (counts[entry.entryType] ?? 0) + 1;
    }
    return counts;
  }

  // ============================================================================
  // WIKI ENTRY MANAGEMENT
  // ============================================================================

  /// Lädt alle Wiki-Einträge aus der Datenbank über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> loadEntries() async {
    await _performAsyncOperation(() async {
      _entries = await _wikiRepository.findAll();
      _applyFiltersAndSort();
    });
  }

  /// Lädt Wiki-Einträge nach Typ über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> loadEntriesByType(WikiEntryType entryType) async {
    await _performAsyncOperation(() async {
      _entries = await _wikiRepository!.findAll();
      // Filtern nach Typ im ViewModel
      _entries = _entries.where((entry) => entry.entryType == entryType).toList();
      _applyFiltersAndSort();
    });
  }

  /// Lädt globale Wiki-Einträge über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> loadGlobalEntries() async {
    await _performAsyncOperation(() async {
      _entries = await _wikiRepository.findAll();
      // Filtern nach globalen Einträgen im ViewModel
      _entries = _entries.where((entry) => entry.campaignId == null).toList();
      _applyFiltersAndSort();
    });
  }

  /// Lädt Wiki-Einträge für eine Kampagne über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> loadCampaignEntries(String campaignId) async {
    await _performAsyncOperation(() async {
      _entries = await _wikiRepository.findAll();
      // Filtern nach Kampagne im ViewModel
      _entries = _entries.where((entry) => entry.campaignId == campaignId).toList();
      _applyFiltersAndSort();
    });
  }

  /// Sucht Wiki-Einträge über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> searchEntries(String query) async {
    await _performAsyncOperation(() async {
      _entries = await _wikiRepository.search(query);
      _searchQuery = query;
      _applyFiltersAndSort();
    });
  }

  /// Lokale Suche ohne Neuladen aus Datenbank
  void searchEntriesLocal(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt den Typ-Filter
  void setTypeFilter(WikiEntryType? type) {
    _selectedType = type;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Toggle für einen Tag-Filter
  void toggleTagFilter(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt die Tag-Filter
  void setTagFilters(Set<String> tags) {
    _selectedTags = Set.from(tags);
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Toggle für Global-Only Filter
  void toggleGlobalOnly() {
    _showGlobalOnly = !_showGlobalOnly;
    if (_showGlobalOnly) {
      _showCampaignOnly = false;
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Toggle für Campaign-Only Filter
  void toggleCampaignOnly() {
    _showCampaignOnly = !_showCampaignOnly;
    if (_showCampaignOnly) {
      _showGlobalOnly = false;
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Setzt die Sortieroption
  void setSortOption(WikiSortOption option) {
    if (_sortOption == option) {
      _sortAscending = !_sortAscending;
    } else {
      _sortOption = option;
      _sortAscending = option == WikiSortOption.title; // Titel normalerweise aufsteigend
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
    _searchQuery = '';
    _selectedType = null;
    _selectedTags.clear();
    _showGlobalOnly = false;
    _showCampaignOnly = false;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Wendet Filter und Sortierung an
  void _applyFiltersAndSort() {
    _filteredEntries = _entries.where((entry) {
      // Suchtext filtern
      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        final titleMatch = entry.title.toLowerCase().contains(queryLower);
        final contentMatch = entry.content.toLowerCase().contains(queryLower);
        final tagsMatch = entry.tags.any((tag) => 
            tag.toLowerCase().contains(queryLower));
        
        if (!(titleMatch || contentMatch || tagsMatch)) {
          return false;
        }
      }

      // Typ filtern
      if (_selectedType != null && entry.entryType != _selectedType) {
        return false;
      }

      // Tags filtern (Alle ausgewählten Tags müssen vorhanden sein)
      if (_selectedTags.isNotEmpty) {
        final hasAllTags = _selectedTags.every((tag) => entry.tags.contains(tag));
        if (!hasAllTags) {
          return false;
        }
      }

      // Global/Campaign filtern
      if (_showGlobalOnly && entry.campaignId != null) {
        return false;
      }

      if (_showCampaignOnly && entry.campaignId == null) {
        return false;
      }

      return true;
    }).toList();

    _sortEntries();
  }

  /// Sortiert die Einträge
  void _sortEntries() {
    switch (_sortOption) {
      case WikiSortOption.title:
        _filteredEntries.sort((a, b) => 
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case WikiSortOption.createdAt:
        _filteredEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case WikiSortOption.updatedAt:
        _filteredEntries.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case WikiSortOption.type:
        _filteredEntries.sort((a, b) => a.entryType.index.compareTo(b.entryType.index));
        break;
      case WikiSortOption.tagCount:
        _filteredEntries.sort((a, b) => a.tags.length.compareTo(b.tags.length));
        break;
    }

    if (!_sortAscending) {
      _filteredEntries = _filteredEntries.reversed.toList();
    }
  }

  /// Erstellt einen neuen Wiki-Eintrag über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> addEntry(WikiEntry entry) async {
    await _performAsyncOperation(() async {
      WikiEntry? savedEntry = await _wikiRepository.create(entry);
      if (savedEntry != null) {
        _entries.add(savedEntry);
        _applyFiltersAndSort();
      }
    });
  }

  /// Aktualisiert einen Wiki-Eintrag über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> updateEntry(WikiEntry entry) async {
    await _performAsyncOperation(() async {
      WikiEntry? updatedEntry = await _wikiRepository.update(entry);
      if (updatedEntry != null) {
        final index = _entries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          _entries[index] = updatedEntry;
          _applyFiltersAndSort();
        }
      }
    });
  }

  /// Löscht einen Wiki-Eintrag über neues Repository
  Future<void> deleteEntry(String entryId) async {
    await _performAsyncOperation(() async {
      await _wikiRepository.delete(entryId);
      _entries.removeWhere((entry) => entry.id == entryId);
      _applyFiltersAndSort();
    });
  }

  /// Dupliziert einen Wiki-Eintrag über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> duplicateEntry(WikiEntry entry) async {
    await _performAsyncOperation(() async {
      final duplicatedEntry = entry.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${entry.title} (Kopie)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      WikiEntry? savedEntry = await _wikiRepository.create(duplicatedEntry);
      if (savedEntry != null) {
        _entries.add(savedEntry);
        _applyFiltersAndSort();
      }
    });
  }

  /// Batch-Operation: Löscht mehrere Einträge auf einmal
  Future<void> deleteEntries(List<String> entryIds) async {
    await _performAsyncOperation(() async {
      await _wikiRepository.deleteAll(entryIds);
      _entries.removeWhere((entry) => entryIds.contains(entry.id));
      _applyFiltersAndSort();
    });
  }

  /// Batch-Operation: Aktualisiert mehrere Einträge auf einmal
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<void> updateEntries(List<WikiEntry> entries) async {
    await _performAsyncOperation(() async {
      await _wikiRepository.updateAll(entries);
      
      // Lokalen State aktualisieren
      for (final entry in entries) {
        final index = _entries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          _entries[index] = entry;
        }
      }
      _applyFiltersAndSort();
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
      debugPrint('Error in WikiViewModel: $e');
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
    await loadEntries();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Sortieroptionen für Wiki-Einträge
enum WikiSortOption {
  title,
  createdAt,
  updatedAt,
  type,
  tagCount,
}
