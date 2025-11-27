import 'package:flutter/foundation.dart';
import '../models/wiki_entry.dart';
import '../database/database_helper.dart';

/// ViewModel für Wiki Management mit reactive State Management
class WikiViewModel extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  
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

  WikiViewModel({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

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

  /// Lädt alle Wiki-Einträge aus der Datenbank
  Future<void> loadEntries() async {
    await _performAsyncOperation(() async {
      _entries = await _databaseHelper.getAllWikiEntries();
      _applyFiltersAndSort();
    });
  }

  /// Sucht nach Wiki-Einträgen
  void searchEntries(String query) {
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

  /// Fügt einen neuen Wiki-Eintrag hinzu
  Future<void> addEntry(WikiEntry entry) async {
    await _performAsyncOperation(() async {
      await _databaseHelper.insertWikiEntry(entry);
      _entries.add(entry);
      _applyFiltersAndSort();
    });
  }

  /// Aktualisiert einen Wiki-Eintrag
  Future<void> updateEntry(WikiEntry entry) async {
    await _performAsyncOperation(() async {
      await _databaseHelper.updateWikiEntry(entry);
      
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
        _applyFiltersAndSort();
      }
    });
  }

  /// Löscht einen Wiki-Eintrag
  Future<void> deleteEntry(String entryId) async {
    await _performAsyncOperation(() async {
      await _databaseHelper.deleteWikiEntry(entryId);
      _entries.removeWhere((entry) => entry.id == entryId);
      _applyFiltersAndSort();
    });
  }

  /// Dupliziert einen Wiki-Eintrag
  Future<void> duplicateEntry(WikiEntry entry) async {
    await _performAsyncOperation(() async {
      final duplicatedEntry = entry.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${entry.title} (Kopie)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _databaseHelper.insertWikiEntry(duplicatedEntry);
      _entries.add(duplicatedEntry);
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
